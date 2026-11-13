const Review = require('../models/review.models');
const AppError = require('../utils/appError');

const parseId = (value , label = "id") => {
    const n = Number(value);
    if(!Number.isInteger(n) || n <=0) throw new AppError(`Invalid ${label}`, 400);
    return n;
};

const pageParams = (query) => {
    const page = Math.max(parseInt(query.page) || 1,1);
    const limit = Math.min(Math.max(parseInt(query.limit) || 10 ,1),50);
    return {page , limit , offset: (page - 1) * limit};
};

const paginated = ({reviews, total}, {page , limit}) => ({
    reviews , page, limit, total, totalPages: Math.ceil(total/limit),
});

// ---- create ----
const createReview = async (user , body = {}) => {
    const loanId = parseId(body.loan_id, "loan id");

    const rating = Number(body.rating);
    if(body.rating === undefined || !Number.isInteger(rating) || rating < 1 || rating > 5)
        throw new AppError("Rating must be a whole number from 1 to 5", 400);
    
    const comment = body.comment ? String(body.comment).trim() : null;
    if(comment && comment.length >500)
        throw new AppError("Comment can be at most 500 characters", 400);

    const loan = await Review.findLoan(loanId);
    if(!loan) throw new AppError("Loan not found", 404);

    // Rule1: only the tow people in the loan can review it
    const isBorrower = loan.borrower_id === user.id;
    const isOwner = loan.owner_id === user.id;
    if(!isBorrower && !isOwner)
        throw new AppError("You can only review loans you were part of", 403);

    // Rule2: the loan must be finished
    if(!loan.returned_at)
        throw new AppError("You can review only after the item is returned", 409);

    // Rule3: You review the OTHER person (never taken from the request)
    const reviewee_id = isBorrower ? loan.owner_id : loan.borrower_id;

    try{
        return await Review.create({
            loan_id: loanId,
            reviewer_id : user.id,
            reviewee_id,
            rating,
            comment,
        });
    }catch(err){
        // UNIQUE (loan_id , reviewer_id): you already reviewed this loan
        if(err.code === '235005') throw new AppError("You already reviewed this loan", 409);
        throw err;
    }
};

// ---- reads ----

const getReceived = async (user, query) => {
    const p = pageParams(query);
    const [list , summary] = await Promise.all([
        Review.findReceived(user.id , p),
        Review.getSummary(user.id),
    ]);
    return {summary, ...paginated(list, p)};
};

const getGiven = async (user , query) => {
    const p = pageParams(query);
    return paginated(await Review.findGiven(user.id , p),p);
};

// Public profile view: any logged-in user can see another user's reviews

const getUserReviews = async (id, query) => {
    const userId = parseId(id , "user id");
    const target = await Review.findUser(userId);
    if(!target) throw new AppError("User not found", 404);

    const p = pageParams(query);
    const [list , summary] = await Promise.all([
        Review.findReceived(userId, p),
        Review.getSummary(userId),
    ]);
    return {
        user: {id: target.id , full_name : target.full_name , avatar: target.avatar},
        summary,
        ...paginated(list, p),
    };
};

const getLoanReviews = async (loanId, user) => {
    const id = parseId(loanId, "loan id");
    const loan = await Review.findLoan(id);
    if(!loan) throw new AppError("Loan not found", 404);

    const involved = loan.borrower_id === user.id || loan.owner_id === user.id;
    if(!involved && user.role !== "admin")
        throw new AppError("You are not allowed to view these rviews", 403);

    return Review.findByLoan(id);  
};

module.exports = {
    createReview,
    getReceived,
    getGiven,
    getUserReviews,
    getLoanReviews
}