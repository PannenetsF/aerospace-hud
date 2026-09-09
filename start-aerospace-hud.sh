#!/usr/bin/env bash
set -euo pipefail

# Standalone launcher for aerospace-hud. Compiles the indicator on first run
# (or whenever the source is newer than the cached binary) and execs it.
#
# Layout is overridable via environment so this drops cleanly into any
# dotfiles/launchd setup:
#   AEROSPACE_HUD_SOURCE   path to workspace_indicator.swift (default: alongside this script)
#   AEROSPACE_HUD_CACHE    directory for the compiled binary (default: ~/Library/Caches/aerospace-hud)
#   AEROSPACE_HUD_LOG      build/runtime log file
#   AEROSPACE_HUD_DIRTY    dirty-file path AeroSpace touches on workspace change

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source_file="${AEROSPACE_HUD_SOURCE:-${script_dir}/workspace_indicator.swift}"
cache_dir="${AEROSPACE_HUD_CACHE:-${HOME}/Library/Caches/aerospace-hud}"
log_dir="$(dirname "${AEROSPACE_HUD_LOG:-${HOME}/Library/Logs/aerospace-hud/aerospace-hud.log}")"
log_file="${AEROSPACE_HUD_LOG:-${log_dir}/aerospace-hud.log}"
dirty_file="${AEROSPACE_HUD_DIRTY:-/tmp/aerospace-workspace-indicator-dirty}"

binary="${cache_dir}/aerospace-hud"

mkdir -p "${cache_dir}" "${log_dir}"
: >"${dirty_file}"

if [[ -f "${source_file}" && -x /usr/bin/swiftc ]]; then
	if [[ ! -x "${binary}" || "${source_file}" -nt "${binary}" ]]; then
		tmp_binary="${binary}.$$"
		if /usr/bin/swiftc "${source_file}" -o "${tmp_binary}" >>"${log_file}" 2>&1; then
			mv "${tmp_binary}" "${binary}"
		else
			rm -f "${tmp_binary}"
		fi
	fi
fi

if [[ ! -x "${binary}" ]]; then
	echo "aerospace-hud binary is missing (swiftc build failed; see ${log_file})" >>"${log_file}"
	exit 1
fi

pkill -x aerospace-hud >/dev/null 2>&1 || true
exec "${binary}" "${dirty_file}"
