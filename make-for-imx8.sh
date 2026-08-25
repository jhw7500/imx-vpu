#!/bin/bash
# VPU 화질 백포트 프로젝트 크로스 빌드 (max9296의 make-for-imx8 대응)
#
# 사용법:
#   ./build.sh          # 증분 빌드 (수정-반복용, 수 초)
#   ./build.sh reconf   # configure/meson 재구성부터 (최초 1회 또는 빌드설정 변경 시)
#
# 산출물:
#   staging/usr/lib/libfslvpuwrap.so.3.0.0          (wrapper)
#   imx-gst1.0-plugin/build/plugins/vpu/libgstvpu.so (GStreamer 플러그인)
# 두 파일은 ABI 세트 — 반드시 함께 배포 (update_bin.sh 사용)
# source 로 부르면 exit 가 호출한 셸을 죽인다. 실행이면 exit, source 면 return 한다.
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then _mfi_end='return'; else _mfi_end='exit'; fi

set -e

[ "$SDK_LOC" ] || SDK_LOC=/shared/fsl-imx-xwayland/5.10-hardknott
[ "$SDK_NAME" ] || SDK_NAME=cortexa53-crypto-poky-linux

[ ! -e ${SDK_LOC}/environment-setup-${SDK_NAME} ] && {
    echo "Sorry, please verify: ${SDK_LOC}/environment-setup-${SDK_NAME}"
    "$_mfi_end" 1
}

. ${SDK_LOC}/environment-setup-${SDK_NAME}

TOP="$(cd "$(dirname "$0")" && pwd)"

# set -e 로 빌드가 실패하면 아래 compile_commands.json 갱신 블록에 도달하지 못한다.
# 낡은 DB 가 그대로 남으므로 ERR 에서 알린다.
trap '[ -e "$TOP/imx-vpuwrap/compile_commands.json" ] && echo "빌드 실패로 imx-vpuwrap/compile_commands.json 을 갱신하지 않았다 — 기존 DB 는 직전 성공 빌드 기준이다." >&2' ERR
DEPS=${TOP}/deps
STAGING=${TOP}/staging

# ---------- 1) imx-vpuwrap (autotools) ----------
cd ${TOP}/imx-vpuwrap
if [ ! -x configure ] || [ "$1" = "reconf" ]; then
    autoreconf -fiv
fi
if [ ! -f Makefile ] || [ "$1" = "reconf" ]; then
    ./configure ${CONFIGURE_FLAGS} --prefix=/usr --libdir=/usr/lib \
        CPPFLAGS="-I${DEPS}/usr/include" \
        CFLAGS="${CFLAGS} -I${DEPS}/usr/include" \
        LDFLAGS="${LDFLAGS} -L${DEPS}/usr/lib"
fi
# PKG_CONFIG_SYSROOT_DIR=deps: Makefile이 hantro 헤더를 make 시점 환경변수
# $(PKG_CONFIG_SYSROOT_DIR)/usr/include/hantro_* 로 참조하므로 명령줄로 덮어씀
# (SDK env가 SDK sysroot로 export해두는 값보다 우선)
make -j"$(nproc)" PKG_CONFIG_SYSROOT_DIR="${DEPS}"
rm -rf ${STAGING}
make install DESTDIR=${STAGING} PKG_CONFIG_SYSROOT_DIR="${DEPS}" >/dev/null

# ---------- 2) imx-gst1.0-plugin (meson, vpu 플러그인) ----------
# SDK 동봉 meson.cross는 설치 경로 relocation이 안 되어 있어(/opt/... 고정)
# 프로젝트 자체 cross 파일을 매번 생성한다 ($SDKTARGETSYSROOT 기반 — 재배치 안전).
# vpuwrap은 SDK sysroot에 없으므로 staging/deps를 c_args/link_args로 직접 주입.
# 헤더 우선순위: repo의 ext-includes → staging (둘 다 백포트 적용본이라 동일)
cd ${TOP}/imx-gst1.0-plugin
cat > ${TOP}/meson.cross <<EOF
[binaries]
c = ['${TARGET_PREFIX}gcc', '-mcpu=cortex-a53', '-march=armv8-a+crc+crypto', '--sysroot=${SDKTARGETSYSROOT}']
cpp = ['${TARGET_PREFIX}g++', '-mcpu=cortex-a53', '-march=armv8-a+crc+crypto', '--sysroot=${SDKTARGETSYSROOT}']
ar = '${TARGET_PREFIX}ar'
nm = '${TARGET_PREFIX}nm'
strip = '${TARGET_PREFIX}strip'
pkgconfig = 'pkg-config'

[properties]
needs_exe_wrapper = true
c_args = ['-O2', '-pipe', '-g', '-I${STAGING}/usr/include/imx-mm/vpu', '-I${STAGING}/usr/include', '-I${DEPS}/usr/include', '-I${SDKTARGETSYSROOT}/usr/include/imx']
c_link_args = ['-Wl,-O1', '-Wl,--hash-style=gnu', '-Wl,--as-needed', '-L${STAGING}/usr/lib', '-L${DEPS}/usr/lib', '-lfslvpuwrap']
sys_root = '${SDKTARGETSYSROOT}'

[host_machine]
system = 'linux'
cpu_family = 'aarch64'
cpu = 'cortex-a53'
endian = 'little'
EOF
MESON_REAL=${OECORE_NATIVE_SYSROOT}/usr/bin/meson.real
if [ ! -d build ] || [ "$1" = "reconf" ]; then
    rm -rf build
    # 래퍼와 동일: 크로스 CC 류가 native 감지에 끼어들지 않게 unset
    (unset CC CXX CPP LD AR NM STRIP; \
     ${MESON_REAL} --cross-file ${TOP}/meson.cross build -Dplatform=MX8)
fi
ninja -C build

echo ""
echo "== 빌드 완료 =="
ls -la ${STAGING}/usr/lib/libfslvpuwrap.so.3.0.0 ${TOP}/imx-gst1.0-plugin/build/plugins/vpu/libgstvpu.so
echo "배포: ./update_bin.sh (두 파일 세트 필수)"

# --- clangd: compile_commands.json 자동 갱신 ---------------------------------
# imx-gst1.0-plugin 은 meson 이 build/compile_commands.json 을 만들어 준다.
# imx-vpuwrap 은 autotools 라 .cmd 가 없으므로 compiledb 로 make -n 출력을
# 파싱한다 (컴파일 없음). 설치: python3 -m pip install --user compiledb
#
# set -e (15행) 때문에 빌드가 실패하면 여기까지 오지 않는다. 즉 이 지점은 항상
# 성공 경로다. $? 를 읽으면 직전 echo 의 상태(항상 0)를 잡게 되어 무의미하므로
# 읽지 않는다.
#
# 뒤집어 말하면 빌드가 실패한 경우 DB 는 갱신되지 않고 직전 성공 빌드 기준으로
# 남는다. 지우지는 않는다 — DB 가 없으면 clangd 는 헤더조차 못 찾는 상태로
# 되돌아가므로, 낡은 DB 가 없는 것보다 낫다. 대신 갱신하지 못했을 때는 그
# 사실을 알린다.
_cc_target="${TOP}/imx-vpuwrap/compile_commands.json"
if ! command -v compiledb >/dev/null 2>&1; then
    echo "compiledb 가 없어 imx-vpuwrap/compile_commands.json 을 갱신하지 못했다." >&2
    echo "  설치: python3 -m pip install --user compiledb" >&2
    [ -e "$_cc_target" ] && echo "  기존 DB 는 직전 성공 빌드 기준이라 낡았을 수 있다." >&2
else
    _cc_tmp="$(mktemp "${TOP}/imx-vpuwrap/.compile_commands.json.XXXXXX" 2>/dev/null)" || _cc_tmp=""
    if [ -n "$_cc_tmp" ] \
       && ( cd "${TOP}/imx-vpuwrap" && compiledb -n -o "$_cc_tmp" make PKG_CONFIG_SYSROOT_DIR="${DEPS}" ) >/dev/null 2>&1 \
       && grep -q '"file"' "$_cc_tmp" 2>/dev/null \
       && mv -f "$_cc_tmp" "$_cc_target"; then
        echo "imx-vpuwrap/compile_commands.json 갱신됨 (clangd)"
    else
        rm -f "$_cc_tmp"
        echo "imx-vpuwrap/compile_commands.json 갱신 실패 — 빌드 자체는 정상" >&2
        [ -e "$_cc_target" ] && echo "  기존 DB 는 직전 성공 빌드 기준이라 낡았을 수 있다." >&2
    fi
fi
"$_mfi_end" 0
