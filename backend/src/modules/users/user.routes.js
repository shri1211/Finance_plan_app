const { Router } = require('express');
const authMiddleware = require('../../middleware/auth.middleware');
const { asyncHandler } = require('../../middleware/error.middleware');
const User = require('./user.model');

const router = Router();

router.use(authMiddleware);

// GET /api/users/me
router.get('/me', asyncHandler(async (req, res) => {
  const user = await User.findById(req.user.id);
  if (!user) return res.status(404).json({ success: false, message: 'User not found' });
  res.json({ success: true, data: user });
}));

// PUT /api/users/me
router.put('/me', asyncHandler(async (req, res) => {
  const { name, phone, avatarUrl } = req.body;
  const user = await User.findByIdAndUpdate(
    req.user.id,
    { $set: { name, phone, avatarUrl } },
    { new: true, runValidators: true }
  );
  res.json({ success: true, data: user });
}));

module.exports = router;
