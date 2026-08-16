// SPEC.md の具体例だけから作った受け入れテスト。
// 実装を見ずに仕様書だけで書いてある。OFF/ON の実装を同じ基準で採点する。
import { test } from "node:test";
import assert from "node:assert/strict";
import { calculateInvoice } from "../src/invoice.js";

test("例1: 単一税率 ノート300×3 10%", () => {
  const r = calculateInvoice([{ name: "ノート", unitPriceJpy: 300, quantity: 3, taxRate: 10 }]);
  assert.equal(r.subtotalJpy, 900);
  assert.equal(r.totalTaxJpy, 90);
  assert.equal(r.totalJpy, 990);
});

test("例2★ R2: 税率ごとに1回だけ税額計算（105×3 の 8% は 25、24ではない）", () => {
  const r = calculateInvoice([
    { name: "りんご", unitPriceJpy: 105, quantity: 1, taxRate: 8 },
    { name: "みかん", unitPriceJpy: 105, quantity: 1, taxRate: 8 },
    { name: "ぶどう", unitPriceJpy: 105, quantity: 1, taxRate: 8 },
  ]);
  assert.equal(r.subtotalJpy, 315);
  assert.equal(r.totalTaxJpy, 25, "明細ごとに端数処理すると24になる");
  assert.equal(r.totalJpy, 340);
});

test("例3: 複数税率と taxByRate の並び順（10%が先）", () => {
  const r = calculateInvoice([
    { name: "弁当", unitPriceJpy: 500, quantity: 2, taxRate: 8 },
    { name: "文具", unitPriceJpy: 300, quantity: 1, taxRate: 10 },
  ]);
  assert.equal(r.subtotalJpy, 1300);
  assert.equal(r.totalTaxJpy, 110);
  assert.equal(r.totalJpy, 1410);
  assert.deepEqual(r.taxByRate.map((t) => t.rate), [10, 8]);
});

test("例4: クーポンの按分（各税率の課税対象額を切り捨て）", () => {
  const r = calculateInvoice(
    [
      { name: "弁当", unitPriceJpy: 500, quantity: 2, taxRate: 8 },
      { name: "文具", unitPriceJpy: 300, quantity: 1, taxRate: 10 },
    ],
    { code: "C200", discountJpy: 200 },
  );
  assert.equal(r.subtotalJpy, 1100);
  const t8 = r.taxByRate.find((t) => t.rate === 8);
  const t10 = r.taxByRate.find((t) => t.rate === 10);
  assert.equal(t8?.taxableJpy, 847);
  assert.equal(t10?.taxableJpy, 254);
});

test("R5: クーポンが小計以上なら全部0", () => {
  const r = calculateInvoice(
    [{ name: "ノート", unitPriceJpy: 300, quantity: 1, taxRate: 10 }],
    { code: "BIG", discountJpy: 5000 },
  );
  assert.equal(r.subtotalJpy, 0);
  assert.equal(r.totalTaxJpy, 0);
  assert.equal(r.totalJpy, 0);
});

test("R6: 明細が空", () => {
  const r = calculateInvoice([]);
  assert.equal(r.subtotalJpy, 0);
  assert.equal(r.totalTaxJpy, 0);
  assert.equal(r.totalJpy, 0);
  assert.deepEqual(r.taxByRate, []);
});

test("R7: quantity が 0 以下で InvoiceError", () => {
  assert.throws(
    () => calculateInvoice([{ name: "x", unitPriceJpy: 100, quantity: 0, taxRate: 10 }]),
    (e: unknown) => e instanceof Error && /quantity/.test(e.message),
  );
});

test("R7: unitPriceJpy が負で InvoiceError", () => {
  assert.throws(
    () => calculateInvoice([{ name: "x", unitPriceJpy: -1, quantity: 1, taxRate: 10 }]),
    (e: unknown) => e instanceof Error && /unitPriceJpy/.test(e.message),
  );
});

test("R7: discountJpy が負で InvoiceError", () => {
  assert.throws(
    () => calculateInvoice([{ name: "x", unitPriceJpy: 100, quantity: 1, taxRate: 10 }], { code: "N", discountJpy: -5 }),
    (e: unknown) => e instanceof Error && /discountJpy/.test(e.message),
  );
});

test("R8: その税率の明細が無ければ taxByRate に含めない", () => {
  const r = calculateInvoice([{ name: "弁当", unitPriceJpy: 500, quantity: 1, taxRate: 8 }]);
  assert.deepEqual(r.taxByRate.map((t) => t.rate), [8]);
});
