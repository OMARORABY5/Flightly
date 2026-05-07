// booking.test.js — FLIGHTLY Booking Service Unit Tests
// Tests for booking creation business logic using mocked DB and Redis.
// WHY: Booking is the most business-critical flow (money involved), so we
//      test edge cases (duplicate passport, missing fields, price calculation).

const BookingController = require('../src/controllers/booking.controller');

// ─── Helpers ─────────────────────────────────────────────────────────────────

function mockRes() {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
}

// ─── Booking Reference Generation Tests ──────────────────────────────────────

describe('Booking Reference Generation', () => {
  test('should generate a reference in the format FLY-YYYYMMDD-XXXXXX', () => {
    const controller = new BookingController({ query: jest.fn() }, null);
    const ref = controller._generateReference();
    // e.g. "FLY-20250101-ABC123"
    expect(ref).toMatch(/^FLY-\d{8}-[A-Z0-9]{6}$/);
  });

  test('should generate unique references across multiple calls', () => {
    const controller = new BookingController({ query: jest.fn() }, null);
    const refs = new Set();
    for (let i = 0; i < 100; i++) {
      refs.add(controller._generateReference());
    }
    // Very unlikely to have collisions across 100 calls
    expect(refs.size).toBeGreaterThan(90);
  });
});

// ─── Create Booking Validation Tests ─────────────────────────────────────────

describe('POST /bookings/create — Input Validation', () => {
  let controller;

  beforeEach(() => {
    // Provide a minimal mock db with a connect() method (transaction flow)
    const db = {
      query: jest.fn(),
      connect: jest.fn().mockResolvedValue({
        query: jest.fn(),
        release: jest.fn(),
      }),
    };
    controller = new BookingController(db, null);
  });

  test('should return 400 when user_id is missing', async () => {
    const req = {
      body: {
        flight_id: 'f1', cabin_class: 'economy',
        contact_email: 'test@test.com', passenger_ids: ['p1'],
      },
    };
    const res = mockRes();
    await controller.createBooking(req, res);
    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({ success: false })
    );
  });

  test('should return 400 when flight_id is missing', async () => {
    const req = {
      body: {
        user_id: 'u1', cabin_class: 'economy',
        contact_email: 'test@test.com', passenger_ids: ['p1'],
      },
    };
    const res = mockRes();
    await controller.createBooking(req, res);
    expect(res.status).toHaveBeenCalledWith(400);
  });

  test('should return 400 when passenger_ids is empty array', async () => {
    const req = {
      body: {
        user_id: 'u1', flight_id: 'f1', cabin_class: 'economy',
        contact_email: 'test@test.com', passenger_ids: [],
      },
    };
    const res = mockRes();
    await controller.createBooking(req, res);
    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({ message: expect.stringContaining('passenger') })
    );
  });

  test('should return 400 when passenger_ids is not an array', async () => {
    const req = {
      body: {
        user_id: 'u1', flight_id: 'f1', cabin_class: 'economy',
        contact_email: 'test@test.com', passenger_ids: 'not-an-array',
      },
    };
    const res = mockRes();
    await controller.createBooking(req, res);
    expect(res.status).toHaveBeenCalledWith(400);
  });

  test('should return 400 when contact_email is missing', async () => {
    const req = {
      body: {
        user_id: 'u1', flight_id: 'f1', cabin_class: 'economy',
        passenger_ids: ['p1'],
      },
    };
    const res = mockRes();
    await controller.createBooking(req, res);
    expect(res.status).toHaveBeenCalledWith(400);
  });

  test('should return 409 when not enough seats available', async () => {
    const client = {
      query: jest.fn(),
      release: jest.fn(),
    };
    const db = {
      query: jest.fn(),
      connect: jest.fn().mockResolvedValue(client),
    };

    // Simulate BEGIN + flight lookup returning only 1 available seat
    client.query
      .mockResolvedValueOnce({}) // BEGIN
      .mockResolvedValueOnce({ // flight lookup
        rowCount: 1,
        rows: [{ id: 'f1', base_price: '500.00', available_seats: 1 }],
      });

    controller = new BookingController(db, null);

    const req = {
      body: {
        user_id: 'u1', flight_id: 'f1', cabin_class: 'economy',
        contact_email: 'test@test.com',
        passenger_ids: ['p1', 'p2', 'p3'], // 3 passengers, only 1 seat
      },
    };
    const res = mockRes();
    await controller.createBooking(req, res);
    expect(res.status).toHaveBeenCalledWith(409);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({ message: expect.stringContaining('seats') })
    );
  });

  test('should calculate correct total price (base_price × passengers)', async () => {
    // The booking controller's transaction makes these calls in order on `client`:
    // 1. BEGIN
    // 2. flight lookup (get base_price + available_seats)
    // 3. passenger validation (check passengers belong to user)
    // 4. INSERT booking  RETURNING *
    // 5. INSERT booking_passengers (one per passenger)
    // 6. UPDATE available_seats
    // 7. COMMIT
    // Plus: _uniqueReference() calls this.db.query (not client.query)

    const bookingRow = {
      id: 'booking-123',
      reference: 'FLY-20250101-ABCDEF',
      status: 'pending',
      payment_status: 'unpaid',
      total_price: '600.00', // 200 × 3 passengers
      cabin_class: 'economy',
      trip_type: 'one_way',
      contact_email: 'test@test.com',
      contact_phone: null,
      created_at: new Date().toISOString(),
    };

    const client = {
      query: jest.fn(),
      release: jest.fn(),
    };

    // Client query mock sequence
    client.query
      .mockResolvedValueOnce({})                                                             // 1. BEGIN
      .mockResolvedValueOnce({ rowCount: 1, rows: [{ id: 'f1', base_price: '200.00', available_seats: 10 }] }) // 2. flight lookup
      .mockResolvedValueOnce({ rowCount: 3, rows: [{ id: 'p1' }, { id: 'p2' }, { id: 'p3' }] })               // 3. passenger validation
      .mockResolvedValueOnce({ rowCount: 1, rows: [bookingRow] })                            // 4. INSERT booking
      .mockResolvedValueOnce({})                                                             // 5a. INSERT booking_passengers (p1)
      .mockResolvedValueOnce({})                                                             // 5b. INSERT booking_passengers (p2)
      .mockResolvedValueOnce({})                                                             // 5c. INSERT booking_passengers (p3)
      .mockResolvedValueOnce({})                                                             // 6. UPDATE available_seats
      .mockResolvedValueOnce({});                                                            // 7. COMMIT

    // db.query is called by _uniqueReference() for the duplicate check
    const db = {
      connect: jest.fn().mockResolvedValue(client),
      query: jest.fn().mockResolvedValue({ rowCount: 0 }), // reference not taken
    };

    controller = new BookingController(db, null);
    const req = {
      body: {
        user_id: 'u1', flight_id: 'f1', cabin_class: 'economy',
        contact_email: 'test@test.com',
        passenger_ids: ['p1', 'p2', 'p3'],
      },
    };
    const res = mockRes();
    await controller.createBooking(req, res);

    expect(res.status).toHaveBeenCalledWith(201);
    const body = res.json.mock.calls[0][0];
    expect(body.success).toBe(true);
    expect(body.data).toHaveProperty('reference');
    expect(body.data.reference).toMatch(/^FLY-/);
    // Total price: 200 × 3 passengers = 600
    expect(body.data.total_price).toBe(600);
  });

});
