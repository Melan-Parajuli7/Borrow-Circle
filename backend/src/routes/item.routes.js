const router = require("express").Router();
const ctrl = require("../controllers/item.controllers");
const { protect } = require("../middlewares/auth.middleware");
const { itemImageUpload } = require("../config/multer.config");

// every item route requires a logged-in user
router.use(protect);

router.get("/", ctrl.getItems);
router.get("/my", ctrl.getMyItems);   // must be BEFORE "/:id", or "my" is read as an id
router.get("/:id", ctrl.getItem);

router.post("/", itemImageUpload.single("image"), ctrl.createItem);
router.put("/:id", itemImageUpload.single("image"), ctrl.updateItem);
router.delete("/:id", ctrl.deleteItem);

module.exports = router;