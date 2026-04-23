const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema(
  {
    _id: { type: String }, // Accept custom UUID from frontend
    userId: { type: String, required: true, index: true },
    amount: { type: Number, required: true, min: 0 },
    type: { type: String, enum: ['credit', 'debit'], required: true },
    category: {
      type: String,
      enum: [
        'food', 'transport', 'shopping', 'entertainment',
        'health', 'utilities', 'education', 'salary',
        'investment', 'transfer', 'other',
      ],
      default: 'other',
    },
    title: { type: String, required: true, trim: true, maxlength: 200 },
    description: { type: String, trim: true, maxlength: 500 },
    merchant: { type: String, trim: true, maxlength: 100 },
    date: { type: Date, required: true, index: true },
    isSmsParsed: { type: Boolean, default: false },
    isSynced: { type: Boolean, default: true },
    rawSms: { type: String },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
  }
);

// Compound indexes for performance
transactionSchema.index({ userId: 1, date: -1 });
transactionSchema.index({ userId: 1, category: 1 });
transactionSchema.index({ userId: 1, type: 1 });

module.exports = mongoose.model('Transaction', transactionSchema);
