const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');

const authRoutes = require('./modules/auth/auth.routes');
const transactionRoutes = require('./modules/transactions/transaction.routes');
const analyticsRoutes = require('./modules/analytics/analytics.routes');
const userRoutes = require('./modules/users/user.routes');

const { errorHandler } = require('./middleware/error.middleware');

function createApp() {
  const app = express();

  app.use(helmet());
  app.use(cors({ origin: '*', credentials: true }));
  app.use(express.json({ limit: '10mb' }));
  app.use(morgan('combined'));

  const limiter = rateLimit({
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS, 10) || 15 * 60 * 1000,
    max: parseInt(process.env.RATE_LIMIT_MAX, 10) || 100,
    standardHeaders: true,
    legacyHeaders: false,
    message: {
      success: false,
      message: 'Too many requests, please try again later.',
    },
  });
  app.use('/api/', limiter);

  app.get('/health', (_, res) => res.json({ status: 'ok', timestamp: new Date() }));

  app.use('/api/auth', authRoutes);
  app.use('/api/transactions', transactionRoutes);
  app.use('/api/analytics', analyticsRoutes);
  app.use('/api/users', userRoutes);

  app.use((req, res) =>
    res.status(404).json({ success: false, message: `Route ${req.path} not found` })
  );

  app.use(errorHandler);

  return app;
}

module.exports = { createApp };
