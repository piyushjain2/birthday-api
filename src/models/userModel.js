const { getWritePool, getReadPool } = require('../config/database');

const createUser = async (username, dateOfBirth) => {
  const pool = getWritePool();
  const query = `
    INSERT INTO users (username, date_of_birth)
    VALUES ($1, $2)
    RETURNING *
  `;
  const values = [username, dateOfBirth];
  
  const result = await pool.query(query, values);
  return result.rows[0];
};

const updateUser = async (username, dateOfBirth) => {
  const pool = getWritePool();
  const query = `
    UPDATE users 
    SET date_of_birth = $2
    WHERE username = $1
    RETURNING *
  `;
  const values = [username, dateOfBirth];
  
  const result = await pool.query(query, values);
  return result.rows[0];
};

const findByUsername = async (username) => {
  const pool = getReadPool();
  const query = `
    SELECT * FROM users 
    WHERE username = $1
  `;
  const values = [username];
  
  const result = await pool.query(query, values);
  return result.rows[0] || null;
};

const findAll = async (limit = 100, offset = 0) => {
  const pool = getReadPool();
  const query = `
    SELECT * FROM users 
    ORDER BY created_at DESC
    LIMIT $1 OFFSET $2
  `;
  const values = [limit, offset];
  
  const result = await pool.query(query, values);
  return result.rows;
};

module.exports = {
  createUser,
  updateUser,
  findByUsername,
  findAll
}; 