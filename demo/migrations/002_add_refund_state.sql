-- 返金フロー対応。src/db/schema.ts の OrderRow にも同じ列を足すこと。
ALTER TABLE orders ADD COLUMN refund_state TEXT NOT NULL DEFAULT 'none';
