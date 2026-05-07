const express = require('express');
const authMiddleware = require('../middleware/auth.middleware');
const SettingsController = require('../controllers/settings.controller');

function getController(req) {
  return new SettingsController(req.db, req.redis);
}

const router = express.Router();

router.use(authMiddleware);

router.get('/', async (req, res) => {
  await getController(req).getSettings(req, res);
});

router.put('/', async (req, res) => {
  await getController(req).updateSettings(req, res);
});

module.exports = router;
