#!/usr/bin/env bash
# PostToolUse — 編集のたびにテストを走らせ、結果を Claude に返す。

set -euo pipefail

input=$(cat)
path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""')

[ -n "$path" ] || exit 0
case "$path" in *.ts) ;; *) exit 0 ;; esac

root="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$root"

if output=$(npm test 2>&1); then
  state="green"
else
  state="red"
fi


pick() { printf '%s' "$output" | { grep -oE "$1" || true; } | awk '{print $3}' | tail -1; }
pass=$(pick '^# pass [0-9]+')
fail=$(pick '^# fail [0-9]+')
: "${pass:=0}" "${fail:=0}"

detail=$(printf '%s' "$output" | \
  { grep -E '^not ok |AssertionError|error TS[0-9]+|expected:|actual:|Cannot find module' || true; } | head -12)

{
  printf '%s\n' "$state"
  printf '%s\n' "$detail" | head -6
} > .tdd-state

if [ "$state" = "green" ]; then
  ctx=$(printf 'テスト: GREEN（pass %s / fail 0）\n\n次にやること: 仕様の未実装ケースがまだあれば次の失敗するテストを書く。全部済んでいればリファクタに進む。' "$pass")
else
  ctx=$(printf 'テスト: RED（pass %s / fail %s）\n\n%s\n\nこの失敗を通す最小の実装だけを書いてください。先回りして他のケースを実装しないこと。' "$pass" "$fail" "$detail")
fi

jq -n --arg c "$ctx" '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: $c
  }
}'
