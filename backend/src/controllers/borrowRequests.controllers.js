const RequestService = require("../services/borrowRequest.services");

const asyncHandler = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);

exports.createRequest = asyncHandler(async (req, res) => {
  const request = await RequestService.createRequest(req.user, req.body);
  res.status(201).json({
    success: true,
    request,
  });
});

exports.getMyRequests = asyncHandler(async (req, res) => {
  const request = await RequestService.getMyRequest(req.user, req.query);
  res.json({ success: true, ...result });
});

exports.getIncomingRequests = asyncHandler(async (req, res) => {
  const result = await RequestService.getIncomingRequests(req.user, req.query);
  res.json({ success: true, ...result });
});

exports.getRequest = asyncHandler(async (req, res) => {
  const request = await RequestService.getRequest(req.params.id, req.user);
  res.json({ success: true, request });
});

exports.approveRequest = asyncHandler(async (req, res) => {
  const request = await RequestService.approveRequest(req.params.id, req.user);
  res.json({ success: true, request });
});

exports.rejectRequest = asyncHandler(async (req, res) => {
  const request = await RequestService.rejectRequest(req.params.id, req.user);
  res.json({ success: true, request });
});

exports.cancelRequest = asyncHandler(async (req, res) => {
  const request = await RequestService.cancelRequest(req.params.id, req.user);
  res.json({ success: true, request });
});
