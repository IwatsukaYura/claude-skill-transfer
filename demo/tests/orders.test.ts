import { test } from "node:test";
import assert from "node:assert/strict";
import { dispatch } from "../src/server.js";

const alice = { userId: "usr_alice", params: { id: "ord_1" } };

test("自分の注文を取得できる", async () => {
  const res = await dispatch("GET /orders/:id", alice);
  assert.equal(res.status, 200);
});

test("存在しない注文は404", async () => {
  const res = await dispatch("GET /orders/:id", { userId: "usr_alice", params: { id: "nope" } });
  assert.equal(res.status, 404);
});

test("他人の注文はキャンセルできない", async () => {
  const res = await dispatch("POST /orders/:id/cancel", {
    userId: "usr_bob",
    params: { id: "ord_1" },
  });
  assert.equal(res.status, 403);
});

test("自分の注文はキャンセルできる", async () => {
  const res = await dispatch("POST /orders/:id/cancel", alice);
  assert.equal(res.status, 200);
});

test("一覧は自分の注文だけ返す", async () => {
  const res = await dispatch("GET /orders", { userId: "usr_bob", params: {} });
  assert.equal(res.status, 200);
  assert.equal((res.body as unknown[]).length, 1);
});
