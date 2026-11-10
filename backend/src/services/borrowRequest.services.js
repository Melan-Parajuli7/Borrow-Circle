const BorrowRequest = require('../models/borrowRequests.model');
const AppError = require('../utils/appError');

const STATUSES = ["pending", "approved", "rejected", "cancelled"];
const MAX_DAYS = 30; // longest allowed loan

// ---- helpers ---- //

const parseId = (value, label = "id") => {
  const n = Number(value);
  if (!Number.isInteger(n) || n <= 0) throw new AppError(`Invalid ${label}`, 400);
  return n;
};

// Must be a real calender date in YYYY-MM-DD form
const isValidDate = (s) => {
  if (typeof s !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(s)) return false;
  const d = new Date(`${s}T00:00:00Z`);
  return !Number.isNaN(d.getTime()) && d.toISOString().slice(0, 10) === s; // rejects 2026-02-31
};

// Today as YYYY-MM-DD in the server's LOCAL time (toISOString would use UTC)
const todayString = () => Date().toLocaleDateString('en-CA');

const daysBetween = (a, b) =>
  (Date.UTC(...b.split("-").map((n, i) => (i === 1 ? n - 1 : +n))) -
    Date.UTC(...a.split("-").map((n, i) => (i === 1 ? n - 1 : +n)))) /
  86400000;

const validateDates = (start, end) => {
    if(!isValidDate(start) || !isValidDate(end))
        throw new AppError("Datee must be valid and in YYYY-MM-DD format", 400);
    if(start < todayString()) // YYYY-MM-DD strings compare correctly as text
        throw new AppError("Start Date cannot be in Past", 400);
    if(end < start)
        throw new AppError("End date cannot be before start date", 400);
    if(daysBetween(start, end) +1 > MAX_DAYS)
        throw new AppError(`You can borrow an items for at most ${MAX_DAYS} days`, 400);
};

const pageParams = (query) => {
    const page = Math.max(parseInt(query.page) || 1,1);
    const limit = Math.min(Math.max(parseInt(query.limit) || 10, 1), 50);
    const status = query.status ? String(query.status).toLowerCase() : undefined;
    if(status && !STATUSES.includes(status))
        throw new AppError(`Status mus be one of ${STATUSES.join(", ")}, 400`);
    return { page , limit , status , offset: (page - 1) * limit};
};

const paginated = ({requests, total}, {page , limit}) => ({
    requests , page , limit , total , totalPages: Math.ceil(total / limit),
});


/// ------- create requests -----
const createRequest = async (user , body = {}) => {
    const itemId = parseId(body.item_id, "item id");
    const start = String(body.start_date || "").trim();
    const end = String(body.end_date || "").trim();
    const message = body.message ? String(body.message).trim() : null;

    validateDates(start, end);
    if(message && message.length > 500)
        throw new AppError("Message can be at most 500 characters", 400);

    const item = await BorrowRequest.findItem(itemId);
    if (!item) throw new AppError("Item not found", 404);

    // Rule 1 : you can't borrow your own item
    if(item.owner_id === user.id)
        throw new AppError("You cannot request your own item", 400);

    // Rule 2 : the owner must have the item marked available
    if(!item.is_available)
        throw new AppError("This item is not available right now", 409);

    // Rule 3: no second pending request for the same item
    if(await BorrowRequest.hasPendingDuplicate(itemId, user.id))
        throw new AppError("You already have a pending request for this item", 409);

    // Rule 4: those dates must not overlap an already approved request
    if(await BorrowRequest.hasApprovedOverlap(itemId, start, end))
        throw new AppError("The item is already booked for those dates", 409);

    return BorrowRequest.create({
        item_id : itemId,
        requester_id : user.id, // Access Token , never from the body
        start_date : start,
        end_date : end,
        message,
    });
};

// ----- reads -----

const getMyRequest = async (user , query) => {
    const p = pageParams(query);
    return paginated(await BorrowRequest.findByRequester(user.id, p), p);
};

const getIncomingRequests = async (user , query) => {
    const p = pageParams(query);
    return paginated(await BorrowRequest.findByOwner(user.id, p), p);
};

// Only the requester or the team's owner can see a request
const getRequest = async (id , user) => {
    const request = await BorrowRequest.findById(parseId(id, "request id"));
    if(!request) throw new AppError("Request not found", 404);

    const involved = request.requester_id === user.id || request.owner_id === user.id;
    if (!involved && user.role !== "admin")
        throw new AppError("You are not allowed to view this request", 403);
    return request;
};

// ---- status changes ----

// Loads the request (404 if missing) without the "involved" check, because
// each action below applies its own, sticker check

const load = async (id) => {
    const request = await BorrowRequest.findById(parseId(id , "request id"));
    if(!request) throw new AppError("Request not found", 404);
    return request;
};

const mustBePending = (request) => {
    if(request.status !== "pending")
        throw new AppError(`This request is already ${request.status}`, 409);
}

const approveRequest = async (id , user) => {
    const request = await load(id);

    // Only the item's OWNER can approve
    if(request.owner_id !== user.id)
        throw new AppError("Only the item owner can approve this request", 403);
    mustBePending(request);

    const item = await BorrowRequest.findItem(request.item_id);
    if(!item || !item.is_available)
        throw new AppError("This item is no longer available", 409);

    // Another Request may have been approved for this dates in the meantime
    if(await BorrowRequest.hasApprovedOverlap(
        request.item_id, request.start_date, request.end_date, request.id))
        throw new AppError("Another approved request already covers these dates", 409);

        const updated = await BorrowRequest.updateStatus(request.id , "pending", "approved");
        if(!updated) throw new AppError("This request was just changed, please refresh", 409);
        return updated;
    };

    const rejectRequest = async (id , user) => {
        const request = await load(id);

        if(request.owner_id !== user.id)
            throw new AppError("Only the item owner can reject this reqest", 403);
        mustBePending(request);

        const updated = await BorrowRequest.updateStatus(request.id, "pending", "rejected");
        if(!updated) throw new AppError("This request was just changed, please refresh", 409);
        return updated;
    };


    const cancelRequest = async (id , user) => {
        const request = await load(id);

        // Only the person who SENT it can cancel
        if(request.requester_id !== user.id)
            throw new AppError("Only the requester can cancel this request", 403);

        const updated = await BorrowRequest.updateStatus(request.id, "pending", "cancelled");
        if(!updated) throw new AppError("This request was just changed, please refresh", 409);
        return updated;
    };

    module.exports = {
        createRequest,
        getMyRequest,
        getIncomingRequests,
        getRequest,
        approveRequest,
        rejectRequest,
        cancelRequest
    }