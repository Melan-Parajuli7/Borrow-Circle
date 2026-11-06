require('dotenv').config();

module.exports = {
    // Server Configuration
    PORT : process.env.PORT,

    // Database Configuration
    DB_HOST : process.env.DB_HOST,
    DB_USER : process.env.DB_USER,
    DB_PORT : process.env.DB_PORT,
    DB_PASSWORD : process.env.DB_PASSWORD,
    DB_NAME : process.env.DB_DATABASE,

    // Allowed Domains
    ALLOWED_EMAIL_DOMAINS : process.env.ALLOWED_EMAIL_DOMAINS,

    // JWT Secrets and Expiry Time
    JWT_SECRET : process.env.JWT_SECRET,
    JWT_EXPIRES_IN: process.env.JWT_EXPIRES_IN


}