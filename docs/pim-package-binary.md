# pim-package VPU 바이너리 provenance

이 문서는 `libgstvpu.so`와 `libfslvpuwrap.so.3.0.0`의 패키지 위치,
소스 커밋, 재현 빌드 결과를 기록한다. 두 파일은 `VpuEncOpenParamSimp`
ABI를 공유하므로 반드시 한 세트로 빌드하고 배포한다.

## 결론

패치된 활성 바이너리의 이 저장소 소스 기준은 병합 커밋
`5b9573c39c9b566a9e17174b812a87f355214afa`다. GitLab 이식용으로 정리된
저장소에서는 `7014cfa076d4a6e5b713b9e43f3e80d32e29c6a2`가 이에 대응한다.

실제 VPU 소스 내용은 병합의 두 번째 부모인
`130651746c8ff4b768e210dbeee23753fbedfd68`에서 완성됐고, 정리된 이력의
대응 커밋은 `e8484816256bb0d3441dd31a8ba43a31a149bd4f`다. 이 저장소의
`1306517`과 `5b9573c`는 Git tree가 `97c1f34f49ca5975dcccbf5fee67007cda06cfc8`로
동일하다. 정리된 저장소의 `e848481`과 `7014cfa`도 Git tree가
`008fffd962cc32087cd67fe67d02e978c27dd11c`로 동일하다.

| 의미 | 이 저장소 커밋 | 정리된 GitLab 이력 커밋 |
| --- | --- | --- |
| 빌드 당시 기준 병합 | `5b9573c39c9b566a9e17174b812a87f355214afa` | `7014cfa076d4a6e5b713b9e43f3e80d32e29c6a2` |
| 실제 소스 내용 완성 | `130651746c8ff4b768e210dbeee23753fbedfd68` | `e8484816256bb0d3441dd31a8ba43a31a149bd4f` |

`5b9573c` 이후 이 저장소의 커밋은 공통 workflow 또는 clangd 빌드 지원만
변경했으며, 위 패키지 바이너리에 들어간 VPU 제품 소스 기준은 바뀌지 않았다.

## 패키지 위치

회사 GitLab `pim-package`의 현재 `origin/master`
`25cd47099f953cd6fac4a93175ac9b725e70a414`에는 VPU 바이너리가 없다.
따라서 이를 `pim-package master 바이너리`라고 부르면 안 된다.

패치된 활성 바이너리는 다음 두 위치에서 확인된다.

- GitHub `pim-package-jhw/master`: 최초 반영 커밋
  `8328eea5a3c5e16b1a9995bd471ddf0e72848654`
- 회사 GitLab `pim-package`의 `sync/github-2026-08-10`: 동기화 커밋
  `eec2a05b9420c7be83fc48a72ff6eb5e53b078d3`

GitLab 동기화 브랜치의 파일 내용은 GitHub `master`와 동일하다.

## 활성 바이너리 식별값

| 항목 | `libgstvpu.so` | `libfslvpuwrap.so.3.0.0` |
| --- | --- | --- |
| 패키지 경로 | `dist/pim/usr/lib/gstreamer-1.0/libgstvpu.so` | `dist/pim/usr/lib/libfslvpuwrap.so.3.0.0` |
| Git blob | `31bd184e1db1c827a11b82331537fa922a02cd51` | `da6a8030f4d43b58f533b6c390ea6dbe15cc1492` |
| SHA-256 | `d83594447b7dac184c019371c0c296b72345585913ed03adf6e0a56f60a38b27` | `03980af335703b0352a9a43f2dff62657671db5aaf822e476a415d5e762a4927` |
| 크기 | `111,720` bytes | `58,576` bytes |
| GNU Build ID | `0d13ca40d28a8f21c54d30f4a5f1032debac9f5b` | `1c5740bed9d68420fc690f8fa86724eae03b8a4c` |
| 형식 | ARM64 AArch64 shared object, stripped | ARM64 AArch64 shared object, stripped |
| 내장 빌드 시각 | `Aug 3 2026 09:30:45` | `Aug 3 2026 09:30:42` |

`dist/pim/usr/lib/libfslvpuwrap.so.3`는
`libfslvpuwrap.so.3.0.0`을 가리키는 심볼릭 링크다.

`dist/pim/opt/pim/lib/` 아래의 동명 파일 2개는 백포트 전 stock 백업본이며
런타임 로드 대상이 아니다. 이 문서의 소스 커밋 판정은 `/usr/lib` 아래의
활성 패치본에만 적용한다.

## 재현 검증

정리된 `7014cfa`를 별도 임시 복제본에서 다음 환경으로 빌드했다.

- SDK: `/shared/fsl-imx-xwayland/5.10-hardknott`
- SDK target: `cortexa53-crypto-poky-linux`
- Hantro 의존성: `setup-deps.sh` 기본 recipe-sysroot
- 명령: `./setup-deps.sh`, `./build.sh reconf`
- 배포와 동일한 SDK `strip --strip-unneeded` 적용

일반 재빌드는 성공했고 두 산출물의 크기가 패키지 파일과 각각 정확히
일치했다. 소스의 `__DATE__`와 `__TIME__`을 원본 빌드 시각으로 맞춰 다시
빌드한 뒤 비교한 결과, 각 파일에서 달라진 것은 `.note.gnu.build-id`의
20바이트뿐이었다. 이 note section을 양쪽에서 제거하면 `cmp`와 SHA-256이
모두 일치한다.

| Build ID 제거 후 | SHA-256 |
| --- | --- |
| `libgstvpu.so` 패키지/재빌드 공통 | `e57a8655cf829dfe5874d1f812d815ba488d7fcce0e9cc6f7ae17db20355eb2f` |
| `libfslvpuwrap.so.3.0.0` 패키지/재빌드 공통 | `3256a7d4ab7c56020e7c7a4a4a490e1dddffe1748993afb7ef8a3aae7c12e8f7` |

GNU Build ID는 링크 시점의 경로와 디버그 입력에도 영향을 받으므로 다른
디렉터리에서 재빌드하면 값이 달라질 수 있다. 실행 코드와 데이터는 위의
정규화 비교에서 동일함을 확인했다.

## GitLab 이식 기준

정리된 GitLab 저장소는 `7014cfa`를 패키지 소스 기준점으로 유지하며
`pim-package-jhw-vpu` 태그가 이 커밋을 가리킨다. 이식 과정에서는 GitHub
자동화 전용 `.github/`와 잘못 추적된 autotools 생성물만 전체 이력에서
제거했다. NXP 패치 커밋과 메시지, 제품 소스, 빌드 스크립트, SDK 설정은
보존했다.
