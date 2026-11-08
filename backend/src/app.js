const express = require("express");
const path = require("path");
const cookieParser = require("cookie-parser");

const userRoutes = require("./routes/user.routes");
const itemRoutes = require("./routes/item.routes");
const errorHandler = require("./middlewares/error.middleware");

const app = express();

app.use(express.json());
app.use(cookieParser()); // fills req.cookies; must come before the routes
app.use("/uploads", express.static(path.join(__dirname, "../uploads")));

app.use("/api/users", userRoutes);
app.use("/api/items", itemRoutes);

// unknown routes return JSON instead of Express's default HTML page
app.use((req, res) => {
  res.status(404).json({ success: false, message: "Route not found" });
});

app.use(errorHandler); // must be last

module.exports = app;