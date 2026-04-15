const Transaction = require('./transaction.model');

const TransactionController = {
  /**
   * GET /api/transactions
   * Query: startDate, endDate, category, type, page, limit
   */
  async getTransactions(req, res) {
    const { startDate, endDate, category, type, page = 1, limit = 20 } = req.query;
    const userId = req.user.id;

    const filter = { userId };
    if (startDate || endDate) {
      filter.date = {};
      if (startDate) filter.date.$gte = new Date(startDate);
      if (endDate) filter.date.$lte = new Date(endDate);
    }
    if (category) filter.category = category;
    if (type) filter.type = type;

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [data, total] = await Promise.all([
      Transaction.find(filter)
        .sort({ date: -1 })
        .skip(skip)
        .limit(parseInt(limit)),
      Transaction.countDocuments(filter),
    ]);

    res.json({
      success: true,
      data,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(total / parseInt(limit)),
      },
    });
  },

  /**
   * GET /api/transactions/:id
   */
  async getTransactionById(req, res) {
    const tx = await Transaction.findOne({
      _id: req.params.id,
      userId: req.user.id,
    });
    if (!tx) {
      return res.status(404).json({ success: false, message: 'Transaction not found' });
    }
    res.json({ success: true, data: tx });
  },

  /**
   * POST /api/transactions
   */
  async createTransaction(req, res) {
    const tx = await Transaction.create({
      ...req.body,
      userId: req.user.id,
    });
    res.status(201).json({ success: true, data: tx });
  },

  /**
   * PUT /api/transactions/:id
   */
  async updateTransaction(req, res) {
    const tx = await Transaction.findOneAndUpdate(
      { _id: req.params.id, userId: req.user.id },
      { $set: req.body },
      { new: true, runValidators: true }
    );
    if (!tx) {
      return res.status(404).json({ success: false, message: 'Transaction not found' });
    }
    res.json({ success: true, data: tx });
  },

  /**
   * DELETE /api/transactions/:id
   */
  async deleteTransaction(req, res) {
    const tx = await Transaction.findOneAndDelete({
      _id: req.params.id,
      userId: req.user.id,
    });
    if (!tx) {
      return res.status(404).json({ success: false, message: 'Transaction not found' });
    }
    res.json({ success: true, message: 'Transaction deleted' });
  },

  /**
   * POST /api/transactions/sync
   * Batch upsert unsynced transactions from device
   */
  async syncTransactions(req, res) {
    const { transactions } = req.body;
    const userId = req.user.id;

    const ops = transactions.map((t) => ({
      updateOne: {
        filter: { _id: t.id || t._id, userId },
        update: { $set: { ...t, userId, isSynced: true } },
        upsert: true,
      },
    }));

    await Transaction.bulkWrite(ops);
    const synced = await Transaction.find({
      _id: { $in: transactions.map((t) => t.id || t._id) },
      userId,
    });

    res.json({ success: true, data: synced });
  },
};

module.exports = TransactionController;
