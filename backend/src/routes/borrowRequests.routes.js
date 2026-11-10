const router = require('express').Router();
const ctrl = require("../controllers/borrowRequests.controllers");
const {protect} = require("../middlewares/auth.middleware");

// every request routes needs a logged-in user
router.use(protect);

router.post("/", ctrl.createRequest);

// "/my" and "/incoming" must come BEFORE "/:id", or they'd be read as ids
router.get("/my", ctrl.getMyRequests);
router.get("/incoming", ctrl.getIncomingRequests);
router.get("/:id" , ctrl.getRequest);

router.patch("/:id/approve" , ctrl.approveRequest);
router.patch("/:id/reject", ctrl.rejectRequest);
router.patch("/:id/cancel", ctrl.cancelRequest);  // only the requester can cancel their request 


module.exports = router;