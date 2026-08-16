#!/usr/bin/env bash
# セットアップ。最初に1回実行する。
# ネットワークが必要なのはここだけ。以降はオフラインでも回る。
set -euo pipefail
cd "$(dirname "$0")"

echo "==> 前提コマンドの確認"
for c in node npm git jq claude; do
  if command -v "$c" >/dev/null 2>&1; then
    echo "    OK  $c ($($c --version 2>&1 | head -1))"
  else
    echo "    NG  $c が見つかりません" >&2
    [ "$c" = "jq" ] && echo "        brew install jq" >&2
    exit 1
  fi
done

echo "==> 依存パッケージ"
( cd demo && npm install --silent )

echo "==> ビルドとテスト（5件パスするのが正しい）"
( cd demo && npm test 2>&1 | grep -E '^# (pass|fail)' )

echo "==> マイグレーション整合チェック（NG が出るのが正しい）"
( cd demo && npm run check:migrations 2>&1 | tail -1 ) || true

echo "==> git リポジトリの初期化（diff レビューのデモに必要）"
if [ ! -d demo/.git ]; then
  ( cd demo \
    && git init -q \
    && git add -A \
    && git -c user.email=workshop@example.com -c user.name=workshop \
         commit -qm "chore: 研修デモの初期状態" )
  echo "    初期コミットを作成しました"
else
  echo "    既に git リポジトリです"
fi

echo "==> 実行権限とガードレールOFF"
chmod +x guardrails.sh guardrails/hooks/*.sh demo/scripts/*.sh
./guardrails.sh off

cat <<'EOS'

セットアップ完了。

  ./guardrails.sh status      いま何が有効か
  ./guardrails.sh only skill  1枚だけ有効化
  ./guardrails.sh off         素の状態に戻す

demo/ をカレントにして claude を起動する:
  cd demo && claude
EOS
