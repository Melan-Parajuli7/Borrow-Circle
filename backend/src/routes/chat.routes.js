const router = require("express").Router();
const ctrl = require("../controllers/chat.controllers");
const { protect } = require("../middlewares/auth.middleware");

router.use(protect);

// Static paths come BEFORE "/:id/..." patterns, or "my", "admin" and
// "loan/12" would be read as conversation ids
router.post("/", ctrl.startConversation);
router.get("/my", ctrl.getConversations);
router.post("/admin", ctrl.startAdminConversation);
router.post("/loan/:loanId", ctrl.startLoanConversation);

router.get("/:id/messages", ctrl.getMessages);
router.post("/:id/messages", ctrl.sendMessage);
router.patch("/:id/read", ctrl.markRead);

module.exports = router;