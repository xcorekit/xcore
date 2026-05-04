#!/usr/bin/env bash
# xcore/install.sh — xcorekit master installer
# Installs all xcorekit public tools in one command.
# Each tool is also individually installable via its own install.sh.
# ─────────────────────────────────────────────────────────────────────────────
# CHANGELOG (newest first)
# ─────────────────────────────────────────────────────────────────────────────
#   2026-05-03  Initial master installer
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

_XCORE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_PARENT="$(cd "$_XCORE_ROOT/.." && pwd)"   # Systems/XCore/
_GITHUB_ORG="git@github.com:xcorekit"
_RC="${HOME}/.bashrc"

printf '\n  xcorekit install\n  ────────────────\n\n'

# ── Helper: clone or pull a public tool ──────────────────────────────────────
_install_tool() {
    local name="$1"
    local dir="$_PARENT/$name"
    printf '  [%s]\n' "$name"
    if [[ -d "$dir/.git" ]]; then
        printf '    pulling latest...\n'
        git -C "$dir" pull --rebase origin main 2>/dev/null || \
            printf '    ! pull failed — continuing\n'
    else
        printf '    cloning...\n'
        git clone "$_GITHUB_ORG/$name.git" "$dir" --quiet
    fi
    if [[ -f "$dir/install.sh" ]]; then
        bash "$dir/install.sh"
    fi
    printf '\n'
}

# ── Install all public tools ─────────────────────────────────────────────────
_install_tool "git-core"
_install_tool "bash-core"
_install_tool "animate-core"
_install_tool "calendar-core"
_install_tool "finance-core"

# ── Private tools (backup-space, sys-space) already in this repo ─────────────
if [[ -f "$_XCORE_ROOT/backup-space/bin/backupx" ]]; then
    _BIN="$_XCORE_ROOT/backup-space/bin"
    [[ ":$PATH:" != *":$_BIN:"* ]] && \
        printf '\n# xcore backup-space\nexport PATH="$PATH:%s"\n' "$_BIN" >> "$_RC"
fi
if [[ -f "$_XCORE_ROOT/sys-space/bin/updatex" ]]; then
    _BIN="$_XCORE_ROOT/sys-space/bin"
    [[ ":$PATH:" != *":$_BIN:"* ]] && \
        printf '\n# xcore sys-space\nexport PATH="$PATH:%s"\n' "$_BIN" >> "$_RC"
fi

printf '  ✓  All xcorekit tools installed.\n'
printf '  Run: source ~/.bashrc\n\n'
