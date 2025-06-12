const moment = require('moment');
const userModel = require('../models/userModel');
const logger = require('../utils/logger');

const saveOrUpdateUser = async (username, dateOfBirth) => {
  try {
    // Check if user exists
    const existingUser = await userModel.findByUsername(username);
    
    if (existingUser) {
      // Update existing user
      await userModel.updateUser(username, dateOfBirth);
      logger.info(`Updated birthday for existing user: ${username}`);
    } else {
      // Create new user
      await userModel.createUser(username, dateOfBirth);
      logger.info(`Created new user: ${username}`);
    }
  } catch (error) {
    logger.error('Error in saveOrUpdateUser:', error);
    throw error;
  }
};

const getBirthdayMessage = async (username) => {
  try {
    const user = await userModel.findByUsername(username);
    
    if (!user) {
      return null;
    }
    
    const today = moment().startOf('day');
    const birthday = moment(user.date_of_birth);
    const thisYearBirthday = moment(birthday).year(today.year());
    
    // If birthday has passed this year, calculate for next year
    if (thisYearBirthday.isBefore(today)) {
      thisYearBirthday.add(1, 'year');
    }
    
    const daysUntilBirthday = thisYearBirthday.diff(today, 'days');
    
    if (daysUntilBirthday === 0) {
      return `Hello, ${username}! Happy birthday!`;
    } else {
      return `Hello, ${username}! Your birthday is in ${daysUntilBirthday} day(s)`;
    }
  } catch (error) {
    logger.error('Error in getBirthdayMessage:', error);
    throw error;
  }
};

module.exports = {
  saveOrUpdateUser,
  getBirthdayMessage
}; 