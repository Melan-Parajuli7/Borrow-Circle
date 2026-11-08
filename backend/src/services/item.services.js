const path = require("path");
const Item = require("../models/items.model");
const AppError = require("../utils/appError");

const CONDITIONS = ["new", "like_new", "good", "fair", "poor"];

// multipart/form-data sends everything as strings, so "true" must become true
const toBool = (v) => {
  if (v === undefined || v === null || v === "") return undefined;
  return v === true || v === "true" || v === "1";
};

const clean = (v) =>
  v === undefined || v === null ? undefined : String(v).trim();

// Validates fields that were provided. Used by both create and update.
const validate = (d) => {
  if (d.title !== undefined && (!d.title || d.title.length > 150))
    throw new AppError("Title is required (max 150 characters)", 400);
  if (d.category && d.category.length > 50)
    throw new AppError("Category max 50 characters", 400);
  if (d.condition && !CONDITIONS.includes(d.condition))
    throw new AppError(
      `Condition must be one of: ${CONDITIONS.join(", ")}`,
      400,
    );
  if (d.group_name && d.group_name.length > 100)
    throw new AppError("Group name max 100 characters", 400);
};

// Only the owner or an admin may change or delete an item
const assertCanModify = (item, user) => {
  if (item.owner_id !== user.id && user.role !== "admin")
    throw new AppError("You can only modify your own items", 403);
};

const createItem = async (user, body, imageUrl) => {
  const data = {
    title: clean(body.title),
    description: clean(body.description) || null,
    category: clean(body.category) || null,
    condition: clean(body.condition) || "good",
    is_group_item: toBool(body.is_group_item) ?? false,
    group_name: clean(body.group_name) || null,
  };
  if (!data.title) throw new AppError("Title is required", 400);
  validate(data);

  if (data.is_group_item && !data.group_name)
    throw new AppError("Group name is required for group items", 400);
  if (!data.is_group_item) data.group_name = null;

  return Item.create({
    ...data,
    image_url: imageUrl || null,
    owner_id: user.id, // from the JWT, so users can't create items for others
  });
};

const getItems = async (query, { ownerId } = {}) => {
  const page = Math.max(parseInt(query.page) || 1, 1);
  const limit = Math.min(Math.max(parseInt(query.limit) || 10, 1), 50);

  const { items, total } = await Item.findAll({
    search: clean(query.search),
    category: clean(query.category),
    condition: clean(query.condition),
    available: toBool(query.available),
    ownerId,
    limit,
    offset: (page - 1) * limit,
  });

  return { items, page, limit, total, totalPages: Math.ceil(total / limit) };
};

const getItem = async (id) => {
  const item = await Item.findById(id);
  if (!item) throw new AppError("Item not found", 404);
  return item;
};

// Returns { item, oldImage } so the controller can delete the replaced file
const updateItem = async (id, user, body, newImageUrl) => {
  const existing = await getItem(id);
  assertCanModify(existing, user);

  const data = {
    title: clean(body.title),
    description: clean(body.description),
    category: clean(body.category),
    condition: clean(body.condition),
    is_group_item: toBool(body.is_group_item),
    group_name: clean(body.group_name),
    is_available: toBool(body.is_available),
  };
  validate(data);

  // Check the group rules against the final (merged) values
  const finalIsGroup = data.is_group_item ?? existing.is_group_item;
  const finalGroupName =
    data.group_name !== undefined ? data.group_name : existing.group_name;
  if (finalIsGroup && !finalGroupName)
    throw new AppError("Group name is required for group items", 400);
  if (!finalIsGroup) data.group_name = null;

  if (newImageUrl) data.image_url = newImageUrl;

  const item = await Item.update(id, data);
  return { item, oldImage: newImageUrl ? existing.image_url : null };
};

// Returns the image URL so the controller can delete the file
const deleteItem = async (id, user) => {
  const existing = await getItem(id);
  assertCanModify(existing, user);

  if (await Item.hasActiveLoan(id))
    throw new AppError("Cannot delete an item that is currently on loan", 409);

  await Item.remove(id);
  return existing.image_url;
};

// image_url is stored as "/uploads/items_images/<file>"; multer's deleteOldFile needs the filename
const filenameFromUrl = (url) => (url ? path.basename(url) : null);

module.exports = {
  createItem,
  getItems,
  getItem,
  updateItem,
  deleteItem,
  filenameFromUrl,
  CONDITIONS,
};

