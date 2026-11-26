const { pool } = require("../config/db.config");

// Participants are always stored in ascending id order (smaller id = participant1).
// The service normalises the pair, so the same two users always map to the same
// row and the partial unique indexes in the migration can never be bypassed
// by swapping the order.
const normalizePair = (a, b) => (a < b ? [a, b] : [b, a]);

// Row shape returned for a conversation, from the point of view of the user
// asking ($1): the "other" side of the chat is exposed as participant_*.
const CONVERSATION_SELECT = `
    c.id, c.loan_id, c.item_id, c.created_at, c.updated_at,
    CASE WHEN c.participant1_id = $1 THEN c.participant2_id
         ELSE c.participant1_id END AS participant_id,
    peer.full_name AS participant_name,
    peer.avatar AS participant_avatar,
    COALESCE(i.id, li.id) AS item_id,
    COALESCE(i.title, li.title) AS item_title,
    last_msg.text AS last_message,
    last_msg.created_at AS last_message_at,
    (
        SELECT COUNT(*)::int FROM messages m
        WHERE m.conversation_id = c.id
          AND m.sender_id <> $1
          AND m.is_read = FALSE
    ) AS unread_count
`;

const CONVERSATION_FROM = `
    FROM conversations c
    JOIN users p1 ON p1.id = c.participant1_id
    JOIN users p2 ON p2.id = c.participant2_id
    JOIN users peer ON peer.id =
        CASE WHEN c.participant1_id = $1 THEN c.participant2_id ELSE c.participant1_id END
    LEFT JOIN loans l ON l.id = c.loan_id
    LEFT JOIN items i ON i.id = c.item_id
    LEFT JOIN items li ON li.id = l.item_id
    LEFT JOIN LATERAL (
        SELECT m.text, m.created_at
        FROM messages m
        WHERE m.conversation_id = c.id
        ORDER BY m.created_at DESC, m.id DESC
        LIMIT 1
    ) last_msg ON TRUE
`;

const MESSAGE_SELECT = `
    m.id, m.conversation_id, m.sender_id, m.text, m.is_read, m.created_at,
    u.full_name AS sender_name, u.avatar AS sender_avatar
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

// ---- conversations ----

// One conversation for a pair inside a scope (loan / item / admin).
// Returns undefined when the pair has never talked in that scope.
const findExisting = async (userId1, userId2, loanId, itemId) => {
  const [p1, p2] = normalizePair(userId1, userId2);
  const { rows } = await pool.query(
    `SELECT id, loan_id, item_id, participant1_id, participant2_id,
            created_at, updated_at
       FROM conversations
      WHERE participant1_id = $1 AND participant2_id = $2
        AND loan_id IS NOT DISTINCT FROM $3
        AND item_id IS NOT DISTINCT FROM $4`,
    [p1, p2, loanId ?? null, itemId ?? null],
  );
  return rows[0];
};

const createConversation = async ({ loanId, itemId, userId1, userId2 }) => {
  const [p1, p2] = normalizePair(userId1, userId2);
  const { rows } = await pool.query(
    `INSERT INTO conversations (loan_id, item_id, participant1_id, participant2_id)
     VALUES ($1, $2, $3, $4)
     RETURNING id, loan_id, item_id, participant1_id, participant2_id,
               created_at, updated_at`,
    [loanId ?? null, itemId ?? null, p1, p2],
  );
  return rows[0];
};

// Reuse the pair's conversation in a scope, creating it on first contact.
// The 23505 re-read keeps a race (both sides starting at once) from
// ever producing two rows.
const getOrCreateConversation = async ({ loanId, itemId, userId1, userId2 }) => {
  const existing = await findExisting(userId1, userId2, loanId, itemId);
  if (existing) return existing;
  try {
    return await createConversation({ loanId, itemId, userId1, userId2 });
  } catch (err) {
    if (err.code === "23505") {
      return findExisting(userId1, userId2, loanId, itemId);
    }
    throw err;
  }
};

// Scoped lookups used by the service when a loan/item is given
const findByLoanAndParticipants = (loanId, userId1, userId2) =>
  findExisting(userId1, userId2, loanId, null);

const findByItemAndParticipants = (itemId, userId1, userId2) =>
  findExisting(userId1, userId2, null, itemId);

const findAdminConversation = (userId1, userId2) =>
  findExisting(userId1, userId2, null, null);

// Plain row by id (authorisation is decided in the service)
const findById = async (id) => {
  const { rows } = await pool.query(
    `SELECT id, loan_id, item_id, participant1_id, participant2_id,
            created_at, updated_at
       FROM conversations WHERE id = $1`,
    [id],
  );
  return rows[0];
};

// Full viewer-aware row (participant_*, item title, last message, unread
// count) for one conversation, as returned by the conversations list
const findByIdForViewer = async (id, userId) => {
  const { rows } = await pool.query(
    `SELECT ${CONVERSATION_SELECT} ${CONVERSATION_FROM} WHERE c.id = $2`,
    [userId, id],
  );
  return rows[0];
};

// Every conversation the user takes part in, most recent activity first
const findUserConversations = async (userId, { limit = 20, offset = 0 } = {}) => {
  const count = await pool.query(
    `SELECT COUNT(*)::int AS total FROM conversations
      WHERE participant1_id = $1 OR participant2_id = $1`,
    [userId],
  );
  const { rows } = await pool.query(
    `SELECT ${CONVERSATION_SELECT} ${CONVERSATION_FROM}
      WHERE c.participant1_id = $1 OR c.participant2_id = $1
      ORDER BY COALESCE(last_msg.created_at, c.updated_at) DESC, c.id DESC
      LIMIT $2 OFFSET $3`,
    [userId, limit, offset],
  );
  return { conversations: rows, total: count.rows[0].total };
};

// ---- admin support chats ----

// Every conversation where at least one participant is an admin, i.e. the
// "Help / Contact admin" threads (never private user-to-user chats).
// The NON-admin side is surfaced as participant_* because the viewer is the
// admin, and its unread messages become the admin's badge.
const findAdminSupportChats = async ({ limit = 20, offset = 0 } = {}) => {
  const count = await pool.query(
    `SELECT COUNT(*)::int AS total
       FROM conversations c
       JOIN users p1 ON p1.id = c.participant1_id
       JOIN users p2 ON p2.id = c.participant2_id
      WHERE p1.role = 'admin' OR p2.role = 'admin'`,
  );
  const { rows } = await pool.query(
    `SELECT c.id, c.loan_id, c.item_id, c.created_at, c.updated_at,
            nu.id AS participant_id,
            nu.full_name AS participant_name,
            nu.avatar AS participant_avatar,
            last_msg.text AS last_message,
            last_msg.created_at AS last_message_at,
            (
                SELECT COUNT(*)::int FROM messages m
                WHERE m.conversation_id = c.id
                  AND m.sender_id = nu.id
                  AND m.is_read = FALSE
            ) AS unread_count
       FROM conversations c
       JOIN users p1 ON p1.id = c.participant1_id
       JOIN users p2 ON p2.id = c.participant2_id
       JOIN users nu ON nu.id =
            CASE WHEN p1.role = 'admin' THEN c.participant2_id ELSE c.participant1_id END
       LEFT JOIN LATERAL (
            SELECT m.text, m.created_at
            FROM messages m
            WHERE m.conversation_id = c.id
            ORDER BY m.created_at DESC, m.id DESC
            LIMIT 1
       ) last_msg ON TRUE
      WHERE p1.role = 'admin' OR p2.role = 'admin'
      ORDER BY COALESCE(last_msg.created_at, c.updated_at) DESC, c.id DESC
      LIMIT $1 OFFSET $2`,
    [limit, offset],
  );
  return { conversations: rows, total: count.rows[0].total };
};

// True when the conversation is a support thread (an admin takes part in it)
const isSupportConversation = async (id) => {
  const { rows } = await pool.query(
    `SELECT 1
       FROM conversations c
       JOIN users p1 ON p1.id = c.participant1_id
       JOIN users p2 ON p2.id = c.participant2_id
      WHERE c.id = $1 AND (p1.role = 'admin' OR p2.role = 'admin')`,
    [id],
  );
  return rows.length > 0;
};

// ---- messages ----

const getMessages = async (conversationId, { limit = 50, offset = 0 } = {}) => {
  const count = await pool.query(
    `SELECT COUNT(*)::int AS total FROM messages WHERE conversation_id = $1`,
    [conversationId],
  );
  const { rows } = await pool.query(
    `SELECT ${MESSAGE_SELECT}
       FROM messages m
       JOIN users u ON u.id = m.sender_id
      WHERE m.conversation_id = $1
      ORDER BY m.created_at ASC, m.id ASC
      LIMIT $2 OFFSET $3`,
    [conversationId, limit, offset],
  );
  return { messages: rows, total: count.rows[0].total };
};

// Insert + re-select so the sender's name comes back with the message
const createMessage = async (conversationId, senderId, text) =>
  withTransaction(async (client) => {
    const { rows } = await client.query(
      `INSERT INTO messages (conversation_id, sender_id, text)
       VALUES ($1, $2, $3) RETURNING id`,
      [conversationId, senderId, text],
    );

    // Keep the thread's "last activity" fresh (fires the updated_at trigger)
    await client.query(
      `UPDATE conversations SET updated_at = NOW() WHERE id = $1`,
      [conversationId],
    );

    const { rows: full } = await client.query(
      `SELECT ${MESSAGE_SELECT}
         FROM messages m
         JOIN users u ON u.id = m.sender_id
        WHERE m.id = $1`,
      [rows[0].id],
    );
    return full[0];
  });

// Only the other side's unread messages flip to read
const markAsRead = async (conversationId, userId) => {
  const { rowCount } = await pool.query(
    `UPDATE messages SET is_read = TRUE
      WHERE conversation_id = $1 AND sender_id <> $2 AND is_read = FALSE`,
    [conversationId, userId],
  );
  return rowCount;
};

// Total unread messages across every conversation of the user (badge count)
const getUnreadCount = async (userId) => {
  const { rows } = await pool.query(
    `SELECT COUNT(*)::int AS total
       FROM messages m
       JOIN conversations c ON c.id = m.conversation_id
      WHERE (c.participant1_id = $1 OR c.participant2_id = $1)
        AND m.sender_id <> $1
        AND m.is_read = FALSE`,
    [userId],
  );
  return rows[0].total;
};

module.exports = {
  findExisting,
  findByLoanAndParticipants,
  findByItemAndParticipants,
  findAdminConversation,
  findById,
  findByIdForViewer,
  createConversation,
  getOrCreateConversation,
  findUserConversations,
  findAdminSupportChats,
  isSupportConversation,
  getMessages,
  createMessage,
  markAsRead,
  getUnreadCount,
};