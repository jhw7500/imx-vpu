# imx-vpu — i.MX8MP VPU 인코더 화질 백포트 SDK 크로스빌드 프로젝트

max9296 프로젝트와 동일한 방식의 독립 크로스컴파일 환경.
Yocto/bitbake 없이 SDK만으로 수 초 단위 수정-빌드 반복이 가능하다.

## 구성

| 경로 | 내용 |
|---|---|
| `imx-vpuwrap/` | NXP 4.6.1 + 화질 백포트 4커밋 (QpMin/Max, bitrate 보정, profile/level, 후속픽스) |
| `imx-gst1.0-plugin/` | NXP 4.6.1 + set-keyframe(자사) + 백포트 2커밋 (qp-min/qp-max, profile/level) |
| `deps/` | vpuwrap 빌드용 hantro 헤더/라이브러리 (recipe-sysroot에서 복사, 1회성) |
| `staging/` | vpuwrap 빌드 산출물 — 플러그인이 이 헤더/라이브러리로 빌드됨 |
| `build.sh` | 전체 빌드 (max9296의 make-for-imx8 대응) |
| `update_bin.sh` | 산출물 2개를 `../pim-package-jhw/dist/pim/usr/lib/`로 복사 |
| `meson.cross` | build.sh가 매번 자동 생성 (SDK 경로 기반) |

## 사용법

```bash
./build.sh          # 증분 빌드 (수정-반복, 수 초)
./build.sh reconf   # 최초 1회 / 빌드설정 변경 시 (configure+meson 재구성)
./update_bin.sh     # dist 반영 (strip 포함) → pim-package 빌드/설치 시 타겟 적용
```

- 요구사항: SDK `/shared/fsl-imx-xwayland/5.10-hardknott` (max9296과 동일; `SDK_LOC`/`SDK_NAME` 환경변수로 변경 가능)
- 산출물: `staging/usr/lib/libfslvpuwrap.so.3.0.0`, `imx-gst1.0-plugin/build/plugins/vpu/libgstvpu.so`

## 반드시 지킬 것 — ABI 세트 배포

백포트가 `VpuEncOpenParamSimp` 구조체 중간에 필드를 추가했으므로
**libfslvpuwrap과 libgstvpu는 항상 세트로 빌드·배포**해야 한다.
`update_bin.sh`가 항상 둘을 함께 복사하는 이유. 한쪽만 교체 금지.

## 추가된 인코더 속성 (vpuenc_h264 / vpuenc_hevc)

| 속성 | 범위 | 설명 |
|---|---|---|
| `qp-min` / `qp-max` | 0~51 (0=wrapper 기본) | CBR에서 QP 상/하한 — 순간 화질붕괴 방어 |
| `profile` | h264: 9~12 / hevc: 0~2 | h264 11=High(CABAC+8x8 → 화질 10~15%↑) |
| `level` | h264: 10~99 / hevc: 30~180 | 미지정 시 wrapper 자동 계산 |

권장(CBR): `vpuenc_h264 bitrate=<기존값> profile=11 qp-max=42 [gop-size=90]`
상세 근거: `imx-gst1.0-plugin` 저장소의 `.omc/plans/vpu-quality-backport-plan.md`
(기술 계획서 / 부록 A·B: 모드 비교·예측) 참조.

## 검증된 수정의 정식 반영 경로

이 프로젝트는 **빠른 실험용**이다. 여기서 검증이 끝난 수정은 커밋 후
patch로 추출해 meta-pim 레이어에 반영한다 (Yocto/도커 빌드가 그걸 사용):

```bash
cd imx-vpuwrap    # 또는 imx-gst1.0-plugin
git format-patch -1 HEAD -o /tmp/
# → /opt/desktop/sources/pim-yocto-layer/meta-pim/recipes-multimedia/{imx-vpuwrap,gstreamer}/
#    파일 복사 + bbappend SRC_URI에 추가
```

meta-pim에는 이미 백포트 패치들이 반영되어 있다 (2026-08-03):
- `recipes-multimedia/gstreamer/imx-gst1.0-plugin/0002,0003-*.patch`
- `recipes-multimedia/imx-vpuwrap/imx-vpuwrap/0001~0004-*.patch`

## 빌드 구조 메모 (트러블슈팅)

- vpuwrap: autotools. hantro 헤더는 make 변수 `PKG_CONFIG_SYSROOT_DIR`로 참조되어
  build.sh가 `make PKG_CONFIG_SYSROOT_DIR=deps`로 덮어씀 (SDK sysroot에 hantro 없음)
- plugin: meson. SDK 동봉 meson.cross는 relocation이 안 되어 있어 자체 생성 파일 사용.
  vpuwrap을 pkg-config가 아닌 c_args/link_args로 주입 (`-I staging/usr/include/imx-mm/vpu`)
- vpu 외 플러그인/툴(aiurdemux, gplay 등)도 함께 빌드되지만 배포 대상 아님
- 소스 출처: `/opt/desktop/build-desktop/workspace/sources/`의 devtool workspace에서
  clone (원격 push 시 workspace가 origin)

<!-- automation v1.45.2 reviewer canary; intentionally unmerged -->
