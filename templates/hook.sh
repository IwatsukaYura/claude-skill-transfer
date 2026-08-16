#!/usr/bin/env bash
# <イベント名> フックのひな形。stdin にイベントJSON、stdout の JSON で制御する。
#
# ★終了コード
#   0    成功。stdout の JSON が処理される  ← JSON を返したいなら必ずこれ
#   2    ブロック。stdout は無視され、stderr が理由として Claude に渡る
#   その他  非ブロックエラー。実行は続行される
set -euo pipefail

input=$(cat)

tool=$(printf '%s' "$input" | jq -r '.tool_name // ""')
path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""')
command=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')
session=$(printf '%s' "$input" | jq -r '.session_id // ""')

# --- PreToolUse: 実行前にブロックする ---------------------------------------
# permissionDecision: allow | deny | ask | defer
#   ★運用に乗るまでは "ask" から始める
#   ★理由には「なぜダメか」だけでなく「代わりに何をすべきか」を書く
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

# --- PostToolUse: 実行後に検査して結果を Claude に返す -----------------------
# additionalContext がそのまま次のターンの入力になる。
# 止めるのではなく行動を変えさせたいときはこちら。
#
# jq -n --arg ctx "検査結果: <内容>。修正してから次に進んでください。" '{
#   hookSpecificOutput: {
#     hookEventName: "PostToolUse",
#     additionalContext: $ctx
#   }
# }'

# --- Stop: 条件を満たすまでターンを終わらせない -----------------------------
# ★安全弁を必ず入れる。無いと直せない失敗で永久に終われなくなる
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
