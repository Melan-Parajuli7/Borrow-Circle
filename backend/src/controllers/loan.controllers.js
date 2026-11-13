const LoanService = require('../services/loan.services');

const asyncHandler = (fn) => (req , res ,next ) => 
    Promise.resolve(fn(req , res, next)).catch(next);

exports.createLoan = asyncHandler(async (req , res) => {
    const loan = await LoanService.createLoan(req.user, req.body);
    res.status(201).json({success : true , loan})
});

exports.getBorrowing = asyncHandler(async (req , res) => {
    const result = await LoanService.getBorrowing(req.user, req.query);
    res.json({success : true , ...result})
});

exports.getLending = asyncHandler(async (req , res) => {
    const result = await LoanService.getLending(req.user, req.query);
    res.json({success : true , ...result})
});

exports.getLoan = asyncHandler(async (req , res) => {
    const loan = await LoanService.getLoan(req.params.id, req.user);
    res.json({success : true , loan})
});

exports.handoverLoan = asyncHandler(async (req , res) => {
    const loan = await LoanService.handoverLoan(req.params.id, req.user, req.body);
    res.json({success : true , loan})
});

exports.returnLoan = asyncHandler(async (req , res) => {
    const loan = await LoanService.returnLoan(req.params.id, req.user);
    res.json({success : true , loan})
});