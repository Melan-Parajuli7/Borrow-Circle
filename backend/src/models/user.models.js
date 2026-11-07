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
  updateProfile,
  updatePassword,
};
