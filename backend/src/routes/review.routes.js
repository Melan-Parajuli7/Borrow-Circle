const router = require("express").Router();
const ctrl = require('../controllers/review.controllers');
const {protect} = require("../middlewares/auth.middleware");

router.use(protect);

router.post("/", ctrl.createReview);
router.get("/received", ctrl.getReceived);
router.get("/given", ctrl.getGiven);
router.get("/user/:id", ctrl.getUserReviews);
router.get("/loan/:loanId", ctrl.getLoanReviews);

module.exports = router;    