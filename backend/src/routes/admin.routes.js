const router = require("express").Router();
const ctrl = require("../controllers/admin.controllers");
const { protect, restrictTo } = require("../middlewares/auth.middleware");

// Every admin route needs a logged-in ADMIN
router.use(protect, restrictTo("admin"));

// Dashboard
router.get("/dashboard/stats", ctrl.getDashboardStats);

// Users management
router.get("/users", ctrl.getUsers);
router.get("/users/:id", ctrl.getUser);
router.patch("/users/:id/role", ctrl.updateUserRole);
router.delete("/users/:id", ctrl.deleteUser);

// Items management
router.get("/items", ctrl.getItems);
router.delete("/items/:id", ctrl.deleteItem);

// Borrow requests
router.get("/requests", ctrl.getRequests);
router.patch("/requests/:id/approve", ctrl.approveRequest);
router.patch("/requests/:id/reject", ctrl.rejectRequest);

// Loans (read-only for admins)
router.get("/loans", ctrl.getLoans);

// Reviews management
router.get("/reviews", ctrl.getReviews);
router.get("/reviews/:id", ctrl.getReview);
router.delete("/reviews/:id", ctrl.deleteReview);

// Admin support chats (conversations an admin takes part in)
router.get("/support-chats", ctrl.getSupportChats);
router.get("/support-chats/:id/messages", ctrl.getSupportChatMessages);

module.exports = router;