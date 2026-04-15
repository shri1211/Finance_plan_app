const { Router } = require('express');
const authMiddleware = require('../../middleware/auth.middleware');
const { asyncHandler } = require('../../middleware/error.middleware');
const ctrl = require('./auth.controller');

const router = Router();

router.post('/register', asyncHandler(ctrl.register));
router.post('/login', asyncHandler(ctrl.login));
router.post('/refresh-token', asyncHandler(ctrl.refreshToken));
router.post('/logout', authMiddleware, asyncHandler(ctrl.logout));

module.exports = router;
