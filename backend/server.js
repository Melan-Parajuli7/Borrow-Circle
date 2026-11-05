const app = require('./src/app');
const { connectDB } = require('./src/config/db.config');
const { PORT } = require('./src/config/config');

const startServer = async () => {
  await connectDB();            // connect first
  app.listen(PORT, () => {      // then listen
    console.log(`Server running on port ${PORT}`);
  });
};

startServer();