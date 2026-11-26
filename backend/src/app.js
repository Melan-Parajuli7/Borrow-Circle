const express = require("express");
const path = require("path");
const cookieParser = require("cookie-parser");
const morgan = require("morgan");
const cors = require("cors");

const userRoutes = require("./routes/user.routes");
const itemRoutes = require("./routes/item.routes");
const borrowRequestRoutes = require("./routes/borrowRequests.routes");
const loanRoutes = require("./routes/loan.routes");
const reviewRoutes = require("./routes/review.routes");
const chatRoutes = require("./routes/chat.routes");
const adminRoutes = require("./routes/admin.routes");
const errorHandler = require("./middlewares/error.middleware");

const app = express();

app.use(morgan(process.env.NODE_ENV === "production" ? "combined" : "dev"));

// The React admin dashboard (Vite dev server) runs on another port, so the
// browser needs CORS with credentials to send the auth cookies along.
app.use(
  cors({
    origin: [
      "http://localhost:5173",
      "http://127.0.0.1:5173",
      "http://localhost:4173", // vite preview
      "http://127.0.0.1:4173",
    ],
    credentials: true,
  }),
);

app.use(express.json());
app.use(cookieParser());
app.use("/uploads", express.static(path.join(__dirname, "../uploads")));

app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});  

app.use("/api/users", userRoutes);
app.use("/api/items", itemRoutes);
app.use("/api/requests", borrowRequestRoutes);
app.use("/api/loans", loanRoutes);
app.use("/api/reviews", reviewRoutes);
app.use("/api/chats", chatRoutes);
app.use("/api/admin", adminRoutes);

app.use((req, res) => {
  res.status(404).json({ success: false, message: "Route not found" });
});

app.use(errorHandler);

module.exports = app;