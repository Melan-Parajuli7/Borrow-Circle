const { pool } = require("../config/db.config");

// `stage`  is derived , so the app doesnt have to interpret hand_over_at / request_at
const LOAN_SELECT = `
    l.id , l.request_id , l.item_id , l.borrower_id , l.owner_id, 
    to_char(l.start_date , 'YYYY-MM-DD') AS start_date,
    to_char(l.end_date, 'YYYY-MM-DD') AS end_date,
    l.status , l.handed_over_at , l.returned_at , l.created_at , l.updated_at,
    CASE
        WHEN l.returned_at IS NOT NULL THEN 'returned'
        WHEN l.handed_over_at IS NULL THEN 'awaiting_handover'
        WHEN l.status = 'overdue' THEN 'overdue'
        ELSE 'on_loan'
    END AS stage,
    i.title AS item_title , i.image_url AS item_image,
    b.full_name AS borrower_name, b.avatar AS borrower_avatar,
    o.full_name AS owner_name, o.avatar AS owner_avatar
`;

const LOAN_FROM = `
  FROM loans l
  JOIN items i ON i.id = l.item_id
  JOIN users b ON b.id = l.borrower_id
  JOIN users o ON o.id = l.owner_id
`;

// Runs several queries as one unit: all succeed or none do
const withTransaction = async (fn) => {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    const result = await fn(client);
    await client.query("COMMIT");
    return result;
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release(); // always give the connection back to the pool
  }
};

// Loans past end_date that were handed over but not returned become 'overdue'.
// Called before every read , so no scheduled job is needed yet
const markOverdue = async () => {
  await pool.query(
    `UPDATE loans SET status= 'overdue'
        WHERE status = 'active' AND handed_over_at IS NOT NULL AND end_date < CURRENT_DATE`,
  );
};

// Small lookup of a borrow request (so this module doesn't depend on the requests model)
const findRequest = async (id) => {
  const { rows } = await pool.query(
    `SELECT br.id , br.status, br.requester_id , i.owner_id
            FROM borrow_requests br
            JOIN items i ON i.id = br.item_id
            WHERE br.id = $1`,
    [id],
  );
  return rows[0];
};

const findByRequestId = async (requestId) => {
  const { rows } = await pool.query(
    "SELECT id FROM loans WHERE request_id = $1",
    [requestId],
  );
  return rows[0];
};

// handover code is only selected here (single loan); the service decides who may see it
const findById = async (id) => {
  const { rows } = await pool.query(
    `SELECT ${LOAN_SELECT}, l.handover_code ${LOAN_FROM} WHERE l.id = $1`,
    [id]
  );
  return rows[0];
};
// Copies item, poeple and dates Straight from the apporved request in ONE statement.
// The Where re-checks status = 'approved', so it cant be bypassed by a race.

const createFromRequest = async (requestId, code) => {
  const { rows } = await pool.query(
    `INSERT INTO loans (request_id, item_id, borrower_id, owner_id, start_date, end_date, handover_code)
        SELECT br.id , br.item_id, br.requester_id, i.owner_id, br.start_date, br.end_date , $2
        FROM borrow_requests br
        JOIN items i on i.id = br.item_id
        WHERE br.id = $1 AND br.status = 'approved'
        RETURNING id`,
    [requestId, code],
  );
  return rows[0] ? findById(rows[0].id) : undefined;
};

// Is this item currently out with someone (handed over , not returned)?
const itemIsOnLoan = async (itemId) => {
  const { rows } = await pool.query(
    `SELECT 1 FROM loans
        WHERE item_id = $1 AND handed_over_at IS NOT NULL AND returned_at IS NULL
        LIMIT 1`,
    [itemId],
  );
  return rows.length > 0;
};

// Shared list query: whereSql decides the perspective (borrower or owner)
const findList = async (
  whereSql,
  values,
  { status, limit = 10, offset = 0 } = {},
) => {
  const params = [...values];
  let where = whereSql;

  if (status) {
    params.push(status);
    where += `AND l.status = $${params.length}`;
  }
  const count = await pool.query(
    `SELECT COUNT(*)::int AS total ${LOAN_FROM} WHERE ${where}`,
    params,
  );
  const { rows } = await pool.query(
    `SELECT ${LOAN_SELECT} ${LOAN_FROM}
        WHERE ${where}
        ORDER BY l.created_at DESC
        LIMIT $${params.length + 1} OFFSET $${params.length + 2}`,
    [...params, limit, offset],
  );
  return { loans: rows, total: count.rows[0].total };
};

const findByBorrower = (userId, opts) =>
  findList("l.borrower_id = $1", [userId], opts);
const findByOwner = (userId, opts) =>
  findList("l.owner_id = $1", [userId], opts);

// Handover: loans gets a timestamp AND the item becomes unavailable together.
// The Where makes it atomic: it only matches if the handover hasn't happened yet.
const markHandedOver = (loanId) =>
  withTransaction(async (client) => {
    const { rows } = await client.query(
      `UPDATE loans SET handed_over_at = NOW()
       WHERE id = $1 AND status = 'active' AND handed_over_at IS NULL
       RETURNING item_id`,
      [loanId]
    );
    if (!rows[0]) return false;

    await client.query("UPDATE items SET is_available = FALSE WHERE id = $1", [rows[0].item_id]);
    return true;
  });

// Return : Loan is closed AND the item becomes available again, together
const markReturned = (loanId) =>
  withTransaction(async (client) => {
    const { rows } = await client.query(
      `UPDATE loans SET status = 'returned', returned_at = NOW()
       WHERE id = $1 AND handed_over_at IS NOT NULL AND returned_at IS NULL
       RETURNING item_id`,
      [loanId]
    );
    if (!rows[0]) return false;

    await client.query("UPDATE items SET is_available = TRUE WHERE id = $1", [rows[0].item_id]);
    return true;
  });

module.exports = {
    markOverdue,
    findRequest,
    findByRequestId,
    findById,
    createFromRequest,
    itemIsOnLoan,
    findByBorrower,
    findByOwner,
    markHandedOver,
    markReturned
}
