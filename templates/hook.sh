#!/usr/bin/env bash
# <イベント名> フックのひな形。
#
# 入力: stdin にイベントJSON
# 出力: exit 0 + stdout の JSON で制御する
#
# ★終了コードの意味（ここを間違える人が多い）
#   0    成功。stdout の JSON が処理される  ← JSON を返したいなら必ずこれ
#   2    ブロック。stdout の JSON は無視され、stderr が理由として Claude に渡る
#   その他  非ブロックエラー。実行は続行される
set -euo pipefail

input=$(cat)

# よく使う入力フィールド
tool=$(printf '%s' "$input" | jq -r '.tool_name // ""')
path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""')
command=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')
session=$(printf '%s' "$input" | jq -r '.session_id // ""')

# ---------------------------------------------------------------------------
# PreToolUse: 実行前にブロックする
# ---------------------------------------------------------------------------
# permissionDecision: allow | deny | ask | defer
#   ★運用に乗るまでは "ask" から始める。いきなり "deny" にしない
#   ★permissionDecisionReason には「なぜダメか」だけでなく
#     「代わりに何をすべきか」を書く。書かないと Claude は同じ壁にぶつかり続ける
#
# if <条件>; then
#   jq -n --arg reason "ブロックしました: <理由>。代わりに <代替案> してください。" '{
#     hookSpecificOutput: {
#       hookEventName: "PreToolUse",
#       permissionDecision: "ask",
#       permissionDecisionReason: $reason
#     }
#   }'
#   exit 0
# fi

# ---------------------------------------------------------------------------
# PostToolUse: 実行後に検査して、結果を Claude に返す
# ---------------------------------------------------------------------------
# additionalContext の文字列がそのまま次のターンの Claude の入力になる。
# 止めるのではなく行動を変えさせたいときはこちら。
#
# jq -n --arg ctx "検査結果: <内容>。修正してから次に進んでください。" '{
#   hookSpecificOutput: {
#     hookEventName: "PostToolUse",
#     additionalContext: $ctx
#   }
# }'

# ---------------------------------------------------------------------------
# Stop: 条件を満たすまでターンを終わらせない
# ---------------------------------------------------------------------------
# ★安全弁を必ず入れる。無いと直せない失敗に当たったとき永久に終われなくなる
#
# stop_active=$(printf '%s' "$input" | jq -r '.stop_hook_active // false')
# [ "$stop_active" = "true" ] && exit 0
#
# counter="${TMPDIR:-/tmp}/my-hook-${session}"
# count=$(cat "$counter" 2>/dev/null || echo 0)
# [ "$count" -ge 3 ] && exit 0
#
# if ! <検証コマンド>; then
#   echo $((count + 1)) > "$counter"
#   jq -n --arg reason "<理由>" '{decision: "block", reason: $reason}'
#   exit 0
# fi
# rm -f "$counter"

# 何も判断しない = 通常のフローに戻す
exit 0
