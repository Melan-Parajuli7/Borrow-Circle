const express = require('express')
const {PORT} = require('./config/config')
const app = express();


app.use(express.json());


module.exports = app;