const { pool } = require("../config/db.config");

const create = async ({ user_id, token_hash, expires_at }) => {
  await pool.query(
    `INSERT INTO refresh_tokens (user_id, token_hash, expires_at)
     VALUES ($1, $2, $3)`,
    [user_id, token_hash, expires_at]
  );
};

// Atomically revokes a token IF it is still valid.
// Returns the row on success, undefined if unknown / already revoked / expired.
// Being atomic means two simultaneous refreshes can't both succeed.
const revokeIfActive = async (token_hash) => {
  const { rows } = await pool.query(
    `UPDATE refresh_tokens
     SET revoked = TRUE
     WHERE token_hash = $1 AND revoked = FALSE AND expires_at > NOW()
     RETURNING user_id`,
    [token_hash]
  );
  return rows[0];
};

const revokeByHash = async (token_hash) => {
  await pool.query(
    "UPDATE refresh_tokens SET revoked = TRUE WHERE token_hash = $1",
    [token_hash]
  );
};

const revokeAllForUser = async (user_id) => {
  await pool.query(
    "UPDATE refresh_tokens SET revoked = TRUE WHERE user_id = $1",
    [user_id]
  );
};

// optional housekeeping, call occasionally
const deleteExpired = async () => {
  await pool.query("DELETE FROM refresh_tokens WHERE expires_at < NOW()");
};

module.exports = { create, revokeIfActive, revokeByHash, revokeAllForUser, deleteExpired };