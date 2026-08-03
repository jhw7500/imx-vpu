# imx-vpu 프로젝트 안내 (AI 어시스턴트용)

## 프로젝트 개요

i.MX8MP(Hantro VC8000E) VPU 인코더 화질개선을 위한 SDK 크로스빌드 프로젝트.
NXP 공식 저장소의 화질 관련 패치를 4.6.1(L5.10.y BSP) 기준으로 백포트해
빠르게 수정-빌드-배포 반복하는 것이 목적이다.

- `imx-vpuwrap/` — NXP VPU wrapper 라이브러리 (libfslvpuwrap). autotools.
- `imx-gst1.0-plugin/` — NXP GStreamer 플러그인 (vpuenc_h264/hevc 등). meson.
- `build.sh` — Yocto SDK(`/shared/fsl-imx-xwayland/5.10-hardknott`) 크로스빌드.
  wrapper를 먼저 빌드해 `staging/`에 넣고, 플러그인이 그것을 참조한다.
- `update_bin.sh` — 산출물 2개를 `../pim-package-jhw/dist/`로 복사(strip 포함).
- `setup-deps.sh` — NXP EULA 바이너리(deps/)를 로컬 빌드트리에서 복사 (repo 미포함).

## 불변 규칙

1. **ABI 세트**: `VpuEncOpenParamSimp` 구조체가 백포트로 변경되어
   `libfslvpuwrap.so`와 `libgstvpu.so`는 반드시 세트로 빌드·배포한다.
   한쪽만 수정/배포하는 변경은 제안하지 말 것.
2. `imx-vpuwrap/vpu_wrapper.h`와 `imx-gst1.0-plugin/ext-includes/vpu_wrapper.h`는
   구조체 정의가 항상 동일해야 한다 (양쪽 함께 수정).
3. `deps/`, `staging/`, `build/`는 커밋 금지 (.gitignore 유지).
4. 여기서 검증된 수정은 meta-pim 레이어(`/opt/desktop/sources/pim-yocto-layer/meta-pim`)에
   patch로 반영해야 Yocto/도커 빌드에 적용된다.

## 빌드/검증

- 빌드: `./build.sh` (증분) / `./build.sh reconf` (재구성)
- 검증: 타겟에서 `gst-inspect-1.0 vpuenc_h264`로 속성(qp-min/qp-max/profile/level) 확인
- GitHub 러너에서는 크로스빌드 재현 불가(SDK+EULA 바이너리 필요) — build-test 워크플로우 비활성
