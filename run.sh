#!/bin/bash
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
PROMPT_FILE="$REPO_DIR/PROMPT.md"
DONE_MARKER="$REPO_DIR/.codex_all_todos_done"
LOG_FILE="${LOG_FILE:-$HOME/tmp/scoop_1_codex_output.txt}"
mkdir -p "$(dirname "$LOG_FILE")"

while true; do
    # Exit if release tag created
    if git -C "$REPO_DIR" tag | grep -q '^v0\.1\.0$'; then
        echo "Tag v0.1.0 found. Done."
        break
    fi

    # Exit if codex signaled "all TODOs done, only GATE remaining"
    if [ -f "$DONE_MARKER" ]; then
        echo "Marker $DONE_MARKER present — all [TODO] tasks done, only [GATE] remains. Exiting loop."
        cat "$DONE_MARKER"
        break
    fi

    echo "Running codex with PROMPT.md..."
    codex exec --dangerously-bypass-approvals-and-sandbox "$(cat "$PROMPT_FILE")" >> "$LOG_FILE" \
        || echo "codex exec failed (exit $?), retrying..." >&2
    "$REPO_DIR/notify.sh" || true
done
