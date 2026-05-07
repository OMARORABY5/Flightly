// auth.test.js — FLIGHTLY Auth Service Unit Tests
// Tests for register and login business logic using mocked DB and Redis.
// WHY: Unit tests verify individual functions in isolation, so a bug in one
//      function doesn't hide errors in another. We mock the DB so we don't
//      need a real running database to run these tests.

const AuthController = require('../src/controllers/auth.controller');

// ─── Helpers ─────────────────────────────────────────────────────────────────

/**
 * Build a mock Express response object so we can spy on res.status and res.json
 * without needing a real HTTP connection.
 */
function mockRes() {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
}

/**
 * Build a minimal mock DB (pg Pool).
 * query() is a Jest mock so each test can override its return value.
 */
function mockDb(overrides = {}) {
  return {
    query: jest.fn(),
    ...overrides,
  };
}

// ─── Register Tests ───────────────────────────────────────────────────────────

describe('POST /auth/register', () => {
  let controller;

  beforeEach(() => {
    controller = new AuthController(mockDb(), null);
  });

  test('should reject registration when email is missing', async () => {
    const req = { body: { password: 'Test1234!' } };
    const res = mockRes();
    await controller.register(req, res);
    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({ success: false })
    );
  });

  test('should reject registration when password is missing', async () => {
    const req = { body: { email: 'user@test.com' } };
    const res = mockRes();
    await controller.register(req, res);
    expect(res.status).toHaveBeenCalledWith(400);
  });

  test('should reject registration with invalid email format', async () => {
    const req = { body: { email: 'not-an-email', password: 'Test1234!' } };
    const res = mockRes();
    await controller.register(req, res);
    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({ message: expect.stringContaining('Invalid email') })
    );
  });

  test('should reject registration with short password (< 8 chars)', async () => {
    const req = { body: { email: 'user@test.com', password: 'abc' } };
    const res = mockRes();
    await controller.register(req, res);
    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({ message: expect.stringContaining('8 characters') })
    );
  });

  test('should reject registration when email already exists (duplicate)', async () => {
    const db = mockDb();
    // First query (check existing) returns a user row
    db.query.mockResolvedValueOnce({ rows: [{ id: 'existing-id' }] });
    controller = new AuthController(db, null);

    const req = { body: { email: 'existing@test.com', password: 'Test1234!' } };
    const res = mockRes();
    await controller.register(req, res);
    expect(res.status).toHaveBeenCalledWith(409);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({ message: expect.stringContaining('already registered') })
    );
  });

  test('should hash password before storing in database', async () => {
    const db = mockDb();
    // No existing user
    db.query
      .mockResolvedValueOnce({ rows: [] })
      .mockResolvedValueOnce({
        rows: [{
          id: 'new-id',
          email: 'newuser@test.com',
          display_name: null,
          created_at: new Date().toISOString(),
        }],
      });
    controller = new AuthController(db, null);

    const req = { body: { email: 'newuser@test.com', password: 'Test1234!', displayName: 'New User' } };
    const res = mockRes();
    await controller.register(req, res);

    expect(res.status).toHaveBeenCalledWith(201);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({ success: true })
    );

    // Verify the second DB call (INSERT) has a bcrypt hash, not plain text
    const insertCall = db.query.mock.calls[1];
    const passwordHashArg = insertCall[1][2]; // 3rd bind param is the hash
    expect(passwordHashArg).not.toBe('Test1234!');
    expect(passwordHashArg).toMatch(/^\$2[aby]\$\d{2}\$/); // bcrypt format
  });
});

// ─── Login Tests ──────────────────────────────────────────────────────────────

describe('POST /auth/login', () => {
  let controller;

  beforeEach(() => {
    controller = new AuthController(mockDb(), null);
  });

  test('should reject login when email is missing', async () => {
    const req = { body: { password: 'Test1234!' } };
    const res = mockRes();
    await controller.login(req, res);
    expect(res.status).toHaveBeenCalledWith(400);
  });

  test('should reject login when password is missing', async () => {
    const req = { body: { email: 'user@test.com' } };
    const res = mockRes();
    await controller.login(req, res);
    expect(res.status).toHaveBeenCalledWith(400);
  });

  test('should return 401 when email does not exist', async () => {
    const db = mockDb();
    db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });
    controller = new AuthController(db, null);

    const req = { body: { email: 'ghost@test.com', password: 'Test1234!' } };
    const res = mockRes();
    await controller.login(req, res);
    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({ message: expect.stringContaining('Invalid email or password') })
    );
  });

  test('should return 401 when password is wrong', async () => {
    const bcrypt = require('bcryptjs');
    const db = mockDb();
    // Return a user with a known hash
    const hash = await bcrypt.hash('CorrectPassword!', 4); // low rounds for test speed
    db.query.mockResolvedValueOnce({
      rows: [{ id: 'uid', email: 'user@test.com', password_hash: hash, display_name: 'User' }],
      rowCount: 1,
    });
    controller = new AuthController(db, null);

    const req = { body: { email: 'user@test.com', password: 'WrongPassword!' } };
    const res = mockRes();
    await controller.login(req, res);
    expect(res.status).toHaveBeenCalledWith(401);
  });

  test('should return JWT token on successful login', async () => {
    const bcrypt = require('bcryptjs');
    const db = mockDb();
    const hash = await bcrypt.hash('Test1234!', 4);
    db.query.mockResolvedValueOnce({
      rows: [{ id: 'uid-123', email: 'user@test.com', password_hash: hash, display_name: 'User' }],
      rowCount: 1,
    });
    controller = new AuthController(db, null);

    const req = { body: { email: 'user@test.com', password: 'Test1234!' } };
    const res = mockRes();
    await controller.login(req, res);
    expect(res.status).toHaveBeenCalledWith(200);
    const responseBody = res.json.mock.calls[0][0];
    expect(responseBody.success).toBe(true);
    expect(responseBody.data).toHaveProperty('token');
    expect(typeof responseBody.data.token).toBe('string');
  });
});
