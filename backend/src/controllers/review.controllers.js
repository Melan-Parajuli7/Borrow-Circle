const ReviewService = require('../services/review.services');

const asyncHandler = (fn) => (req , res , next) => 
    Promise.resolve(fn(req, res , next)).catch(next);

exports.createReview = asyncHandler(async (req, res) => {
    const review = await ReviewService.createReview(req.user, req.body);
    res.status(201).json({success: true , review});
});

exports.getReceived = asyncHandler(async (req, res) => {
    const result = await ReviewService.getReceived(req.user, req.query);
    res.json({success: true , result});
});

exports.getGiven = asyncHandler(async (req, res) => {
    const result = await ReviewService.getGiven(req.user, req.query);
    res.json({success: true , result});
});

exports.getUserReviews = asyncHandler(async (req, res) => {
    const result = await ReviewService.getUserReviews(req.params.id, req.query);
    res.json({success: true , result});
});

exports.getLoanReviews = asyncHandler(async (req, res) => {
    const reviews = await ReviewService.getLoanReviews(req.params.loanId, req.user);
    res.json({success: true , reviews});
});