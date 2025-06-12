const express = require('express');
const router = express.Router();
const birthdayController = require('../controllers/birthdayController');
const validateRequest = require('../middleware/validateRequest');
const { birthdaySchema } = require('../utils/validators');

// PUT /hello/:username - Save/update user's birthday
router.put('/:username', 
  validateRequest(birthdaySchema), 
  birthdayController.updateBirthday
);

// GET /hello/:username - Get birthday message
router.get('/:username', birthdayController.getBirthdayMessage);

module.exports = router; 