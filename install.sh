#!/usr/bin/env bash
# xcorekit/xcore/install.sh
# Installs all xcorekit public tools in one command.
# Each tool is also individually installable via its own install.sh.
# ─────────────────────────────────────────────────────────────────────────────
# Usage:
#   ./install.sh           — install all xcorekit public tools
#   ./install.sh --list    — show what would be installed
# ─────────────────────────────────────────────────────────────────────────────
# CHANGELOG (newest first)
# ─────────────────────────────────────────────────────────────────────────────
#   2026-05-05  v1.0.0 — initial master installer for xcorekit
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

# Public tools — cloned to sibling dirs of xcore
declare -a PUBLIC_TOOLS=(
    "git-core"
    "bash-core"
    "animate-core"
    "calendar-core"
    "finance-core"
)

# Private tools already in this repo (xcore/backup-space, xcore/sys-space)
declare -a PRIVATE_BINS=(
    "backup-space/bin"
    "sys-space/bin"
)

if [[ "$_MODE" == "--list" ]]; then
    printf '\n  xcorekit tools that will be installed:\n\n'
    for t in "${PUBLIC_TOOLS[@]}"; do
        printf '    %s  (public) → %s/%s\n' "$t" "$_PARENT" "$t"
    done
    for b in "${PRIVATE_BINS[@]}"; do
        printf '    %s  (private, already in repo)\n' "$b"
    done
    printf '\n'
    exit 0
fi

_sec "xcorekit install"
mkdir -p "$_USER_BIN"

# ── Public tools ──────────────────────────────────────────────────────────────
_sec "Public tools"
for repo in "${PUBLIC_TOOLS[@]}"; do
    dir="$_PARENT/$repo"
    printf '\n  [%s]\n' "$repo"
    if [[ -d "$dir/.git" ]]; then
        git -C "$dir" pull --rebase origin main --quiet 2>/dev/null \
            && _ok "Updated" || _ok "Up to date"
    else
        git clone --quiet "$_ORG/$repo.git" "$dir" \
            && _ok "Cloned" || { _err "Failed to clone $repo"; continue; }
    fi
    if [[ -f "$dir/install.sh" ]]; then
        bash "$dir/install.sh"
    else
        # Fallback: wire PATH + link bins directly
        bin_dir="$dir/cli/bin"
        if [[ -d "$bin_dir" ]]; then
            chmod +x "$bin_dir"/* 2>/dev/null || true
            if ! grep -qF "$bin_dir" "$_RC" 2>/dev/null; then
                printf '\n# xcorekit/%s\nexport PATH="%s:$PATH"\n' "$repo" "$bin_dir" >> "$_RC"
                _add "PATH: $bin_dir"
            fi
            for f in "$bin_dir"/*; do
                [[ -f "$f" ]] || continue
                ln -sf "$f" "$_USER_BIN/$(basename "$f")"
                _run "Linked: $(basename "$f")"
            done
        fi
    fi
done

# ── Private tools (backup-space, sys-space) ───────────────────────────────────
_sec "Private tools"
for rel_bin in "${PRIVATE_BINS[@]}"; do
    bin_dir="$_ROOT/$rel_bin"
    if [[ -d "$bin_dir" ]]; then
        label="xcore/${rel_bin%/bin}"
        if ! grep -qF "$bin_dir" "$_RC" 2>/dev/null; then
            printf '\n# %s\nexport PATH="%s:$PATH"\n' "$label" "$bin_dir" >> "$_RC"
            _add "PATH: $label"
        else
            _ok "Already in PATH: $label"
        fi
        chmod +x "$bin_dir"/* 2>/dev/null || true
        for f in "$bin_dir"/*; do
            [[ -f "$f" ]] || continue
            ln -sf "$f" "$_USER_BIN/$(basename "$f")"
            _run "Linked: $(basename "$f")"
        done
    else
        printf '  (no %s — skipping)\n' "$rel_bin"
    fi
done

_sec "Done"
printf '  All xcorekit tools installed.\n'
printf '  Run: source ~/.bashrc\n\n'
