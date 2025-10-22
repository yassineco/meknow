#!/usr/bin/env node

/**
 * MIGRATION SCRIPT: File-based JSON → PostgreSQL
 * 
 * Ce script migre les produits stockés en JSON vers PostgreSQL
 * Utilisation: node migrate-to-postgres.js
 */

const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

// Configuration PostgreSQL
const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'meknow_production',
});

// Chemin du fichier JSON existant
const PRODUCTS_FILE = path.join(__dirname, 'products-data.json');

/**
 * Créer la table products_data si elle n'existe pas
 */
async function createProductsTable() {
  console.log('🔧 Creating products_data table if not exists...');
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS products_data (
        id SERIAL PRIMARY KEY,
        products JSONB NOT NULL,
        collections JSONB DEFAULT '[]'::jsonb,
        version INTEGER DEFAULT 1,
        last_modified_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(version)
      );
      
      CREATE INDEX IF NOT EXISTS idx_products_data_version ON products_data(version);
      CREATE INDEX IF NOT EXISTS idx_products_data_modified ON products_data(last_modified_at);
    `);
    console.log('✅ Table products_data created or already exists');
  } catch (error) {
    console.error('❌ Error creating table:', error.message);
    throw error;
  }
}

/**
 * Vérifier si la table contient déjà des données
 */
async function hasExistingData() {
  try {
    const result = await pool.query('SELECT COUNT(*) as count FROM products_data WHERE products::text != \'[]\'');
    return result.rows[0].count > 0;
  } catch (error) {
    console.log('ℹ️ No existing data found in products_data table');
    return false;
  }
}

/**
 * Lire les produits depuis le fichier JSON
 */
function readProductsFromFile() {
  try {
    if (fs.existsSync(PRODUCTS_FILE)) {
      const data = fs.readFileSync(PRODUCTS_FILE, 'utf8');
      const products = JSON.parse(data);
      console.log(`📂 Read ${products.length} products from ${PRODUCTS_FILE}`);
      return products;
    }
  } catch (error) {
    console.log('⚠️ Error reading JSON file:', error.message);
  }
  return null;
}

/**
 * Insérer les produits dans PostgreSQL
 */
async function insertProducts(products) {
  try {
    const result = await pool.query(
      `INSERT INTO products_data (products, collections, version, last_modified_at)
       VALUES ($1, $2, 1, CURRENT_TIMESTAMP)
       RETURNING *`,
      [JSON.stringify(products), '[]']
    );
    console.log('✅ Products inserted into PostgreSQL');
    return result.rows[0];
  } catch (error) {
    console.error('❌ Error inserting products:', error.message);
    throw error;
  }
}

/**
 * Vérifier la connexion à PostgreSQL
 */
async function testConnection() {
  try {
    const result = await pool.query('SELECT NOW()');
    console.log('✅ PostgreSQL connected:', result.rows[0].now);
  } catch (error) {
    console.error('❌ PostgreSQL connection failed:', error.message);
    throw error;
  }
}

/**
 * Main migration function
 */
async function migrate() {
  console.log('🚀 Starting migration process...\n');
  
  try {
    // 1. Test connection
    console.log('Step 1: Testing PostgreSQL connection');
    await testConnection();
    console.log('');
    
    // 2. Create table
    console.log('Step 2: Creating products_data table');
    await createProductsTable();
    console.log('');
    
    // 3. Check for existing data
    console.log('Step 3: Checking for existing data in PostgreSQL');
    const hasData = await hasExistingData();
    console.log('');
    
    if (hasData) {
      console.log('✅ Products already exist in PostgreSQL, skipping migration');
      console.log('');
    } else {
      // 4. Read from JSON file
      console.log('Step 4: Reading products from JSON file');
      const products = readProductsFromFile();
      console.log('');
      
      if (products && products.length > 0) {
        // 5. Insert into PostgreSQL
        console.log('Step 5: Inserting products into PostgreSQL');
        const inserted = await insertProducts(products);
        console.log(`✅ Migration complete: ${products.length} products migrated`);
        console.log('');
      } else {
        console.log('⚠️ No products found to migrate');
        console.log('');
      }
    }
    
    console.log('🎉 Migration process finished successfully!');
    console.log('');
    
  } catch (error) {
    console.error('\n❌ Migration failed:', error.message);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

// Run migration
migrate();
