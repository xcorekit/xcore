#!/usr/bin/env bash
# xcore/install.sh — xcorekit barrel installer
# Installs every xcorekit public tool in one command.
# Each tool is also individually installable via its own install.sh.
# ─────────────────────────────────────────────────────────────────────────────
# Usage:
#   ./install.sh           — install all xcorekit tools
#   ./install.sh --list    — show what will be installed
#   ./install.sh --update  — pull all repos + re-link
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_PARENT="$(cd "$_ROOT/.." && pwd)"    # XCore/
_ORG="git@github.com:xcorekit"
_USER_BIN="${HOME}/bin"
_RC="${HOME}/.bashrc"
_MODE="${1:-}"

_ok()  { printf '  \033[32m✓\033[0m  %s\n' "$*"; }
_add() { printf '  \033[33m+\033[0m  %s\n' "$*"; }
_run() { printf '  \033[2m~\033[0m  %s\n' "$*"; }
_err() { printf '  \033[31m✗\033[0m  %s\n' "$*" >&2; }
_sec() { printf '\n  \033[1m%s\033[0m\n  %s\n' "$1" "$(printf '─%.0s' $(seq 1 ${#1}))"; }

# Public tools from xcore.conf
source "$_ROOT/xcore.conf"

if [[ "$_MODE" == "--list" ]]; then
    printf '\n  xcorekit tools:\n\n'
    for t in "${XCOREKIT_PUBLIC[@]}"; do
        local_dir="$_PARENT/$t"
        status="not cloned"
        [[ -d "$local_dir/.git" ]] && status="installed"
        printf '    %-20s → %s  (%s)\n' "$t" "$local_dir" "$status"
    done
    printf '\n'
    exit 0
fi

if [[ "$_MODE" == "--update" ]]; then
    _sec "Updating all xcorekit tools"
    for repo in "${XCOREKIT_PUBLIC[@]}"; do
        dir="$_PARENT/$repo"
        [[ -d "$dir/.git" ]] || continue
        printf '  [%s] ' "$repo"
        git -C "$dir" pull --rebase origin main --quiet 2>/dev/null \
            && _ok "updated" || _ok "up to date"
    done
    printf '\n  ✓  All tools updated.\n\n'
    exit 0
fi

_sec "xcorekit barrel install"
mkdir -p "$_USER_BIN"

for repo in "${XCOREKIT_PUBLIC[@]}"; do
    dir="$_PARENT/$repo"
    printf '\n  [%s]\n' "$repo"

    # Clone if not present, pull if already there
    if [[ -d "$dir/.git" ]]; then
        git -C "$dir" pull --rebase origin main --quiet 2>/dev/null \
            && _ok "Updated" || _ok "Up to date"
    else
        git clone --quiet "$_ORG/$repo.git" "$dir" \
            && _ok "Cloned" \
            || { _err "Failed to clone $repo — skipping"; continue; }
    fi

    # Run the tool's own install.sh
    if [[ -f "$dir/install.sh" ]]; then
        bash "$dir/install.sh"
    else
        # Fallback: wire PATH + link directly
        bin_dir="$dir/cli/bin"
        if [[ -d "$bin_dir" ]]; then
            chmod +x "$bin_dir"/* 2>/dev/null || true
            if ! grep -qF "$bin_dir" "$_RC" 2>/dev/null; then
                printf '\n# xcorekit/%s\nexport PATH="%s:$PATH"\n' "$repo" "$bin_dir" >> "$_RC"
                _add "PATH wired"
            fi
            for f in "$bin_dir"/*; do
                [[ -f "$f" ]] || continue
                ln -sf "$f" "$_USER_BIN/$(basename "$f")"
                _run "Linked: $(basename "$f")"
            done
        fi
    fi
done

_sec "Done"
printf '  All xcorekit tools installed.\n'
printf '  Run: source ~/.bashrc\n\n'
