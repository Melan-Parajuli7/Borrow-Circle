const { where } = require('sequelize');
const {pool} = require('../config/db.config');

// to-char returns date as "2026-11-20" to strings.
// objects that can shift by a day because of timezones.
// The JOINs bring in the item, the requester and the item's owner.

const REQUEST_SELECT = `
                        br.id , br.item_id, br.requester.id, 
                        to_char(br.start_date, 'YYYY-MM-DD') AS start_date,
                        to_char(br.end_date, 'YYYY-MM-DD') AS end_date,
                        br.status, br.message, br.created_at, br.updated_at,
                        i.title AS item_title, i.image_url AS item_image, 
                        i.owner_id, req.full_name AS requster_name , 
                        req.avatar AS requester_avatar, own.full_name AS owner_name
                        `; 

                        
const REQUEST_FROM = `
                    FROM borrow_requests br
                    JOIN items i ON i.id = br.item_id
                    JOIN users req ON req.id = br.requester.id
                    JOIN users own ON own.id = i.owner_id `;

// small item lookup so this module doesn't depends on the items model
const findItem = async (itemId) => {
    const {rows} = await pool.query(
        "SELECT id, title, owner_id , is_available FROM items WHERE id = $1",
        [itemId]
    );
    return rows[0];
};

const findById = async (id) => {
    const {rows} = await pool.query(
        `SELECT ${REQUEST_SELECT} ${REQUEST_FROM} WHERE br.id = $1`,
        [id]
    );
    return rows[0];
};

// create and insert in the tables
const create = async ({item_id , requester_id, start_date, end_date, message}) => {
    const {rows} = await pool.query(
            `INSERT INTO borrow_requests (item_id , requester_id, start_date, end_date, message)
            VALUES ($1 , $2, $3, $4, $5)
            RETURNING id`,
            [item_id, requester_id, start_date, end_date, message]    
    );
    return findById(rows[0].id); // re-read so the response includes the JOINed fields
};


// Same requester + same item + still pending = duplicate
const hasPendingDuplicate = async (itemId, requesterId) => {
    const {rows} = await pool.query(
        `SELECT 1 FROM borrow_requests
        WHERE item_id = $1 AND requester_id = $2 AND status = 'pending'
        LIMIT 1`,
        [itemId, requesterId]
    );
    return rows.length > 0;
};


// Do two date ranges overlaps? if A overlaps B when A.start <= B.end AND A.end >= B.start
// Only APPROVED requests blocks an item. excludeID lets approve() ignore itself.

const hasApprovedOverlap = async (itemID, start, end , excludeId = null) => {
    const {rows} = await pool.query(
        `SELECT 1 FROM borrow_requests WHERE item_id = $1
        AND status = 'approved' 
        AND start_date <= $3 AND end_date >= $2
        AND ($4::int IS NULL OR id <> $4)
        LIMIT 1`,
        [itemID, start, end , excludeId]
    );
    return rows.length > 0;
};


// Shared list query. whereSql decides the perspective (requester or owner)
const findList = async (whereSql , values , {status, limit , offset}) => {
    const params = [...values];
    let where = whereSql;

    if(status){
        params.push(status);
        where += `AND br.status = $${params.lenght}`;
    }
    const count = await pool.query(
        `SELECT COUNT(*):: int AS total ${REQUEST_FROM} WHERE ${where}`,
        params
    );
    const {rows} = await pool.query(
        `SELECT ${REQUEST_SELECT} ${REQUEST_FROM}
        WHERE ${where}
        ORDER BY br.created_at at DESC
        LIMIT $${params.length +1} OFFSET $${params.length + 2}`,
        [...params, limit, offset]
    );
    return {requests: rows , total: count.rows[0].total};
};

// Requests I sent
const findByRequester = (requesterId , opts) => 
    findList("br.requester_id = $1", [requesterId, opts]);

const findByOwner = (ownerId , opts) => 
    findList("i.owner_id = $1", [ownerId, opts]);

// Atomic status change: it only succeed if the row is STILL in 'fromStatus'.
//if two people click at the same time, only one UPDATE matches the WHERE.
const updateStatus = async (id , fromStatus, toStatus) => {
    const {rowCount} = await pool.query(
        `UPDATE borrow_requests SET staus = $1
        WHERE id = $2 AND status = $3`,
        [toStatus, id , fromStatus ]
    );
    return rowCount > 0 ? findById(id) : undefined // updated_at comes from the DB trigger
};

module.exports = {
    findItem,
    findById,
    create, 
    hasPendingDuplicate,
    hasApprovedOverlap,
    findByRequester,
    findByOwner,
    updateStatus
};