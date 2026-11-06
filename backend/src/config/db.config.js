require('dotenv').config();
const {Pool} = require('pg');
const { Sequelize } = require('sequelize');


const pool = new Pool({
    host : process.env.DB_HOST,
    user : process.env.DB_USER,
    port : process.env.DB_PORT,
    password : process.env.DB_PASSWORD,
    database : process.env.DB_NAME
});

const connectDB = async () => {
    try {
        const client = await pool.connect();
        console.log("Connected to Database", process.env.DB_NAME);
        client.release(); // return to the pool
    }catch(err){
        console.error("Failed to Connect", err.message);
        process.exit(1);  // exits if databse is unrecheable
    }
};


module.exports = {
    pool ,
    connectDB
}
