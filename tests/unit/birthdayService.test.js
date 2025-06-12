const moment = require('moment');
const birthdayService = require('../../src/services/birthdayService');
const userModel = require('../../src/models/userModel');

// Mock dependencies
jest.mock('../../src/models/userModel');
jest.mock('../../src/utils/logger');

describe('Birthday Service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('saveOrUpdateUser', () => {
    it('should create a new user if user does not exist', async () => {
      userModel.findByUsername.mockResolvedValue(null);
      userModel.createUser.mockResolvedValue({ id: 1, username: 'john', date_of_birth: '1990-01-01' });

      await birthdayService.saveOrUpdateUser('john', '1990-01-01');

      expect(userModel.findByUsername).toHaveBeenCalledWith('john');
      expect(userModel.createUser).toHaveBeenCalledWith('john', '1990-01-01');
      expect(userModel.updateUser).not.toHaveBeenCalled();
    });

    it('should update existing user if user exists', async () => {
      userModel.findByUsername.mockResolvedValue({ id: 1, username: 'john', date_of_birth: '1990-01-01' });
      userModel.updateUser.mockResolvedValue({ id: 1, username: 'john', date_of_birth: '1991-01-01' });

      await birthdayService.saveOrUpdateUser('john', '1991-01-01');

      expect(userModel.findByUsername).toHaveBeenCalledWith('john');
      expect(userModel.updateUser).toHaveBeenCalledWith('john', '1991-01-01');
      expect(userModel.createUser).not.toHaveBeenCalled();
    });

    it('should throw error if database operation fails', async () => {
      userModel.findByUsername.mockRejectedValue(new Error('Database error'));

      await expect(birthdayService.saveOrUpdateUser('john', '1990-01-01'))
        .rejects.toThrow('Database error');
    });
  });

  describe('getBirthdayMessage', () => {
    it('should return null if user not found', async () => {
      userModel.findByUsername.mockResolvedValue(null);

      const result = await birthdayService.getBirthdayMessage('john');

      expect(result).toBeNull();
    });

    it('should return happy birthday message if birthday is today', async () => {
      const today = moment().format('YYYY-MM-DD');
      const birthYear = moment().subtract(25, 'years').format('YYYY');
      const birthday = today.substring(5); // MM-DD
      
      userModel.findByUsername.mockResolvedValue({
        username: 'john',
        date_of_birth: `${birthYear}-${birthday}`
      });

      const result = await birthdayService.getBirthdayMessage('john');

      expect(result).toBe('Hello, john! Happy birthday!');
    });

    it('should return days until birthday message', async () => {
      const futureDate = moment().add(5, 'days');
      const birthYear = moment().subtract(25, 'years').format('YYYY');
      const birthday = futureDate.format('MM-DD');
      
      userModel.findByUsername.mockResolvedValue({
        username: 'john',
        date_of_birth: `${birthYear}-${birthday}`
      });

      const result = await birthdayService.getBirthdayMessage('john');

      expect(result).toBe('Hello, john! Your birthday is in 5 day(s)');
    });

    it('should calculate days until next year birthday if birthday passed', async () => {
      const pastDate = moment().subtract(5, 'days');
      const birthYear = moment().subtract(25, 'years').format('YYYY');
      const birthday = pastDate.format('MM-DD');
      
      userModel.findByUsername.mockResolvedValue({
        username: 'john',
        date_of_birth: `${birthYear}-${birthday}`
      });

      const result = await birthdayService.getBirthdayMessage('john');

      expect(result).toMatch(/Hello, john! Your birthday is in \d+ day\(s\)/);
      
      // Verify it's calculating for next year
      const daysMatch = result.match(/in (\d+) day/);
      const days = parseInt(daysMatch[1]);
      expect(days).toBeGreaterThan(300); // Should be more than 300 days
    });
  });
}); 