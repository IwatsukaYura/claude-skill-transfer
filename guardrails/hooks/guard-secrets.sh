#!/usr/bin/env bash
# PreToolUse — 秘密情報を含むファイルへの書き込みを「確実に」止める。
#
# CLAUDE.md の「.env は編集しない」との違い:
#   CLAUDE.md   … あなたが書いた文字列に、Claude が気づけば従う（お願い）
#   このフック  … パターンに一致したら Claude の判断に関係なく止まる（強制）
#
# 入力: stdin に PreToolUse のイベントJSON
# 出力: 拒否するときだけ permissionDecision: deny を stdout に出して exit 0
set -euo pipefail

input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // ""')

# 対象パスの取り出し（Write / Edit 系）
path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""')
# Bash の場合はコマンド文字列を見る
command=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')

deny() {
  jq -n --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

# 1) .env / .env.local / .env.production / secrets.* などへの書き込み
if [ -n "$path" ]; then
  base=$(basename "$path")
  case "$base" in
    .env|.env.*|*.pem|*.key|secrets.*|credentials.*)
      deny "PreToolUse フックがブロックしました: '${base}' は秘密情報を含むファイルです。値の追加・変更は人間が手元で行ってください。必要な場合は .env.example にキー名だけを追記する形で提案してください。"
      ;;
  esac
fi

# 2) シェル経由の書き込みで迂回されるのも止める
if [ "$tool" = "Bash" ] && [ -n "$command" ]; then
  if printf '%s' "$command" | grep -Eq '(>>?|tee|cp|mv|sed -i).*\.env'; then
    deny "PreToolUse フックがブロックしました: シェル経由でも .env 系ファイルへの書き込みは禁止です。"
  fi
  if printf '%s' "$command" | grep -Eq '(sk_live_|sk_test_|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY)'; then
    deny "PreToolUse フックがブロックしました: コマンドに秘密情報らしき文字列が含まれています。"
  fi
fi

# 判断しない = 通常の権限フローに戻す
exit 0
