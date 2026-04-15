require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');

const authRoutes = require('./modules/auth/auth.routes');
const transactionRoutes = require('./modules/transactions/transaction.routes');
const analyticsRoutes = require('./modules/analytics/analytics.routes');
const userRoutes = require('./modules/users/user.routes');

const { connectMongoDB } = require('./config/database');
const { errorHandler } = require('./middleware/error.middleware');

const app = express();

// ─── Middleware ─────────────────────────────────────────────────────────────

app.use(helmet());
app.use(cors({ origin: '*', credentials: true }));
app.use(express.json({ limit: '10mb' }));
app.use(morgan('combined'));

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
  max: parseInt(process.env.RATE_LIMIT_MAX) || 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, message: 'Too many requests, please try again later.' },
});
app.use('/api/', limiter);

// ─── Routes ─────────────────────────────────────────────────────────────────

app.get('/health', (_, res) => res.json({ status: 'ok', timestamp: new Date() }));

app.use('/api/auth', authRoutes);
app.use('/api/transactions', transactionRoutes);
app.use('/api/analytics', analyticsRoutes);
app.use('/api/users', userRoutes);

// 404 handler
app.use((req, res) =>
  res.status(404).json({ success: false, message: `Route ${req.path} not found` })
);

// Error handler
app.use(errorHandler);

// ─── Start ───────────────────────────────────────────────────────────────────

const PORT = process.env.PORT || 3000;

async function bootstrap() {
  try {
    await connectMongoDB();
    app.listen(PORT, () => {
      console.log(`🚀 Finance Tracker API running on port ${PORT}`);
      console.log(`   ENV: ${process.env.NODE_ENV}`);
    });
  } catch (err) {
    console.error('❌ Failed to start server:', err);
    process.exit(1);
  }
}

bootstrap();
