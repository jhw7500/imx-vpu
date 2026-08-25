# Changelog

## [Unreleased]

### Added
- VPU 인코더 화질개선 NXP 공식 패치 백포트 (PR #1)
  - `qp-min`/`qp-max` 속성 — CBR QP 상/하한 (MMFMWK-9106)
  - `profile`/`level` 속성 — H.264 High(CABAC+8x8)/HEVC Main10 선택 (MLK-26134)
  - CBR bitrate 보정 (MMFMWK-9147)

## [0.1.0] - 2026-08-03

### Added
- 프로젝트 초기 구성: NXP 4.6.1(MM_04.06.01_2105_L5.10.y) 기준
  - imx-vpuwrap `cab67186`
  - imx-gst1.0-plugin `057e6bf` + set-keyframe 자사 패치
- Yocto SDK 크로스빌드 (`make-for-imx8.sh`) 및 pim-package dist 배포 (`update_bin.sh`)
