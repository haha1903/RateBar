#!/bin/bash
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
PROMPT_FILE="$REPO_DIR/PROMPT.md"
DONE_MARKER="$REPO_DIR/.codex_all_todos_done"
LOG_FILE="${LOG_FILE:-$HOME/tmp/scoop_1_codex_output.txt}"
mkdir -p "$(dirname "$LOG_FILE")"

# Load env from interactive zsh (PROXY_OPENAI_API_KEY etc.)
ENV_DUMP="$(zsh -ic 'env' 2>/dev/null | grep -E '^(PROXY_|OPENAI_|ANTHROPIC_|PATH=)' || true)"
if [ -n "$ENV_DUMP" ]; then
    while IFS= read -r line; do
        export "$line"
    done <<< "$ENV_DUMP"
fi

FAILS=0
MAX_FAILS=3

while true; do
    if git -C "$REPO_DIR" tag | grep -q '^v0\.1\.0$'; then
        echo "Tag v0.1.0 found. Done."
        break
    fi

    if [ -f "$DONE_MARKER" ]; then
        echo "Marker $DONE_MARKER present. Done."
        cat "$DONE_MARKER"
        break
    fi

    echo "Running codex with PROMPT.md..." | tee -a "$LOG_FILE"
    if codex exec --dangerously-bypass-approvals-and-sandbox "$(cat "$PROMPT_FILE")" >> "$LOG_FILE" 2>&1; then
        FAILS=0
    else
        FAILS=$((FAILS + 1))
        echo "codex exec failed ($FAILS/$MAX_FAILS)" | tee -a "$LOG_FILE"
        if [ $FAILS -ge $MAX_FAILS ]; then
            echo "Too many consecutive failures, aborting." | tee -a "$LOG_FILE"
            "$REPO_DIR/notify.sh" "❌ run.sh aborted after $MAX_FAILS failures" || true
            exit 1
        fi
        sleep 5
        continue
    fi
    "$REPO_DIR/notify.sh" || true
done
