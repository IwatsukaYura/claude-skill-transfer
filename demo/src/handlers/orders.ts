import { db } from "../lib/db.js";
import { ApiError } from "../lib/errors.js";
import type { OrderRow } from "../db/schema.js";

export type RequestContext = {
  /** 認証ミドルウェアが解決した呼び出し元のユーザーID */
  userId: string;
  params: Record<string, string | undefined>;
};

export async function getOrder(ctx: RequestContext): Promise<OrderRow> {
  const id = ctx.params["id"];
  if (!id) throw ApiError.invalidRequest("id は必須です");

  const order = await db.orders.findById(id);
  if (!order) throw ApiError.notFound("注文");

  return order;
}

export async function cancelOrder(ctx: RequestContext): Promise<{ cancelled: true }> {
  const id = ctx.params["id"];
  if (!id) throw ApiError.invalidRequest("id は必須です");

  const order = await db.orders.findById(id);
  if (!order) throw ApiError.notFound("注文");
  if (order.user_id !== ctx.userId) {
    throw ApiError.forbidden("他人の注文はキャンセルできません");
  }

  db.orders.update(order.id, { cancelled: true });

  return { cancelled: true };
}

export async function listOrders(ctx: RequestContext): Promise<OrderRow[]> {
  const all = await db.orders.list();
  return all.filter((o) => o.user_id === ctx.userId);
}
