/**
 * migrations/ の内容と手で同期させている型定義。
 * ズレると本番で落ちるが、tsc も npm test も検知しない。
 * 同期チェックは scripts/check-migration-sync.sh で行う。
 */

export type OrderRow = {
  id: string;
  user_id: string;
  total_jpy: number;
  cancelled: boolean;
  created_at: string;
};

export type UserRow = {
  id: string;
  email: string;
  created_at: string;
};

export const TABLES = ["orders", "users"] as const;
