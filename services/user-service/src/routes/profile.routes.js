const express = require('express');
const authMiddleware = require('../middleware/auth.middleware');
const ProfileController = require('../controllers/profile.controller');

function getController(req) {
  return new ProfileController(req.db, req.redis);
}

const router = express.Router();

router.use(authMiddleware);

router.get('/', async (req, res) => {
  await getController(req).getProfile(req, res);
});

router.put('/', async (req, res) => {
  await getController(req).updateProfile(req, res);
});

router.post('/photo', async (req, res) => {
  await getController(req).updatePhoto(req, res);
});

module.exports = router;
