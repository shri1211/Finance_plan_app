const { Router } = require('express');
const authMiddleware = require('../../middleware/auth.middleware');
const { asyncHandler } = require('../../middleware/error.middleware');
const ctrl = require('./analytics.controller');

const router = Router();

router.use(authMiddleware);

router.get('/daily', asyncHandler(ctrl.getDaily));
router.get('/monthly', asyncHandler(ctrl.getMonthly));
router.get('/yearly', asyncHandler(ctrl.getYearly));

module.exports = router;
