const { Router } = require('express');
const authMiddleware = require('../../middleware/auth.middleware');
const { asyncHandler } = require('../../middleware/error.middleware');
const ctrl = require('./transaction.controller');

const router = Router();

router.use(authMiddleware);

router.get('/', asyncHandler(ctrl.getTransactions));
router.get('/:id', asyncHandler(ctrl.getTransactionById));
router.post('/', asyncHandler(ctrl.createTransaction));
router.post('/sync', asyncHandler(ctrl.syncTransactions));
router.put('/:id', asyncHandler(ctrl.updateTransaction));
router.delete('/:id', asyncHandler(ctrl.deleteTransaction));

module.exports = router;
