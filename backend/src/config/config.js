require('dotenv').config();

module.exports = {
    // Server Configuration
    PORT : process.env.PORT,

    // Database Configuration
    DB_HOST : process.env.DB_HOST,
    DB_USER : process.env.DB_USER,
    DB_PORT : process.env.DB_PORT,
    DB_PASSWORD : process.env.DB_PASSWORD,
    DB_NAME : process.env.DB_DATABASE

}