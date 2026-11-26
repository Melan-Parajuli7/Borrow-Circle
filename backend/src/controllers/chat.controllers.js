const ChatService = require('../services/chat.services');

const asyncHandler = (fn) => (req , res ,next ) => 
    Promise.resolve(fn(req , res, next)).catch(next);

// POST /api/chats -- start/get any conversation (loan, item or admin scope)
exports.startConversation = asyncHandler(async (req , res) => {
    const conversation = await ChatService.startConversation(req.user, req.body);
    res.status(201).json({success : true , conversation})
});

// GET /api/chats/my -- the signed-in user's conversation list
exports.getConversations = asyncHandler(async (req , res) => {
    const result = await ChatService.getConversations(req.user, req.query);
    res.json({success : true , ...result})
});

// POST /api/chats/admin -- "Help / Contact admin" support thread
exports.startAdminConversation = asyncHandler(async (req , res) => {
    const conversation = await ChatService.startAdminConversation(req.user);
    res.status(201).json({success : true , conversation})
});

// POST /api/chats/loan/:loanId -- lender <-> borrower coordination chat
exports.startLoanConversation = asyncHandler(async (req , res) => {
    const conversation = await ChatService.startLoanConversation(req.user, req.params.loanId);
    res.status(201).json({success : true , conversation})
});

// GET /api/chats/:id/messages -- paginated message history
exports.getMessages = asyncHandler(async (req , res) => {
    const result = await ChatService.getMessages(req.user, req.params.id, req.query);
    res.json({success : true , ...result})
});

// POST /api/chats/:id/messages -- send a message
exports.sendMessage = asyncHandler(async (req , res) => {
    const message = await ChatService.sendMessage(req.user, req.params.id, req.body.text);
    res.status(201).json({success : true , message})
});

// PATCH /api/chats/:id/read -- mark the other side's messages as read
exports.markRead = asyncHandler(async (req , res) => {
    await ChatService.markRead(req.user, req.params.id);
    res.json({success : true})
});