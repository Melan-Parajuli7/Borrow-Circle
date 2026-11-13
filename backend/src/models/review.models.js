const {pool} = require("../config/db.config");

const REVIEW_SELECT = `
    r.id, r.loan_id , r.reviewer_id, r.reviewee_id, r.rating, r.comment, r.created_at,
    rv.full_name AS reviewer_name , rv.avatar AS reviewer_avatar,
    re.full_name AS reviewee_name,
    i.tilte AS item_title
`;

const REVIEW_FORM = `
    FROM reviews r
    JOIN users rv ON rv.id = r.reviewer_id
    JOIN users re ON re.id = r.reviewee_id
    JOIN loans l ON l.id = r.loan_id
    JOIN items i ON i.id = l.item_id
`;

// finding the laon from the tables using this query
const findLoan = async (id) => {
    const {rows} = await pool.query(
    "SELECT id, borrower_id, owner_id , returned_at FROM loans WHERE id = $1",
        [id]
    );
    return rows[0];
};

const findUser = async (id) => {
  const { rows } = await pool.query(
    "SELECT id, full_name, avatar FROM users WHERE id = $1",
    [id]
  );
  return rows[0];
};

//find by id who has given the review
const findById = async (id) => {
    const {rows} = await pool.query(
        `SELECT ${REVIEW_SELECT} ${REVIEW_FORM} WHERE r.id = $1`,
        [id]
    );
    return rows[0];
};

// creating the review using this INSERT query
const create = async ({loan_id , reviewer_id , reviewee_id, rating , comment}) => {
    const {rows} = await pool.query(
        `INSERT INTO reviews (loan_id , reviewer_id , reviewee_id, rating , comment)
        VALUES ($1, $2, $3, $4, $5)
        RETURNING id`,
        [loan_id , reviewer_id, reviewee_id, rating, comment]
    );
    return findById(rows[0].id)
};

// Shared list query; whereSql decides the prespective
const findList = async (whereSql , values , {limit = 10, offset = 0} = {}) => {
    const count = await pool.query(
        `SELECT COUNT(*)::int AS total ${REVIEW_FORM} where ${whereSql}`,
        values
    );
    const {rows} = await pool.query(
        `SELECT ${REVIEW_SELECT} ${REVIEW_FORM}
        WHERE ${whereSql}
        ORDER BY r.created_at DESC
        LIMIT $${values.length + 1} OFFSET $${values.length + 2}`,
        [...values, limit, offset]
    );
    return {reviews : rows , total : count.rows[0].total};
};

const findReceived = (userId , opts) => findList("r.reviewee_id = $1", [userId], opts);
const findGiven = (userId , opts) => findList("r.reviewer_id = $1", [userId], opts);

const findByLoan = async (loanId) => {
    const {rows} = await pool.query(
        `SELECT ${REVIEW_SELECT} ${REVIEW_FORM} WHERE r.loan_id = $1 ORDER BY r.created_at`,
        [loanId]
    );
    return rows
};

// :: float because pg returns numeric (AVG) as a string
const getSummary = async (userId) => {
    const {rows} = await pool.query(
        `SELECT COUNT(*)::int AS total,
                COALESCE(ROUND(AVG(rating),2),0):: float AS average
        FROM reviews WHERE reviewee_id = $1`,
        [userId]
    );
    return rows[0];
};

module.exports = {
    findLoan,
    findUser,
    findById,
    create,
    findReceived,
    findGiven,
    findByLoan, 
    getSummary
}