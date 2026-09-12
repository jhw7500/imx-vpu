#!/bin/bash
# deps/ 채우기 — NXP EULA 라이선스 바이너리(hantro)라 repo에 포함하지 않는다.
# Yocto 빌드트리의 imx-vpuwrap recipe-sysroot에서 복사한다.
set -e

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"

TOP="$(cd "$(dirname "$0")" && pwd)"
# 인자로 준 경로가 1순위, 없으면 .env 의 HANTRO_SYSROOT.
SRC=${1:-$HANTRO_SYSROOT}
[ -n "${SRC}" ] || {
    echo "hantro recipe-sysroot 경로가 없다." >&2
    echo "사용법: $0 [recipe-sysroot 경로]   또는 .env 의 HANTRO_SYSROOT 를 채운다" >&2
    exit 1
}

[ ! -d ${SRC}/usr/include/hantro_dec ] && {
    echo "hantro 헤더를 찾을 수 없음: ${SRC}"
    echo "사용법: $0 [recipe-sysroot 경로]"
    echo "(bitbake imx-vpuwrap 1회 실행 후 다시 시도)"
    exit 1
}

mkdir -p ${TOP}/deps/usr/include ${TOP}/deps/usr/lib
cp -a ${SRC}/usr/include/hantro_dec ${SRC}/usr/include/hantro_VC8000E_enc ${TOP}/deps/usr/include/
cp -a ${SRC}/usr/lib/libcodec.so* ${SRC}/usr/lib/libhantro.so* ${SRC}/usr/lib/libhantro_vc8000e.so* ${TOP}/deps/usr/lib/

echo "== deps 구성 완료 =="
ls ${TOP}/deps/usr/include ${TOP}/deps/usr/lib
