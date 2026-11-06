const multer = require('multer');
const path = require('path');
const fs = require('fs');


// defina upload directories

const UPLOAD_DIRS = {
    profilePics: path.join(__dirname, "../../uploads/profile_pics"),
    itemsImages: path.join(__dirname, "../../uploads/items_images"),
};

// create upload directories if they don't exist
Object.values(UPLOAD_DIRS).forEach(dir => {
    if (!fs.existsSync(dir)) {  
        fs.mkdirSync(dir, { recursive: true });
    }
});

// storage configuration

const createStorage = (uploadDir) => {
  return multer.diskStorage({
    // Where to store files
    destination: (req, file, cb) => {
      cb(null, uploadDir);
    },

    // How to name files
    filename: (req, file, cb) => {
      // Get original name without extension
      const originalName = path.parse(file.originalname).name;

      // Clean filename
      const cleanName = originalName
        .toLowerCase()
        .replace(/\s+/g, "-")          // replace spaces with -
        .replace(/[^a-z0-9\-]/g, "");  // remove special characters

      // Create unique suffix
      const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;

      // Get extension
      const extension = path.extname(file.originalname);

      // Final filename
      const finalName = `${cleanName}-${uniqueSuffix}${extension}`;

      cb(null, finalName);
    },
  });
};

// file filter to allow only images

const fileFilter = (req, file, cb) => {
  const allowedMimeTypes = [
    "image/jpeg",
    "image/png",
    "image/gif",
    "image/webp",
  ];

  const ext = path.extname(file.originalname).toLowerCase();
  const allowedExtensions = [".jpg", ".jpeg", ".png", ".gif", ".webp"];

  if (
    allowedMimeTypes.includes(file.mimetype) &&
    allowedExtensions.includes(ext)
  ) {
    cb(null, true);
  } else {
    const error = new Error(
      "Only image files (jpg, png, gif, webp) are allowed"
    );
    error.code = "LIMIT_FILE_TYPE";
    cb(error, false);
  }
};

// create multer config

const createMulterConfig = (uploadDir, maxFileSize = 5 * 1024 * 1024) => {
  return multer({
    storage: createStorage(uploadDir),
    fileFilter: fileFilter,
    limits: {
      fileSize: maxFileSize,
      files: 1,
    },
  });
};

// multer instances for different upload types
const profilePicUpload = createMulterConfig(UPLOAD_DIRS.profilePics);
const itemImageUpload = createMulterConfig(UPLOAD_DIRS.itemsImages);

// delete old files

const deleteOldFile = (filename, type) => {
  if (!filename) return;

  const dir =
    type === "profilePic"
      ? UPLOAD_DIRS.profilePics
      : UPLOAD_DIRS.itemsImages;

  const filePath = path.join(dir, filename);

  if (fs.existsSync(filePath)) {
    try {
      fs.unlinkSync(filePath);
      console.log(`Deleted file: ${filePath}`);
    } catch (err) {
      console.error(`Error deleting file: ${err.message}`);
    }
  }
};

// Create a multer configuration for multiple recipe images
const itemsImagesUpload = multer({
  storage: createStorage(UPLOAD_DIRS.itemsImages),
  fileFilter: fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB per file
    files: 11 // Maximum 11 files (1 main + 10 step images)
  }
});

// get file url

const getFileUrl = (filename, type) => {
  if (!filename) return null;

  // Match the actual folder names
  const folder = type === "profilePic" ? "profile_pics" : "items_images";

  return `/uploads/${folder}/${filename}`;
};

// export modules
module.exports = {
  profilePicUpload,
  itemImageUpload, 
    deleteOldFile,
    getFileUrl,
    UPLOAD_DIRS,
    itemsImagesUpload,
};