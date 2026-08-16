#!/usr/bin/env bash
# TDDデモのセットアップ。最初に1回実行する。
set -euo pipefail
cd "$(dirname "$0")"

echo "==> 前提コマンド"
for c in node npm jq claude; do
  command -v "$c" >/dev/null 2>&1 \
    && echo "    OK  $c ($($c --version 2>&1 | head -1))" \
    || { echo "    NG  $c が見つかりません" >&2; [ "$c" = jq ] && echo "        brew install jq" >&2; exit 1; }
done

echo "==> 依存パッケージ"
( cd app && npm install --silent )

echo "==> 開始状態の確認（money のテスト3本だけが緑になるのが正しい）"
chmod +x guardrails.sh guardrails/hooks/*.sh
./guardrails.sh reset

echo "==> ガードレールOFF"
./guardrails.sh off

cat <<'EOS'

セットアップ完了。

  ./guardrails.sh off     素の Claude Code
  ./guardrails.sh on      全部入り
  ./guardrails.sh reset   app/ を開始状態に戻す（切り替えのたびに実行）
  ./guardrails.sh status  いまの状態

app/ をカレントにして起動する:
  cd app && claude

詳しくは ./README.md
EOS
