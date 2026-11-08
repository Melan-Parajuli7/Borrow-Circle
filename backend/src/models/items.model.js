const { pool } = require("../config/db.config");

const ITEM_SELECT = `
  i.id, i.title, i.description, i.image_url, i.category, i.condition,
  i.owner_id, i.is_group_item, i.group_name, i.is_available,
  i.created_at, i.updated_at,
  u.full_name AS owner_name, u.avatar AS owner_avatar
`;

const findById = async (id) => {
  const { rows } = await pool.query(
    `SELECT ${ITEM_SELECT}
     FROM items i
     JOIN users u ON u.id = i.owner_id
     WHERE i.id = $1`,
    [id]
  );
  return rows[0];
};

const create = async ({
  title, description, image_url, category, condition,
  owner_id, is_group_item, group_name,
}) => {
  const { rows } = await pool.query(
    `INSERT INTO items
       (title, description, image_url, category, condition, owner_id, is_group_item, group_name)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
     RETURNING id`,
    [title, description, image_url, category, condition, owner_id, is_group_item, group_name]
  );
  return findById(rows[0].id);
};

const findAll = async ({ search, category, condition, available, ownerId, limit, offset }) => {
  const where = [];
  const values = [];

  if (search) {
    values.push(`%${search}%`);
    where.push(`(i.title ILIKE $${values.length} OR i.description ILIKE $${values.length})`);
  }
  if (category) {
    values.push(category);
    where.push(`i.category = $${values.length}`);
  }
  if (condition) {
    values.push(condition);
    where.push(`i.condition = $${values.length}`);
  }
  if (available !== undefined) {
    values.push(available);
    where.push(`i.is_available = $${values.length}`);
  }
  if (ownerId) {
    values.push(ownerId);
    where.push(`i.owner_id = $${values.length}`);
  }

  const whereSql = where.length ? `WHERE ${where.join(" AND ")}` : "";

  const countResult = await pool.query(
    `SELECT COUNT(*)::int AS total FROM items i ${whereSql}`,
    values
  );

  const { rows } = await pool.query(
    `SELECT ${ITEM_SELECT}
     FROM items i
     JOIN users u ON u.id = i.owner_id
     ${whereSql}
     ORDER BY i.created_at DESC
     LIMIT $${values.length + 1} OFFSET $${values.length + 2}`,
    [...values, limit, offset]
  );

  return { items: rows, total: countResult.rows[0].total };
};

const UPDATABLE = [
  "title", "description", "image_url", "category", "condition",
  "is_group_item", "group_name", "is_available",
];

const update = async (id, data) => {
  const sets = [];
  const values = [];

  for (const field of UPDATABLE) {
    if (data[field] !== undefined) {
      values.push(data[field]);
      sets.push(`${field} = $${values.length}`);
    }
  }
  if (sets.length === 0) return findById(id);

  values.push(id);
  await pool.query(
    `UPDATE items SET ${sets.join(", ")} WHERE id = $${values.length}`,
    values
  );
  return findById(id);
};

const remove = async (id) => {
  await pool.query("DELETE FROM items WHERE id = $1", [id]);
};

const hasActiveLoan = async (id) => {
  const { rows } = await pool.query(
    "SELECT 1 FROM loans WHERE item_id = $1 AND status IN ('active', 'overdue') LIMIT 1",
    [id]
  );
  return rows.length > 0;
};

module.exports = { create, findById, findAll, update, remove, hasActiveLoan };