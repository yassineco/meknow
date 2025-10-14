const dotenv = require("dotenv");

let ENV_FILE_NAME = "";
switch (process.env.NODE_ENV) {
  case "production":
    ENV_FILE_NAME = ".env.production";
    break;
  case "staging":
    ENV_FILE_NAME = ".env.staging";
    break;
  case "test":
    ENV_FILE_NAME = ".env.test";
    break;
  case "development":
  default:
    ENV_FILE_NAME = ".env";
    break;
}

try {
  dotenv.config({ path: process.cwd() + "/" + ENV_FILE_NAME });
} catch (e) {}

const DATABASE_URL = process.env.DATABASE_URL || "postgresql://localhost/menow_dev";
const REDIS_URL = process.env.REDIS_URL || "";
const STORE_CORS = process.env.STORE_CORS || "http://localhost:3000";
const ADMIN_CORS = process.env.ADMIN_CORS || "http://localhost:7000,http://localhost:7001";

const plugins = [
  `medusa-fulfillment-manual`,
  `medusa-payment-manual`,
  {
    resolve: `@medusajs/file-local`,
    options: {
      upload_dir: "uploads",
    },
  },
  {
    resolve: "@medusajs/admin",
    options: {
      autoRebuild: true,
      develop: {
        open: process.env.OPEN_BROWSER !== "false",
      },
    },
  },
];

if (REDIS_URL) {
  plugins.push({
    resolve: `@medusajs/cache-redis`,
    options: {
      redisUrl: REDIS_URL,
      ttl: 30,
    },
  });
} else {
  plugins.push({
    resolve: `@medusajs/cache-inmemory`,
  });
}

const modules = {
  eventBus: REDIS_URL
    ? {
        resolve: "@medusajs/event-bus-redis",
        options: {
          redisUrl: REDIS_URL,
        },
      }
    : {
        resolve: "@medusajs/event-bus-local",
      },
};

module.exports = {
  projectConfig: {
    jwt_secret: process.env.JWT_SECRET || "supersecret",
    cookie_secret: process.env.COOKIE_SECRET || "supersecret",
    store_cors: STORE_CORS,
    admin_cors: ADMIN_CORS,
    database_url: DATABASE_URL,
    database_type: "postgres",
    redis_url: REDIS_URL,
  },
  plugins,
  modules,
  featureFlags: {
    product_categories: false,
  },
};
