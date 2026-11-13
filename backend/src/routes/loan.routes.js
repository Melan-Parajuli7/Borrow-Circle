const router = require("express").Router();
const ctrl = require("../controllers/loan.controllers");
const { protect } = require("../middlewares/auth.middleware");

router.use(protect);

router.post("/", ctrl.createLoan);

// "/borrowing" and "/lending" must come BEFORE "/:id", or they'd be read as ids
router.get("/borrowing", ctrl.getBorrowing);
router.get("/lending", ctrl.getLending);
router.get("/:id", ctrl.getLoan);

router.patch("/:id/handover", ctrl.handoverLoan);
router.patch("/:id/return", ctrl.returnLoan);

module.exports = router;