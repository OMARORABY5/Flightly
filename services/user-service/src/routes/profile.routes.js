const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const authMiddleware = require('../middleware/auth.middleware');
const ProfileController = require('../controllers/profile.controller');

function getController(req) {
  return new ProfileController(req.db, req.redis);
}

const router = express.Router();

// ─── Multer Configuration for Photo Uploads ──────────────────────────────────
const uploadsDir = path.join(__dirname, '../../public/uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadsDir);
  },
  filename: function (req, file, cb) {
    // Unique filename: user_id-timestamp.ext
    const ext = path.extname(file.originalname) || '.jpg';
    cb(null, `${req.userId}-${Date.now()}${ext}`);
  }
});
const upload = multer({ storage: storage });

router.use(authMiddleware);

router.get('/', async (req, res) => {
  await getController(req).getProfile(req, res);
});

router.put('/', async (req, res) => {
  await getController(req).updateProfile(req, res);
});

// Legacy raw photo_url update
router.post('/photo', async (req, res) => {
  await getController(req).updatePhoto(req, res);
});

// Multipart file upload endpoint
router.post('/photo/upload', upload.single('photo'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ success: false, message: 'No image file provided' });
  }
  // Store the relative URL which will be served by static express middleware and routed by NGINX
  req.body.photo_url = `/uploads/${req.file.filename}`;
  await getController(req).updatePhoto(req, res);
});

module.exports = router;
