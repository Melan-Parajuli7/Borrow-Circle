const crypto = require("crypto");
const Loan = require("../models/loan.models");
const AppError = require("../utils/appError");

const STATUESE = ["active", "returned", "overdue"];

// ---- helpers ----
const parseId = (value, label = "id") => {
  const n = Number(value);
  if (!Number.isInteger(n) || n <= 0)
    throw new AppError(`Invalid ${label}`, 400);
  return n;
};

// Generate the 6 digits code -> for this i am using crypto.randomInt is secure than Math.random is not
const generateCode = () =>
  String(crypto.randomInt(0, 1000000)).padStart(6, "0");

// the handover code is a sceret between app and borrower:
// the borrower sees it until handover, nobody else ever does ( not even the owner ).
const present = (loan, user) => {
  const { handover_code, ...rest } = loan;
  if (user.id === loan.borrower_id && loan.stage === "awaiting_handover") {
    rest.handover_code = handover_code;
  }
  return rest;
};

const pageParams = (query) => {
  const page = Math.max(parseInt(query.page) || 1, 1);
  const limit = Math.min(Math.max(parseInt(query.limit) || 10, 1), 50);
  const status = query.status ? String(query.status).toLowerCase() : undefined;
  if(status && !STATUESE.includes(status))
    throw new AppError(`Status must be one of: ${STATUESE.join(", ")}`, 400);
  return {page , limit, status, offset: (page -1)*limit};
};

const paginated = ({loans , total}, {page , limit}) => ({
    loans , page, limit , total , totalPages: Math.ceil(total / limit),
});

// Loads a loan (404 if missing). Refreshes overdue statuses first.
const load = async (id) => {
    await Loan.markHandOver();
    const loan = await Loan.findById(parseId(id , "loan id"));
    if(!loan) throw new AppError("Loan not found", 404);
    return loan;
};

const mustbeOwner = (loan, user, action) => {
    if(loan.owner_id !== user.id)
        throw new AppError(`Only the item owner can ${action}`, 403); 
};

// ----- create -----

const createLoan = async (user , body = {}) => {
    const requestId = parseId(body.request_id, "request id");

    const request = await Loan.findRequest(requestId);
    if(!request) throw new AppError("Request not found", 404);

    // Rule 1: only the item's onwer starts the loan
    if(request.owner_id !== user.id)
        throw new AppError("Only the item owner can start a loan", 403);

    // Rule 2: the request must be approved first
    if(request.status !== "approved")
        throw new AppError(`Only approved requests can become loans (this one is ${request.status})`, 409);

    // Rule 3: one loan per Request
    if(await Loan.findByRequestId(requestId))
        throw new AppError("A loan already exists for this request", 409);

    try{
        const loan = await Loan.createFromRequest(requestId, generateCode());
        if(!loan) throw new AppError("This request can no longer become a loan", 409);
        return present(loan , user); // owner doesnt get the code back
    }catch(err){
        if(err.code === "23505")
            throw new AppError("A loan already exists for this request", 409);
        throw err;
    }
};

// ---- reads ----

const getBorrowing = async (user , query) => {
    await Loan.markHandOver();
    const p = pageParams(query);
    return paginated(await Loan.findByBorrower(user.id , p), p);
};

const getLending = async (user , query) => {
    await Loan.markHandOver();
    const p = pageParams(query);
    return paginated(await Loan.findByOwner(user.id , p), p);
};

const getLoan = async (id , user) => {
    const loan = await load(id);
    const involved = loan.borrower_id === user.id || loan.owner_id === user.id;
    if(!involved && user.role !== "admin")
        throw new AppError("You are not allowed to view this loan", 403);
    return present(loan, user);
};

// ----- handover -----

const handoverLoan = async (id , user , body = {}) => {
    const loan = await load(id);

    mustbeOwner(loan , user , "confirm the handover");

    if(loan.stage !== "awaiting_handover")
        throw new AppError(`This loan is already ${loan.stage.replace("_", " ")}`, 409);

    // The code the borrower showed a the meetup
    const code = String(body.code || "").trim();
    if(!code || code !== loan.handover_code)
        throw new AppError("Incorrect handover code", 400);

    // Another loan for this item may still be out (e.g returned late)
    if( await Loan.itemIsOnLoan(loan.item_id))
        throw new AppError("This item is still out on anotther loan", 409);

    if(!(await Loan.markHandOver(loan.id)))
        throw new AppError("This loan was just changed, please refresh", 409);

    return present(await Loan.findById(loan.id), user);     
};

// ---- return ----

const returnLoan = async (id , user) => {
    const loan = await load(id);

    // The owner confirms they got the item back

    mustbeOwner(loan , user, "confirm the return");

    if(loan.stage !== "on_loan" && loan.stage !== "overdue")
        throw new AppError(
        loan.stage == "returned"
        ? "This loan is already returned"
        : "This item has't been handed over yet",
        409
    );

    if(!(await Loan.markReturned(loan.id)))
        throw new AppError("This loan was just changed, please refresh", 409);

    return present(await Loan.findById(loan.id), user);
};

module.exports = {
    createLoan,
    getBorrowing,
    getLending,
    getLoan,
    handoverLoan,
    returnLoan
}
