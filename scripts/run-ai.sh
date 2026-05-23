#!/bin/bash
# AI News Daily — launchd에서 실행되는 스크립트
# Schedule: cron 08:00 KST

export PATH="/Users/leoheo/.local/bin:/Users/leoheo/.nvm/versions/node/v22.22.0/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
export HOME="/Users/leoheo"

cd /Users/leoheo/dev/ai-news

TOPIC="ai"
DATE=$(date +%Y-%m-%d)
LOG="/Users/leoheo/dev/ai-news/logs/generate-${TOPIC}-${DATE}.log"

echo "=== ${TOPIC} News Daily: ${DATE} $(date +%H:%M:%S) ===" >> "$LOG"

claude -p \
  --dangerously-skip-permissions \
  --allowedTools "WebSearch,WebFetch,Bash,Read,Write,Edit,Glob,Grep" \
  --model sonnet \
  "Read scripts/generate.md and follow ALL instructions exactly. Execute the full 7-step pipeline. Topic is '${TOPIC}'. Today's date is ${DATE}." \
  >> "$LOG" 2>&1

echo "=== Completed: $(date +%H:%M:%S) ===" >> "$LOG"
