const router = require('express').Router();
const ctrl = require('../controllers/user.controllers');
const { protect } = require('../middlewares/auth.middleware');
const { profilePicUpload } = require('../config/multer.config');

router.post('/register', ctrl.register);
router.post('/login', ctrl.login);

router.get('/me', protect, ctrl.getMe);
router.put('/me', protect, profilePicUpload.single('avatar'), ctrl.updateMe);
router.put('/me/password', protect, ctrl.changePassword);

module.exports = router;