const ItemService = require("../services/item.services");
const { deleteOldFile, getFileUrl } = require("../config/multer.config");

const asyncHandler = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);

// Builds the stored URL from the uploaded file
const imageUrlFrom = (file) => (file ? getFileUrl(file.filename, "itemImage") : null);

// Removes an uploaded file if the request fails afterwards
const rollbackUpload = async (file) => {
  if (file) await deleteOldFile(file.filename, "itemImage");
};

exports.createItem = asyncHandler(async (req, res) => {
  try {
    const item = await ItemService.createItem(req.user, req.body, imageUrlFrom(req.file));
    res.status(201).json({ success: true, item });
  } catch (err) {
    await rollbackUpload(req.file);
    throw err;
  }
});

exports.getItems = asyncHandler(async (req, res) => {
  const result = await ItemService.getItems(req.query);
  res.json({ success: true, ...result });
});

exports.getMyItems = asyncHandler(async (req, res) => {
  const result = await ItemService.getItems(req.query, { ownerId: req.user.id });
  res.json({ success: true, ...result });
});

exports.getItem = asyncHandler(async (req, res) => {
  const item = await ItemService.getItem(req.params.id);
  res.json({ success: true, item });
});

exports.updateItem = asyncHandler(async (req, res) => {
  try {
    const { item, oldImage } = await ItemService.updateItem(
      req.params.id, req.user, req.body, imageUrlFrom(req.file)
    );
    if (oldImage) await deleteOldFile(ItemService.filenameFromUrl(oldImage), "itemImage");
    res.json({ success: true, item });
  } catch (err) {
    await rollbackUpload(req.file);
    throw err;
  }
});

exports.deleteItem = asyncHandler(async (req, res) => {
  const image = await ItemService.deleteItem(req.params.id, req.user);
  if (image) await deleteOldFile(ItemService.filenameFromUrl(image), "itemImage");
  res.json({ success: true, message: "Item deleted" });
});