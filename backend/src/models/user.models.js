const { pool } = require("../config/db.config");

const SAFE_FIELDS =
  "id , full_name, email , role, avatar, created_at , updated_at";

const create = async ({ full_name, email, password }) => {
  const { rows } = await pool.query(
    `INSERT INTO users(full_name , email , password) 
        VALUES ($1, $2, $3)
        RETURNING ${SAFE_FIELDS}`,
    [full_name, email, password],
  );
  return rows[0];
};

// find email
const findByEmail = async (email) => {
  const { rows } = await pool.query(
    `SELECT ${SAFE_FIELDS} FROM users WHERE EMAIL = $1`, [email],
  );
  return rows[0];
};

// select password || used at login only
const findByEmailwithPassword = async (email) => {
  const { rows } = await pool.query(
    `
        SELECT * FROM users WHERE email = $1`,
    [email],
  );
  return rows[0];
};

// find user by ID
const findById = async (id) => {
  const { rows } = await pool.query(
    `SELECT ${SAFE_FIELDS} FROM users WHERE id = $1`,
    [id],
  );
  return rows[0];
};

// find user by id wihh passowrd
const findByIdwithPassowrd = async (id) => {
  const { rows } = await pool.query(`SELECT * FROM users WHERE id = $1`, [id]);
  return rows[0];
};

// find the first user holding a role (used to pick an admin for support chats)
const findByRole = async (role) => {
  const { rows } = await pool.query(
    `SELECT ${SAFE_FIELDS} FROM users WHERE role = $1 ORDER BY id LIMIT 1`,
    [role]
  );
  return rows[0];
};

// Admin list: every user with live counters, newest first.
// `search` matches name or email; `role` narrows to user/admin.
const findAll = async ({ search, role, limit = 20, offset = 0 } = {}) => {
  const params = [];
  let where = "TRUE";

  if (search) {
    params.push(`%${search}%`);
    where += ` AND (u.full_name ILIKE $${params.length} OR u.email ILIKE $${params.length})`;
  }
  if (role) {
    params.push(role);
    where += ` AND u.role = $${params.length}`;
  }

  const count = await pool.query(
    `SELECT COUNT(*)::int AS total FROM users u WHERE ${where}`,
    params,
  );
  const { rows } = await pool.query(
    `SELECT ${SAFE_FIELDS},
            (SELECT COUNT(*)::int FROM items i WHERE i.owner_id = u.id) AS items_count,
            (SELECT COUNT(*)::int FROM borrow_requests br WHERE br.requester_id = u.id) AS requests_count,
            (SELECT COUNT(*)::int FROM loans l
              WHERE l.borrower_id = u.id OR l.owner_id = u.id) AS loans_count
       FROM users u
      WHERE ${where}
      ORDER BY u.created_at DESC, u.id DESC
      LIMIT $${params.length + 1} OFFSET $${params.length + 2}`,
    [...params, limit, offset],
  );
  return { users: rows, total: count.rows[0].total };
};

// Promote / demote a user (admin dashboard)
const updateRole = async (id, role) => {
  const { rows } = await pool.query(
    `UPDATE users SET role = $1, updated_at = NOW()
      WHERE id = $2
      RETURNING ${SAFE_FIELDS}`,
    [role, id],
  );
  return rows[0];
};

// Returns false when nothing matched, so the service can answer 404
const remove = async (id) => {
  const { rowCount } = await pool.query(
    `DELETE FROM users WHERE id = $1`,
    [id],
  );
  return rowCount > 0;
};

// update user 
const updateProfile = async (id , {full_name, avatar}) => {
    const {rows} = await pool.query(
        `UPDATE users
        SET full_name = COALESCE($1, full_name),
        avatar = COALESCE($2, avatar)
        WHERE id = $3
        RETURNING ${SAFE_FIELDS}`,
        [full_name ?? null, avatar ?? null , id]
    );
    return rows[0];
}

// update password(hashed)
const updatePassword = async (id , hashedPassword) => {
    await pool.query(`UPDATE users SET password = $1 WHERE id = $2`, [hashedPassword, id])
};

module.exports = {
  create,
  findByEmail,
  findByEmailwithPassword,
  findById,
  findByIdwithPassowrd,
  findByRole,
  findAll,
  updateRole,
  remove,
  updateProfile,
  updatePassword,
};
