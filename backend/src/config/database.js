const mongoose = require('mongoose');

async function connectMongoDB() {
  const uri = process.env.MONGODB_URI || 'mongodb://localhost:27017/finance_tracker';
  await mongoose.connect(uri);
  console.log('✅ MongoDB connected');
}

module.exports = { connectMongoDB };
