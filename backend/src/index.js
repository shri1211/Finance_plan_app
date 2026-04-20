require('dotenv').config();

const { connectMongoDB } = require('./config/database');
const { createApp } = require('./app');

// ─── Start ───────────────────────────────────────────────────────────────────

const PORT = process.env.PORT || 3000;

async function bootstrap() {
  try {
    await connectMongoDB();
    const app = createApp();
    app.listen(PORT, () => {
      console.log(`🚀 Finance Tracker API running on port ${PORT}`);
      console.log(`   ENV: ${process.env.NODE_ENV}`);
    });
  } catch (err) {
    console.error('❌ Failed to start server:', err);
    process.exit(1);
  }
}

if (require.main === module) {
  bootstrap();
}

module.exports = { bootstrap };
