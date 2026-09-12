#!/bin/bash
# 빌드 산출물을 pim-package dist로 복사 → 패키지 설치 시 타겟에 적용
# (max9296의 update_bin.sh 대응)
#
# !! 두 파일은 ABI 세트(VpuEncOpenParamSimp 구조체 변경) — 반드시 함께 배포 !!
#    한쪽만 교체된 장치는 인코더 파라미터가 어긋나 오동작한다.
set -e

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"

TOP="$(cd "$(dirname "$0")" && pwd)"
# 기본값은 형제 디렉터리라 호스트 종속이 아니다. 다른 곳에 두었으면 .env 의
# PIM_PACKAGE_DIR 로 가리킨다 (gstApp/update_bin.sh 와 같은 이름).
DIST=${PIM_PACKAGE_DIR:-${TOP}/../pim-package-jhw}/dist/pim

[ ! -d ${DIST} ] && { echo "dist 폴더 없음: ${DIST}"; exit 1; }

WRAP=${TOP}/staging/usr/lib/libfslvpuwrap.so.3.0.0
PLUG=${TOP}/imx-gst1.0-plugin/build/plugins/vpu/libgstvpu.so
[ ! -f ${WRAP} ] || [ ! -f ${PLUG} ] && { echo "산출물 없음 — 먼저 ./make-for-imx8.sh 실행"; exit 1; }

# strip을 위해 SDK 환경 로드 (경로는 env.sh 가 .env 에서 읽어 둔다)
. ${SDK_LOC}/environment-setup-${SDK_NAME}

install -d ${DIST}/usr/lib/gstreamer-1.0

# wrapper: 실파일 + 런타임 심볼릭 링크
install -m 0755 ${WRAP} ${DIST}/usr/lib/libfslvpuwrap.so.3.0.0
${STRIP} --strip-unneeded ${DIST}/usr/lib/libfslvpuwrap.so.3.0.0
ln -sf libfslvpuwrap.so.3.0.0 ${DIST}/usr/lib/libfslvpuwrap.so.3

# gstreamer 플러그인
install -m 0755 ${PLUG} ${DIST}/usr/lib/gstreamer-1.0/libgstvpu.so
${STRIP} --strip-unneeded ${DIST}/usr/lib/gstreamer-1.0/libgstvpu.so

echo "== dist 반영 완료 (2파일 세트) =="
ls -la ${DIST}/usr/lib/libfslvpuwrap.so.3* ${DIST}/usr/lib/gstreamer-1.0/libgstvpu.so
echo ""
echo "타겟 적용 후: 녹화/재생 앱 재시작 필요 (재부팅 불필요)"
echo "속성 확인:   gst-inspect-1.0 vpuenc_h264 | grep -E 'qp-min|qp-max|profile|level'"
