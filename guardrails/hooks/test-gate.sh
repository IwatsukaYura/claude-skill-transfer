#!/usr/bin/env bash
# Stop — テストが落ちている間はターンを終わらせない。
#
# 体感してほしいこと:
#   「直しました」と言って終わろうとした Claude が、
#   自分の宣言が嘘だったことを突きつけられて作業に戻る。
#
# 注意: 無限ループ防止のため、同一セッションで3回までしかブロックしない。
set -uo pipefail

input=$(cat)
session=$(printf '%s' "$input" | jq -r '.session_id // "unknown"')
stop_active=$(printf '%s' "$input" | jq -r '.stop_hook_active // false')

# 既に Stop フック起因で継続中なら、そのまま通す（多重ブロック防止）
[ "$stop_active" = "true" ] && exit 0

counter="${TMPDIR:-/tmp}/claude-test-gate-${session}"
count=$(cat "$counter" 2>/dev/null || echo 0)
if [ "$count" -ge 3 ]; then
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR:-.}"

if output=$(npm test 2>&1); then
  rm -f "$counter"
  exit 0
fi

echo $((count + 1)) > "$counter"

failures=$(printf '%s' "$output" | grep -E '^(not ok|# fail|  Error|AssertionError)' | head -20)

jq -n --arg reason "$(printf 'Stop フックがブロックしました: npm test が失敗しています。テストを通してから終了してください。\n\n%s' "$failures")" '{
  decision: "block",
  reason: $reason
}'
