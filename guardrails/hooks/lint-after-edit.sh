#!/usr/bin/env bash
# PostToolUse — 編集直後にそのファイルだけを検査し、結果を Claude に返す。
#
# 体感してほしいこと:
#   ユーザーが何も言わなくても、Claude が自分で直しに戻る。
#   additionalContext で返した文字列が、そのまま次のターンの Claude の入力になる。
set -euo pipefail

input=$(cat)
path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""')

[ -z "$path" ] && exit 0
[ ! -f "$path" ] && exit 0
case "$path" in *.ts) ;; *) exit 0 ;; esac

findings=""

if grep -nE '(:|<)\s*any\b' "$path" >/dev/null 2>&1; then
  lines=$(grep -nE '(:|<)\s*any\b' "$path" | head -5 | sed 's/^/    /')
  findings="${findings}- \`any\` を使っている箇所があります。\`unknown\` で受けて絞り込んでください:\n${lines}\n"
fi

if grep -nE '^\s*console\.(log|debug)\(' "$path" >/dev/null 2>&1; then
  lines=$(grep -nE '^\s*console\.(log|debug)\(' "$path" | head -5 | sed 's/^/    /')
  findings="${findings}- \`console.log\` が残っています。削除するかロガーに置き換えてください:\n${lines}\n"
fi

if grep -nE 'catch\s*\([^)]*\)\s*\{\s*\}' "$path" >/dev/null 2>&1; then
  findings="${findings}- 空の catch があります。握りつぶす場合は理由をコメントで書いてください。\n"
fi

[ -z "$findings" ] && exit 0

context=$(printf "PostToolUse フックが %s を検査しました。以下を修正してから次に進んでください。\n\n%b" "$path" "$findings")

jq -n --arg ctx "$context" '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: $ctx
  }
}'
