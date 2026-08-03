#!/bin/bash
# deps/ 채우기 — NXP EULA 라이선스 바이너리(hantro)라 repo에 포함하지 않는다.
# Yocto 빌드트리의 imx-vpuwrap recipe-sysroot에서 복사한다.
set -e

TOP="$(cd "$(dirname "$0")" && pwd)"
SRC=${1:-/opt/desktop/build-desktop/tmp/work/cortexa53-crypto-mx8mp-fsl-linux/imx-vpuwrap/4.6.1-r0/recipe-sysroot}

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
