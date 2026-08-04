import type { OrderRow, UserRow } from "../db/schema.js";

/** 研修用のインメモリDB。本物のDBドライバの代わり。 */
class Table<T extends { id: string }> {
  private rows = new Map<string, T>();

  constructor(seed: readonly T[]) {
    for (const row of seed) this.rows.set(row.id, row);
  }

  async findById(id: string): Promise<T | undefined> {
    await tick();
    return this.rows.get(id);
  }

  async update(id: string, patch: Partial<T>): Promise<void> {
    await tick();
    const current = this.rows.get(id);
    if (!current) return;
    this.rows.set(id, { ...current, ...patch });
  }

  async list(): Promise<T[]> {
    await tick();
    return [...this.rows.values()];
  }
}

function tick(): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, 0));
}

export const db = {
  orders: new Table<OrderRow>([
    {
      id: "ord_1",
      user_id: "usr_alice",
      total_jpy: 12800,
      cancelled: false,
      created_at: "2026-07-01T00:00:00Z",
    },
    {
      id: "ord_2",
      user_id: "usr_bob",
      total_jpy: 4500,
      cancelled: false,
      created_at: "2026-07-02T00:00:00Z",
    },
  ]),
  users: new Table<UserRow>([
    { id: "usr_alice", email: "alice@example.com", created_at: "2026-06-01T00:00:00Z" },
    { id: "usr_bob", email: "bob@example.com", created_at: "2026-06-02T00:00:00Z" },
  ]),
};
