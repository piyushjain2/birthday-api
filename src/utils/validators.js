const Joi = require('joi');
const moment = require('moment');

// Custom validator for date format and past date
const pastDateValidator = (value, helpers) => {
  const date = moment(value, 'YYYY-MM-DD', true);
  
  if (!date.isValid()) {
    return helpers.error('any.invalid');
  }
  
  if (date.isSameOrAfter(moment().startOf('day'))) {
    return helpers.error('date.past');
  }
  
  return value;
};

// Username must contain only letters
const usernamePattern = /^[a-zA-Z]+$/;

const birthdaySchema = Joi.object({
  dateOfBirth: Joi.date()
    .max(moment().subtract(1, 'day').toDate())
    .required()
    .messages({
      'date.max': 'Date of birth must be before today',
      'any.required': 'Date of birth is required'
    })
});

const usernameSchema = Joi.string()
  .pattern(/^[a-zA-Z]+$/)
  .required()
  .messages({
    'string.pattern.base': 'Username must contain only letters',
    'any.required': 'Username is required'
  });

module.exports = {
  birthdaySchema,
  usernameSchema
}; 