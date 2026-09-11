#!/bin/bash
# 공통 설정. make-for-imx8.sh / setup-deps.sh / update_bin.sh 가 source 한다.
# 모든 값은 환경변수로 덮어쓸 수 있다.

# source 로 부르면 exit 가 호출한 셸을 죽인다. 실행이면 exit, source 면 return 한다.
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then _env_end='return'; else _env_end='exit'; fi

# 호스트별 경로는 이 파일 옆의 `.env`(gitignore 대상)에서 읽는다. 이미 환경에 있는
# 값이 우선이고, 없는 것만 파일에서 채운다. `cp .env.example .env` 로 시작한다.
_ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${_ENV_DIR}/.env" ]; then
    while IFS= read -r _env_line || [ -n "$_env_line" ]; do
        case "$_env_line" in ''|'#'*) continue ;; esac
        # '=' 없는 줄은 건너뛴다 — ${_env_line#*=} 가 줄 전체를 돌려줘
        # 키 이름이 값으로 들어가는 것을 막는다.
        case "$_env_line" in *=*) ;; *) continue ;; esac
        _env_k=${_env_line%%=*}
        _env_v=${_env_line#*=}
        # 파일이 임의 변수를 설정하지 못하도록 아는 키만 받는다.
        case "$_env_k" in
            SDK_LOC|SDK_NAME|HANTRO_SYSROOT|PIM_PACKAGE_DIR) ;;
            *) continue ;;
        esac
        # 값이 비었더라도 '설정됨'이면 존중한다 — :- 로 보면 일부러 비운 값 위에
        # .env 값이 되살아난다.
        [ -n "${!_env_k+set}" ] || [ -z "$_env_v" ] || printf -v "$_env_k" '%s' "$_env_v"
    done < "${_ENV_DIR}/.env"
fi

# 호스트 종속 값에는 기본값을 두지 않는다. 여기서 `: "${VAR:=}"` 로 초기화하면
# 값이 없을 때도 변수가 '설정됨' 상태가 되어, source 로 부른 뒤 .env 를 고쳐 다시
# source 해도 위 로더가 이미 설정된 것으로 보고 새 값을 넘긴다. 없는 값은 unset 으로
# 남긴다 — 읽는 쪽에서 `:-` 로 받는다.
# HANTRO_SYSROOT 는 setup-deps.sh 만, PIM_PACKAGE_DIR 은 update_bin.sh 만 쓴다.
# 둘 다 해당 스크립트에서 확인하므로 여기서는 필수로 보지 않는다.

for _env_req in SDK_LOC SDK_NAME; do
    [ -n "${!_env_req:-}" ] && continue
    echo "${_env_req} 가 비었다 — ${_ENV_DIR}/.env 를 만들어 채운다 (cp .env.example .env)" >&2
    "$_env_end" 1
done
