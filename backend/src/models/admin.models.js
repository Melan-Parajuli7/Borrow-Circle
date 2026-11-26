const { pool } = require("../config/db.config");

// One round trip for the whole dashboard: every counter is a scalar subquery.
// `active_loans` matches the apps' notion of "out right now" (handed over,
// not returned); `support_unread` is the admin's badge across support chats.
const getStats = async () => {
  const { rows } = await pool.query(
    `SELECT
        (SELECT COUNT(*)::int FROM users WHERE role = 'user')      AS total_users,
        (SELECT COUNT(*)::int FROM users WHERE role = 'admin')     AS total_admins,
        (SELECT COUNT(*)::int FROM items)                         AS total_items,
        (SELECT COUNT(*)::int FROM items WHERE is_available)      AS available_items,
        (SELECT COUNT(*)::int FROM borrow_requests)               AS total_requests,
        (SELECT COUNT(*)::int FROM borrow_requests
          WHERE status = 'pending')                               AS pending_requests,
        (SELECT COUNT(*)::int FROM loans)                         AS total_loans,
        (SELECT COUNT(*)::int FROM loans
          WHERE status IN ('active', 'overdue'))                  AS active_loans,
        (SELECT COUNT(*)::int FROM loans
          WHERE returned_at IS NOT NULL)                          AS returned_loans,
        (SELECT COUNT(*)::int FROM reviews)                       AS total_reviews,
        (SELECT COUNT(*)::int FROM messages)                      AS total_messages,
        (SELECT COUNT(*)::int FROM conversations c
           JOIN users p1 ON p1.id = c.participant1_id
           JOIN users p2 ON p2.id = c.participant2_id
          WHERE p1.role = 'admin' OR p2.role = 'admin')           AS support_chats,
        (SELECT COUNT(*)::int FROM messages m
           JOIN conversations c ON c.id = m.conversation_id
           JOIN users p1 ON p1.id = c.participant1_id
           JOIN users p2 ON p2.id = c.participant2_id
          WHERE m.is_read = FALSE
            AND (p1.role = 'admin' OR p2.role = 'admin'))         AS support_unread`,
  );
  return rows[0];
};

// Deleting a user cascades to their loans (and the reviews on those loans),
// so loan history is a hard stop for the delete action.
const userHasLoans = async (userId) => {
  const { rows } = await pool.query(
    `SELECT 1 FROM loans
      WHERE borrower_id = $1 OR owner_id = $1
      LIMIT 1`,
    [userId],
  );
  return rows.length > 0;
};

// Deleting an item cascades to its borrow requests and loans (with their
// reviews), so any loan on the item -- past or active -- blocks the delete.
const itemHasLoans = async (itemId) => {
  const { rows } = await pool.query(
    `SELECT 1 FROM loans WHERE item_id = $1 LIMIT 1`,
    [itemId],
  );
  return rows.length > 0;
};

module.exports = {
  getStats,
  userHasLoans,
  itemHasLoans,
};