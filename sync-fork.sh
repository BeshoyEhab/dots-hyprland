#!/usr/bin/env bash
# Sync fork with upstream while preserving local changes
# Usage: ./sync-fork.sh [--commit]

set -euo pipefail

UPSTREAM="https://github.com/end-4/dots-hyprland.git"
BRANCH="main"
DO_COMMIT=false

[[ "${1:-}" == "--commit" ]] && DO_COMMIT=true

info()  { printf "\033[1;34m:: %s\033[0m\n" "$1"; }
ok()    { printf "\033[1;32m:: %s\033[0m\n" "$1"; }
warn()  { printf "\033[1;33m:: %s\033[0m\n" "$1"; }
err()   { printf "\033[1;31m:: %s\033[0m\n" "$1"; }

# Ensure we're in a git repo
git rev-parse --is-inside-work-tree &>/dev/null || { err "Not a git repository"; exit 1; }

# Add upstream if missing
if ! git remote get-url upstream &>/dev/null; then
    info "Adding upstream remote..."
    git remote add upstream "$UPSTREAM"
fi

info "Fetching upstream..."
git fetch upstream

# Check if there's anything to merge
CURRENT=$(git rev-parse HEAD)
UPSTREAM_MAIN=$(git rev-parse upstream/main)

if [[ "$CURRENT" == "$UPSTREAM_MAIN" ]]; then
    ok "Already up-to-date with upstream"
    exit 0
fi

# Check for uncommitted changes
HAS_CHANGES=false
if ! git diff --quiet || ! git diff --cached --quiet; then
    HAS_CHANGES=true
fi
HAS_UNTRACKED=false
if [[ -n $(git ls-files --others --exclude-standard) ]]; then
    HAS_UNTRACKED=true
fi

STASHED=false
if [ "$HAS_CHANGES" = true ] || [ "$HAS_UNTRACKED" = true ]; then
    info "Stashing local changes..."
    local stash_args=(-m "sync-fork auto-stash $(date +%Y%m%d-%H%M%S)")
    [ "$HAS_UNTRACKED" = true ] && stash_args+=(--include-untracked)
    git stash push "${stash_args[@]}"
    STASHED=true
fi

# Merge upstream
info "Merging upstream/main..."
if git merge upstream/main --no-edit; then
    ok "Merge successful"
else
    err "Merge conflict! Resolve manually:"
    git diff --name-only --diff-filter=U
    if $STASHED; then
        warn "Your stashed changes are still in git stash. Run 'git stash pop' after resolving."
    fi
    exit 1
fi

# Restore stashed changes
if $STASHED; then
    info "Restoring stashed changes..."
    if git stash pop; then
        ok "Local changes restored"
    else
        warn "Conflicts while restoring. Resolve manually, then run 'git stash drop' if clean."
        exit 1
    fi
fi

# Commit if requested
if $DO_COMMIT; then
    if ! git diff --quiet || ! git diff --cached --quiet || [[ -n $(git ls-files --others --exclude-standard) ]]; then
        info "Committing all changes..."
        git add -A
        git commit -m "sync with upstream + local fixes $(date +%Y-%m-%d)"
        ok "Changes committed"
    else
        ok "Nothing to commit"
    fi
fi

ok "Done! Upstream synced."
echo ""
echo "Current status:"
git log --oneline -3
echo ""
git status --short | head -10
[[ $(git status --short | wc -l) -gt 10 ]] && echo "... and $(($(git status --short | wc -l) - 10)) more"
