// Runs a migration file against the database.
// Usage:  node migrations/run.js migrations/add_chat_system.sql
const fs = require("fs");
const path = require("path");
const { pool } = require("../src/config/db.config");

const run = async () => {
  const file = path.resolve(
    process.argv[2] || path.join(__dirname, "add_chat_system.sql"),
  );

  if (!fs.existsSync(file)) {
    console.error(`Migration file not found: ${file}`);
    process.exit(1);
  }

  const sql = fs.readFileSync(file, "utf8");
  try {
    await pool.query(sql); // one multi-statement call: all-or-nothing
    console.log(`Migration applied: ${path.basename(file)}`);
  } catch (err) {
    console.error("Migration failed:", err.message);
    process.exitCode = 1;
  } finally {
    await pool.end();
  }
};

run();