const birthdayService = require('../services/birthdayService');
const logger = require('../utils/logger');

const updateBirthday = async (req, res, next) => {
  try {
    const { username } = req.params;
    const { dateOfBirth } = req.body;

    await birthdayService.saveOrUpdateUser(username, dateOfBirth);
    
    logger.info(`Birthday updated for user: ${username}`);
    res.status(204).send();
  } catch (error) {
    logger.error('Error updating birthday:', error);
    next(error);
  }
};

const getBirthdayMessage = async (req, res, next) => {
  try {
    const { username } = req.params;
    
    const message = await birthdayService.getBirthdayMessage(username);
    
    if (!message) {
      return res.status(404).json({ 
        error: 'User not found' 
      });
    }
    
    res.status(200).json({ message });
  } catch (error) {
    logger.error('Error getting birthday message:', error);
    next(error);
  }
};

module.exports = {
  updateBirthday,
  getBirthdayMessage
}; 