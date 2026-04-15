const Transaction = require('../transactions/transaction.model');

const AnalyticsController = {
  /**
   * GET /api/analytics/daily?date=YYYY-MM-DD
   */
  async getDaily(req, res) {
    const userId = req.user.id;
    const date = req.query.date ? new Date(req.query.date) : new Date();
    const start = new Date(date.getFullYear(), date.getMonth(), date.getDate());
    const end = new Date(start);
    end.setDate(end.getDate() + 1);

    const txs = await Transaction.find({
      userId,
      date: { $gte: start, $lt: end },
    });

    const summary = _computeSummary(txs);
    res.json({ success: true, data: summary });
  },

  /**
   * GET /api/analytics/monthly?year=2024&month=4
   */
  async getMonthly(req, res) {
    const userId = req.user.id;
    const year = parseInt(req.query.year) || new Date().getFullYear();
    const month = parseInt(req.query.month) || new Date().getMonth() + 1;

    const start = new Date(year, month - 1, 1);
    const end = new Date(year, month, 1);

    const txs = await Transaction.find({
      userId,
      date: { $gte: start, $lt: end },
    });

    const summary = _computeSummary(txs);
    const topExpenses = [...txs]
      .filter((t) => t.type === 'debit')
      .sort((a, b) => b.amount - a.amount)
      .slice(0, 5);

    res.json({
      success: true,
      data: { year, month, summary, topExpenses },
    });
  },

  /**
   * GET /api/analytics/yearly?year=2024
   */
  async getYearly(req, res) {
    const userId = req.user.id;
    const year = parseInt(req.query.year) || new Date().getFullYear();

    // Aggregate by month
    const result = await Transaction.aggregate([
      {
        $match: {
          userId: String(userId),
          date: {
            $gte: new Date(`${year}-01-01`),
            $lte: new Date(`${year}-12-31`),
          },
        },
      },
      {
        $group: {
          _id: { month: { $month: '$date' }, type: '$type' },
          total: { $sum: '$amount' },
        },
      },
    ]);

    // Reshape to monthly array
    const months = Array.from({ length: 12 }, (_, i) => ({
      month: i + 1,
      year,
      totalIncome: 0,
      totalExpense: 0,
      balance: 0,
    }));

    result.forEach((r) => {
      const m = months[r._id.month - 1];
      if (r._id.type === 'credit') m.totalIncome = r.total;
      if (r._id.type === 'debit') m.totalExpense = r.total;
    });

    months.forEach((m) => {
      m.balance = m.totalIncome - m.totalExpense;
    });

    res.json({ success: true, data: months });
  },
};

function _computeSummary(txs) {
  let totalIncome = 0;
  let totalExpense = 0;
  const categoryBreakdown = {};
  const dailyMap = {};

  txs.forEach((t) => {
    if (t.type === 'credit') {
      totalIncome += t.amount;
    } else {
      totalExpense += t.amount;
      categoryBreakdown[t.category] = (categoryBreakdown[t.category] || 0) + t.amount;
    }
    const day = t.date.toISOString().split('T')[0];
    if (!dailyMap[day]) dailyMap[day] = { income: 0, expense: 0 };
    if (t.type === 'credit') dailyMap[day].income += t.amount;
    else dailyMap[day].expense += t.amount;
  });

  const dailySpendings = Object.entries(dailyMap)
    .map(([date, v]) => ({ date, ...v, net: v.income - v.expense }))
    .sort((a, b) => a.date.localeCompare(b.date));

  const savingsRate = totalIncome > 0
    ? ((totalIncome - totalExpense) / totalIncome) * 100
    : 0;

  return {
    totalIncome,
    totalExpense,
    balance: totalIncome - totalExpense,
    savingsRate,
    categoryBreakdown,
    dailySpendings,
  };
}

module.exports = AnalyticsController;
