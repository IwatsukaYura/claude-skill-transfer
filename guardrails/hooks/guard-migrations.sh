#!/usr/bin/env bash
# PreToolUse — 適用済みマイグレーションの書き換えをブロックする。
#
# ★このフックが研修の主役である理由:
#
#   これは「Claude の暴走を止める」フックではない。
#   Claude は危険な操作なら自分から確認してくる（実測済み）。
#   ここで止めているのは、Claude が「無理のない判断」をした結果の事故である。
#
#   「002 のデフォルト値を変えて」と言われたら、002 を編集するのが唯一の方法に見える。
#   002 が本番で既に適用済みだという事実は、リポジトリのどこにも書かれていない。
#   だから Claude は防げない。どれだけ賢くても防げない。
#   人間もまた、他人が2ヶ月前に適用したマイグレーションを覚えていない。
#
#   フックは、その「リポジトリに無い事実」を実行時に持ち込む装置。
set -euo pipefail

input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // ""')
path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""')
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')

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

# 適用済みとみなすマイグレーション。実務では applied ログや DB から引くところ。
# 研修では「リポジトリの外にある事実」を模すため、ここに直書きしている。
APPLIED_UP_TO="002"

reason_for() {
  cat <<EOS
PreToolUse フックがブロックしました: $1 は本番環境で既に適用済みのマイグレーション（適用済み: 001〜${APPLIED_UP_TO}）です。

既に適用されたファイルを編集しても本番のスキーマは変わりません。新しい環境だけが違う定義で作られ、本番と検証環境が静かに食い違います。原因の分からない障害として数週間後に現れます。

正しい手順:
  1. migrations/003_<変更内容>.sql を新規作成する
  2. ALTER TABLE で差分だけを書く
  3. src/db/schema.ts の型も合わせて更新する
  4. npm run check:migrations で整合を確認する
EOS
}

# 1) 編集ツール経由
if [ -n "$path" ]; then
  case "$path" in
    */migrations/*.sql|migrations/*.sql)
      base=$(basename "$path")
      num=${base%%_*}
      # 数値として 001〜APPLIED_UP_TO の範囲なら拒否（003 以降の新規作成は通す）
      if printf '%s' "$num" | grep -Eq '^[0-9]+$' && [ "$((10#$num))" -le "$((10#$APPLIED_UP_TO))" ]; then
        # 既に存在するファイルへの書き込みだけを止める（同名の新規作成は無いが念のため）
        [ -f "$path" ] && deny "$(reason_for "$base")"
      fi
      ;;
  esac
fi

# 2) シェル経由の書き換え（sed -i / リダイレクト / mv）で迂回されるのも止める
if [ "$tool" = "Bash" ] && [ -n "$cmd" ]; then
  if printf '%s' "$cmd" | grep -Eq '(sed -i|>>?[[:space:]]*[^|]*|tee|mv|cp).*migrations/00[0-9]'; then
    if printf '%s' "$cmd" | grep -Eq "migrations/00[1-${APPLIED_UP_TO#00}]"; then
      deny "$(reason_for "適用済みマイグレーション")"
    fi
  fi
fi

exit 0
