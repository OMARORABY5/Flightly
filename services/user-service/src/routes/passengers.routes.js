// passengers.routes.js — FLIGHTLY User Service
// Phase 6: Passenger profile CRUD routes

const express = require('express');
const router  = express.Router();
const PassengersController = require('../controllers/passengers.controller');

function getController(req) {
  return new PassengersController(req.db, req.redis);
}

// GET  /users/passengers?user_id=       — list all passengers for user
router.get('/', async (req, res) => {
  await getController(req).listPassengers(req, res);
});

// POST /users/passengers                — add a new passenger
router.post('/', async (req, res) => {
  await getController(req).addPassenger(req, res);
});

// PUT  /users/passengers/:id            — update a passenger
router.put('/:id', async (req, res) => {
  await getController(req).updatePassenger(req, res);
});

// DELETE /users/passengers/:id?user_id= — delete a passenger
router.delete('/:id', async (req, res) => {
  await getController(req).deletePassenger(req, res);
});

module.exports = router;
