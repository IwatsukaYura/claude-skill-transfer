#!/usr/bin/env bash
# diff-reviewer サブエージェント用のレビュー対象を用意する。
#
# ★注意: これは「自己レビュー vs 新鮮な文脈」の比較には使えない。
#   スクリプトが作った差分は、メインセッションにとっても初見なので、
#   取り除くべきバイアスがそもそも存在しない。
#
# 用途は diff-reviewer の出力形式と tools 制約を確認することだけ。
#
#   ./scenarios/apply-review-target.sh        差分を作る
#   ./scenarios/apply-review-target.sh reset  元に戻す
set -euo pipefail
cd "$(dirname "$0")/.."

if [ "${1:-}" = "reset" ]; then
  git checkout -- .
  git clean -fdq -e scenarios
  echo "元に戻しました。"
  exit 0
fi

git diff --quiet || { echo "エラー: 未コミットの変更があります。先に reset してください。" >&2; exit 1; }

cat >> src/handlers/orders.ts <<'TS'

export type Receipt = {
  order_id: string;
  total_jpy: number;
  issued_at: string;
};

/** 領収書を発行する。発行済みフラグを立てて領収書を返す。 */
export async function issueReceipt(ctx: RequestContext): Promise<Receipt> {
  const id = ctx.params["id"];
  if (!id) throw ApiError.invalidRequest("id は必須です");

  const order = await db.orders.findById(id);
  if (!order) throw ApiError.notFound("注文");

  db.orders.update(order.id, { receipt_issued: true });

  return {
    order_id: order.id,
    total_jpy: order.total_jpy,
    issued_at: new Date().toISOString(),
  };
}
TS

python3 - <<'PY'
import pathlib

p = pathlib.Path("src/db/schema.ts")
s = p.read_text()
s = s.replace("  cancelled: boolean;", "  cancelled: boolean;\n  receipt_issued: boolean;")
p.write_text(s)

p = pathlib.Path("src/lib/db.ts")
s = p.read_text()
s = s.replace("      cancelled: false,", "      cancelled: false,\n      receipt_issued: false,")
p.write_text(s)

p = pathlib.Path("src/server.ts")
s = p.read_text()
s = s.replace(
    'import { getOrder, cancelOrder, listOrders, type RequestContext } from "./handlers/orders.js";',
    'import { getOrder, cancelOrder, listOrders, issueReceipt, type RequestContext } from "./handlers/orders.js";',
)
s = s.replace(
    '  "POST /orders/:id/cancel": cancelOrder,',
    '  "POST /orders/:id/cancel": cancelOrder,\n  "POST /orders/:id/receipt": issueReceipt,',
)
p.write_text(s)

p = pathlib.Path("tests/orders.test.ts")
s = p.read_text()
s += '''
test("領収書を発行できる", async () => {
  const res = await dispatch("POST /orders/:id/receipt", alice);
  assert.equal(res.status, 200);
});
'''
p.write_text(s)
PY

echo "レビュー対象の差分を作りました。"
echo
npm test 2>&1 | grep -E '^# (pass|fail)'
cat <<'EOS'

この状態で:
  ../guardrails.sh only agent してから
  「未コミットの差分を diff-reviewer サブエージェントでレビューして」

  ※「自己レビューと比較する」用途には使えない（冒頭のコメント参照）
EOS
