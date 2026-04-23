const assert = require('node:assert/strict');
const test = require('node:test');
const mongoose = require('mongoose');
const request = require('supertest');
const { MongoMemoryServer } = require('mongodb-memory-server');

const { createApp } = require('../src/app');
const User = require('../src/modules/users/user.model');
const Transaction = require('../src/modules/transactions/transaction.model');

process.env.JWT_SECRET = process.env.JWT_SECRET || 'test_jwt_secret';
process.env.JWT_REFRESH_SECRET =
  process.env.JWT_REFRESH_SECRET || 'test_refresh_secret';
process.env.JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';
process.env.JWT_REFRESH_EXPIRES_IN =
  process.env.JWT_REFRESH_EXPIRES_IN || '30d';
process.env.RATE_LIMIT_MAX = process.env.RATE_LIMIT_MAX || '1000';

let app;
let mongoServer;

test.before(async () => {
  mongoServer = await MongoMemoryServer.create();
  await mongoose.connect(mongoServer.getUri());
  app = createApp();
});

test.after(async () => {
  await mongoose.disconnect();
  if (mongoServer) {
    await mongoServer.stop();
  }
});

test.beforeEach(async () => {
  await Promise.all([User.deleteMany({}), Transaction.deleteMany({})]);
});

async function registerAndGetAccessToken() {
  const registerRes = await request(app).post('/api/auth/register').send({
    name: 'Test User',
    email: 'test@example.com',
    password: 'password123',
  });

  assert.equal(registerRes.status, 201);
  return registerRes.body.data.accessToken;
}

test('POST /api/auth/register creates user and returns tokens', async () => {
  const res = await request(app).post('/api/auth/register').send({
    name: 'Shree',
    email: 'shree@example.com',
    password: 'password123',
  });

  assert.equal(res.status, 201);
  assert.equal(res.body.success, true);
  assert.equal(res.body.data.user.email, 'shree@example.com');
  assert.ok(res.body.data.accessToken);
  assert.ok(res.body.data.refreshToken);
});

test('POST /api/auth/login returns 401 for invalid password', async () => {
  await request(app).post('/api/auth/register').send({
    name: 'Shree',
    email: 'login@example.com',
    password: 'password123',
  });

  const res = await request(app).post('/api/auth/login').send({
    email: 'login@example.com',
    password: 'wrong-password',
  });

  assert.equal(res.status, 401);
  assert.equal(res.body.success, false);
});

test('GET /api/transactions requires authentication', async () => {
  const res = await request(app).get('/api/transactions');

  assert.equal(res.status, 401);
  assert.equal(res.body.success, false);
});

test('POST /api/transactions creates transaction for authenticated user', async () => {
  const token = await registerAndGetAccessToken();

  const createRes = await request(app)
    .post('/api/transactions')
    .set('Authorization', `Bearer ${token}`)
    .send({
      amount: 299.5,
      type: 'debit',
      category: 'food',
      title: 'Lunch',
      date: '2026-04-20T10:00:00.000Z',
    });

  assert.equal(createRes.status, 201);
  assert.equal(createRes.body.success, true);
  assert.equal(createRes.body.data.title, 'Lunch');
  assert.equal(createRes.body.data.type, 'debit');

  const listRes = await request(app)
    .get('/api/transactions')
    .set('Authorization', `Bearer ${token}`);

  assert.equal(listRes.status, 200);
  assert.equal(listRes.body.success, true);
  assert.equal(listRes.body.data.length, 1);
  assert.equal(listRes.body.pagination.total, 1);
});

test('POST /api/transactions/sync upserts transactions', async () => {
  const token = await registerAndGetAccessToken();
  const txId = new mongoose.Types.ObjectId().toString();

  const syncRes = await request(app)
    .post('/api/transactions/sync')
    .set('Authorization', `Bearer ${token}`)
    .send({
      transactions: [
        {
          id: txId,
          amount: 1500,
          type: 'debit',
          category: 'shopping',
          title: 'Synced purchase',
          date: '2026-04-18T12:00:00.000Z',
          isSynced: false,
        },
      ],
    });

  assert.equal(syncRes.status, 200);
  assert.equal(syncRes.body.success, true);
  assert.equal(syncRes.body.data.length, 1);
  assert.equal(syncRes.body.data[0]._id, txId);
  assert.equal(syncRes.body.data[0].isSynced, true);

  const inDb = await Transaction.findById(txId);
  assert.ok(inDb);
  assert.equal(inDb.title, 'Synced purchase');
  assert.equal(inDb.isSynced, true);
});
