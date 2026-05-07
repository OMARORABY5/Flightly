// flight.test.js — FLIGHTLY Flight Service Unit Tests
// Tests for flight search input validation using mocked DB.
// WHY: Unit tests verify controller logic in isolation without a real DB.
//      searchFlights uses req.query (GET params), not req.body.

const FlightController = require('../src/controllers/flight.controller');

// ─── Helpers ─────────────────────────────────────────────────────────────────

function mockRes() {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
}

function mockDb(queryFn) {
  return {
    query: queryFn || jest.fn().mockResolvedValue({ rows: [], rowCount: 0 }),
  };
}

// ─── Flight Search Tests ──────────────────────────────────────────────────────
// searchFlights reads from req.query (it's a GET endpoint with query params)
// Field names: origin, destination, date, cabin, passengers

describe('GET /flights/search — Input Validation', () => {
  let controller;

  beforeEach(() => {
    controller = new FlightController(mockDb(), null);
  });

  test('should return 400 when origin is missing', async () => {
    const req = {
      query: { destination: 'DXB', date: '2025-12-01', passengers: '1' },
    };
    const res = mockRes();
    await controller.searchFlights(req, res);
    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({ success: false })
    );
  });

  test('should return 400 when destination is missing', async () => {
    const req = {
      query: { origin: 'CAI', date: '2025-12-01', passengers: '1' },
    };
    const res = mockRes();
    await controller.searchFlights(req, res);
    expect(res.status).toHaveBeenCalledWith(400);
  });

  test('should return 400 when date is missing', async () => {
    const req = { query: { origin: 'CAI', destination: 'DXB', passengers: '1' } };
    const res = mockRes();
    await controller.searchFlights(req, res);
    expect(res.status).toHaveBeenCalledWith(400);
  });

  test('should return success with empty flights when no flights found', async () => {
    const db = mockDb();
    // The controller runs a count query first then a flights query
    // Return 0 total_count in count, and empty rows in list
    db.query
      .mockResolvedValueOnce({ rows: [{ total_count: '0' }] }) // count
      .mockResolvedValueOnce({ rows: [] });                    // list

    controller = new FlightController(db, null);

    const req = {
      query: { origin: 'ZZZ', destination: 'YYY', date: '2099-01-01', passengers: '1' },
    };
    const res = mockRes();
    await controller.searchFlights(req, res);

    // Should succeed (success:true) even when flights is empty
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({ success: true })
    );
    // Pagination total should reflect 0 results
    const body = res.json.mock.calls[0][0];
    expect(body.data.pagination.total).toBe(0);
  });

  test('should correctly filter by stops (maxStops query param)', async () => {
    // This test verifies the SQL filter is applied — we check the db.query was called
    const db = mockDb();
    db.query
      .mockResolvedValueOnce({ rows: [{ total_count: '0' }] })
      .mockResolvedValueOnce({ rows: [] });

    controller = new FlightController(db, null);
    const req = {
      query: {
        origin: 'CAI', destination: 'DXB',
        date: '2025-12-01', passengers: '1',
        maxStops: '0', // Non-stop only
      },
    };
    const res = mockRes();
    await controller.searchFlights(req, res);

    // Verify the DB was queried (filter was applied without crashing)
    expect(db.query).toHaveBeenCalled();
    const callArgs = db.query.mock.calls[0][0];
    expect(callArgs).toContain('stops'); // SQL contains the stops filter
  });

  test('should sort by price when sort=price_asc is requested', async () => {
    const db = mockDb();
    db.query
      .mockResolvedValueOnce({ rows: [{ total_count: '0' }] })
      .mockResolvedValueOnce({ rows: [] });

    controller = new FlightController(db, null);
    const req = {
      query: {
        origin: 'CAI', destination: 'DXB',
        date: '2025-12-01', passengers: '1',
        sort: 'price_asc',
      },
    };
    const res = mockRes();
    await controller.searchFlights(req, res);

    // Verify DB was called — check the 1st query args for the ORDER BY clause
    expect(db.query).toHaveBeenCalled();
    // The first query call includes the ORDER BY clause
    const allCallArgs = db.query.mock.calls.map((c) => c[0]).join(' ');
    expect(allCallArgs).toContain('base_price ASC');
  });
});

// ─── Controller Structure Tests ───────────────────────────────────────────────

describe('FlightController — structure', () => {
  test('should be a proper class with expected methods', () => {
    const controller = new FlightController(mockDb(), null);
    expect(typeof controller.searchFlights).toBe('function');
    expect(typeof controller.getFlightById).toBe('function');
    expect(typeof controller.searchAirports).toBe('function');
    expect(typeof controller.getPopularAirports).toBe('function');
  });
});
