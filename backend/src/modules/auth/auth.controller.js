const jwt = require('jsonwebtoken');
const User = require('../users/user.model');

function signAccessToken(userId) {
  return jwt.sign({ id: userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  });
}

function signRefreshToken(userId) {
  return jwt.sign({ id: userId }, process.env.JWT_REFRESH_SECRET, {
    expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d',
  });
}

const AuthController = {
  /**
   * POST /api/auth/register
   */
  async register(req, res) {
    const { name, email, password } = req.body;
    if (!name || !email || !password) {
      return res.status(400).json({ success: false, message: 'All fields are required' });
    }
    const existing = await User.findOne({ email });
    if (existing) {
      return res.status(409).json({ success: false, message: 'Email already registered' });
    }
    const user = await User.create({ name, email, password });
    const accessToken = signAccessToken(user._id);
    const refreshToken = signRefreshToken(user._id);

    // Save refresh token
    user.refreshToken = refreshToken;
    await user.save({ validateBeforeSave: false });

    res.status(201).json({
      success: true,
      data: {
        user: { id: user._id, name: user.name, email: user.email, createdAt: user.createdAt },
        accessToken,
        refreshToken,
      },
    });
  },

  /**
   * POST /api/auth/login
   */
  async login(req, res) {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'Email and password required' });
    }
    const user = await User.findOne({ email }).select('+password +refreshToken');
    if (!user || !(await user.comparePassword(password))) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }
    const accessToken = signAccessToken(user._id);
    const refreshToken = signRefreshToken(user._id);

    user.refreshToken = refreshToken;
    await user.save({ validateBeforeSave: false });

    res.json({
      success: true,
      data: {
        user: {
          id: user._id,
          name: user.name,
          email: user.email,
          phone: user.phone,
          avatarUrl: user.avatarUrl,
          isEmailVerified: user.isEmailVerified,
          createdAt: user.createdAt,
        },
        accessToken,
        refreshToken,
      },
    });
  },

  /**
   * POST /api/auth/refresh-token
   */
  async refreshToken(req, res) {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      return res.status(400).json({ success: false, message: 'Refresh token required' });
    }
    const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
    const user = await User.findById(decoded.id).select('+refreshToken');
    if (!user || user.refreshToken !== refreshToken) {
      return res.status(401).json({ success: false, message: 'Invalid refresh token' });
    }
    const newAccessToken = signAccessToken(user._id);
    res.json({ success: true, data: { accessToken: newAccessToken } });
  },

  /**
   * POST /api/auth/logout
   */
  async logout(req, res) {
    if (req.user) {
      await User.findByIdAndUpdate(req.user.id, { $unset: { refreshToken: 1 } });
    }
    res.json({ success: true, message: 'Logged out successfully' });
  },
};

module.exports = AuthController;
