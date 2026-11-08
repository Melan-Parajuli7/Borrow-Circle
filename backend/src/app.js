const express = require('express');
const app = express();
const path = require('path');
const userRoutes = require('./routes/user.routes')
const itemRoutes = require('./routes/item.routes')
const authMiddleware = require('./middlewares/error.middleware')

app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

app.use('/api/users', userRoutes);
app.use("/api/items", itemRoutes);
app.use(authMiddleware);


module.exports = app;