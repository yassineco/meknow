#!/usr/bin/env node

// Script simple pour corriger les images via l'API REST
const axios = require('axios');

const baseURL = 'http://localhost:9000';
const adminEmail = 'admin@medusa.com';
const adminPassword = 'admin123';

// Mapping des nouveaux URLs d'images locales
const imageUpdates = [
  {
    handle: "blouson-cuir-premium",
    newImageUrl: "/products/luxury_fashion_jacke_28fde759.jpg"
  },
  {
    handle: "jean-denim-selvage", 
    newImageUrl: "/products/luxury_fashion_jacke_45c6de81.jpg"
  },
  {
    handle: "chemise-lin-naturel",
    newImageUrl: "/products/premium_fashion_coll_0e2672aa.jpg"
  },
  {
    handle: "tshirt-coton-bio",
    newImageUrl: "/products/premium_fashion_coll_55d86770.jpg"
  }
];

async function fixImages() {
  console.log("🖼️ Starting image fix script...");

  try {
    // 1. Login admin
    console.log("🔐 Authenticating admin...");
    const authResponse = await axios.post(`${baseURL}/admin/auth/session`, {
      email: adminEmail,
      password: adminPassword
    });
    
    const sessionCookie = authResponse.headers['set-cookie']?.[0];
    if (!sessionCookie) {
      throw new Error('No session cookie received');
    }

    console.log("✅ Authentication successful");

    const headers = {
      'Cookie': sessionCookie,
      'Content-Type': 'application/json'
    };

    // 2. Get all products
    console.log("📦 Fetching products...");
    const productsResponse = await axios.get(`${baseURL}/admin/products`, { headers });
    const products = productsResponse.data.products;

    console.log(`Found ${products.length} products`);

    // 3. Update each product
    for (const productUpdate of imageUpdates) {
      try {
        console.log(`📦 Processing: ${productUpdate.handle}`);

        // Find product by handle
        const product = products.find(p => p.handle === productUpdate.handle);
        
        if (!product) {
          console.warn(`⚠️ Product not found: ${productUpdate.handle}`);
          continue;
        }

        console.log(`📦 Found product: ${product.title}`);

        // Update product with new thumbnail
        const updateData = {
          thumbnail: productUpdate.newImageUrl,
          images: [
            {
              url: productUpdate.newImageUrl
            }
          ]
        };

        await axios.post(`${baseURL}/admin/products/${product.id}`, updateData, { headers });

        console.log(`✅ Updated ${product.title} with image: ${productUpdate.newImageUrl}`);

      } catch (error) {
        console.error(`❌ Error updating ${productUpdate.handle}:`, error.response?.data || error.message);
      }
    }

    console.log("🎉 Image fix completed!");
    console.log("📝 Note: Images are now using local paths starting with /products/");

  } catch (error) {
    console.error("❌ Script failed:", error.response?.data || error.message);
    process.exit(1);
  }
}

fixImages();