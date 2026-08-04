import { getOrder, cancelOrder, listOrders, type RequestContext } from "./handlers/orders.js";
import { ApiError, toErrorBody } from "./lib/errors.js";

type Route = (ctx: RequestContext) => Promise<unknown>;

const routes: Record<string, Route> = {
  "GET /orders": listOrders,
  "GET /orders/:id": getOrder,
  "POST /orders/:id/cancel": cancelOrder,
};

export async function dispatch(
  route: string,
  ctx: RequestContext,
): Promise<{ status: number; body: unknown }> {
  const handler = routes[route];
  if (!handler) return { status: 404, body: { error: { code: "not_found", message: "no route" } } };

  try {
    return { status: 200, body: await handler(ctx) };
  } catch (err) {
    if (err instanceof ApiError) {
      return { status: err.status, body: toErrorBody(err) };
    }
    throw err;
  }
}
