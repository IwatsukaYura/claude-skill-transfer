import { test } from "node:test";
import assert from "node:assert/strict";
import { floorYen, taxOf, prorate } from "../src/money.js";

test("floorYen は円未満を切り捨てる", () => {
  assert.equal(floorYen(25.2), 25);
  assert.equal(floorYen(25.9), 25);
  assert.equal(floorYen(25), 25);
});

test("taxOf は税率ごとの税額を切り捨てで返す", () => {
  assert.equal(taxOf(315, 8), 25);
  assert.equal(taxOf(900, 10), 90);
  assert.equal(taxOf(0, 10), 0);
});

test("prorate は分母0のとき0を返す", () => {
  assert.equal(prorate(200, 1000, 1300), 153);
  assert.equal(prorate(200, 0, 0), 0);
});
