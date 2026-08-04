CREATE TABLE users (
  id         TEXT PRIMARY KEY,
  email      TEXT NOT NULL UNIQUE,
  created_at TEXT NOT NULL
);

CREATE TABLE orders (
  id         TEXT PRIMARY KEY,
  user_id    TEXT NOT NULL REFERENCES users(id),
  total_jpy  INTEGER NOT NULL,
  cancelled  BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TEXT NOT NULL
);
