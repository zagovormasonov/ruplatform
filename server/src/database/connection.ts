import { Pool } from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://gen_user:OCS(ifoR||A5$~@40e0a3b39459bee0b2e47359.twc1.net:5432/default_db',
  ssl: {
    rejectUnauthorized: false
  }
});

export default pool;
