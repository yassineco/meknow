import { ExecArgs } from "@medusajs/framework/types"
import { Modules, ProductStatus } from "@medusajs/framework/utils"
import { 
  createRegionsWorkflow,
  createProductsWorkflow,
  createInventoryLevelsWorkflow,
  createCollectionsWorkflow
} from "@medusajs/medusa/core-flows"

export default async function seedMenowData({ container }: ExecArgs) {
  const logger = container.resolve("logger")
  const query = container.resolve("query")

  logger.info("🇲🇦 Starting Menow seed script...")

  // ============================================
  // 0. CREATE STOCK LOCATION IF MISSING
  // ============================================
  const stockLocationService = container.resolve(Modules.STOCK_LOCATION)
  const { data: existingLocations } = await query.graph({
    entity: "stock_location",
    fields: ["id", "name"]
  })

  if (!existingLocations || existingLocations.length === 0) {
    logger.info("Creating default stock location...")
    await stockLocationService.createStockLocations({
      name: "Entrepôt Menow Maroc",
      address: {
        address_1: "Casablanca",
        city: "Casablanca",
        country_code: "ma"
      }
    })
    logger.info("✅ Created stock location: Entrepôt Menow Maroc")
  } else {
    logger.info(`✅ Stock location exists: ${existingLocations[0].name}`)
  }

  // ============================================
  // 1. GET OR CREATE REGION FRANCE WITH EUR
  // ============================================
  logger.info("Checking for France region...")
  
  const { data: existingRegions } = await query.graph({
    entity: "region",
    fields: ["id", "name", "currency_code"],
    filters: { name: "France" }
  })

  let franceRegion
  if (existingRegions && existingRegions.length > 0) {
    franceRegion = existingRegions[0]
    logger.info(`✅ Found existing region: ${franceRegion.name} (${franceRegion.currency_code.toUpperCase()})`)
  } else {
    const { result: regions } = await createRegionsWorkflow(container).run({
      input: {
        regions: [
          {
            name: "France",
            currency_code: "eur",
            countries: ["fr"],
            automatic_taxes: true
          }
        ]
      }
    })
    franceRegion = regions[0]
    logger.info(`✅ Created new region: ${franceRegion.name} (${franceRegion.currency_code.toUpperCase()})`)
  }

  // ============================================
  // 2. GET DEFAULT SALES CHANNEL
  // ============================================
  const salesChannelService = container.resolve(Modules.SALES_CHANNEL)
  const [defaultSalesChannel] = await salesChannelService.listSalesChannels({
    name: "Default Sales Channel"
  })

  if (!defaultSalesChannel) {
    throw new Error("Default sales channel not found")
  }

  logger.info(`✅ Found sales channel: ${defaultSalesChannel.name}`)

  // ============================================
  // 3. GET OR CREATE COLLECTION "CAPSULE MENOW"
  // ============================================
  logger.info("Checking for Capsule Menow collection...")

  const { data: existingCollections } = await query.graph({
    entity: "product_collection",
    fields: ["id", "title", "handle"],
    filters: { handle: "capsule-menow" }
  })

  let capsuleCollection
  if (existingCollections && existingCollections.length > 0) {
    capsuleCollection = existingCollections[0]
    logger.info(`✅ Found existing collection: ${capsuleCollection.title}`)
  } else {
    const { result: collections } = await createCollectionsWorkflow(container).run({
      input: {
        collections: [
          {
            title: "Capsule Menow",
            handle: "capsule-menow",
            metadata: {
              description: "Collection exclusive de pièces premium fabriquées au Maroc"
            }
          }
        ]
      }
    })
    capsuleCollection = collections[0]
    logger.info(`✅ Created collection: ${capsuleCollection.title}`)
  }

  // ============================================
  // 4. CREATE 4 PREMIUM PRODUCTS
  // ============================================
  logger.info("Creating 4 premium Menow products...")

  const productsData = [
    {
      title: "Blouson Cuir Premium",
      description: "Blouson en cuir véritable tanné au Maroc. Coupe moderne et finitions artisanales. Doublure en soie.",
      handle: "blouson-cuir-premium",
      status: ProductStatus.PUBLISHED,
      collection_id: capsuleCollection.id,
      metadata: {
        material: "Cuir véritable",
        origin: "Maroc",
        care: "Nettoyage à sec uniquement"
      },
      options: [
        {
          title: "Taille",
          values: ["S", "M", "L", "XL"]
        }
      ],
      variants: [
        {
          title: "Blouson Cuir Premium - S",
          sku: "MENOW-CUIR-S",
          manage_inventory: true,
          prices: [
            { currency_code: "eur", amount: 18900 }
          ],
          options: {
            Taille: "S"
          }
        },
        {
          title: "Blouson Cuir Premium - M",
          sku: "MENOW-CUIR-M",
          manage_inventory: true,
          prices: [
            { currency_code: "eur", amount: 18900 }
          ],
          options: {
            Taille: "M"
          }
        },
        {
          title: "Blouson Cuir Premium - L",
          sku: "MENOW-CUIR-L",
          manage_inventory: true,
          prices: [
            { currency_code: "eur", amount: 18900 }
          ],
          options: {
            Taille: "L"
          }
        },
        {
          title: "Blouson Cuir Premium - XL",
          sku: "MENOW-CUIR-XL",
          manage_inventory: true,
          prices: [
            { currency_code: "eur", amount: 18900 }
          ],
          options: {
            Taille: "XL"
          }
        }
      ],
      sales_channels: [{ id: defaultSalesChannel.id }],
      images: [
        {
          url: "https://images.unsplash.com/photo-1551028719-00167b16eac5?w=800"
        }
      ]
    },
    {
      title: "Jean Denim Selvage",
      description: "Jean en denim selvage tissé traditionnellement. Coupe droite intemporelle. Teinture indigo naturelle.",
      handle: "jean-denim-selvage",
      status: ProductStatus.PUBLISHED,
      collection_id: capsuleCollection.id,
      metadata: {
        material: "Denim selvage 100% coton",
        origin: "Maroc",
        care: "Lavage à 30°C"
      },
      options: [
        {
          title: "Taille",
          values: ["S", "M", "L", "XL"]
        }
      ],
      variants: [
        {
          title: "Jean Denim Selvage - S",
          sku: "MENOW-DENIM-S",
          manage_inventory: true,
          prices: [
            { currency_code: "eur", amount: 12900 }
          ],
          options: {
            Taille: "S"
          }
        },
        {
          title: "Jean Denim Selvage - M",
          sku: "MENOW-DENIM-M",
          manage_inventory: true,
          prices: [
            { currency_code: "eur", amount: 12900 }
          ],
          options: {
            Taille: "M"
          }
        },
        {
          title: "Jean Denim Selvage - L",
          sku: "MENOW-DENIM-L",
          manage_inventory: true,
          prices: [
            { currency_code: "eur", amount: 12900 }
          ],
          options: {
            Taille: "L"
          }
        },
        {
          title: "Jean Denim Selvage - XL",
          sku: "MENOW-DENIM-XL",
          manage_inventory: true,
          prices: [
            { currency_code: "eur", amount: 12900 }
          ],
          options: {
            Taille: "XL"
          }
        }
      ],
      sales_channels: [{ id: defaultSalesChannel.id }],
      images: [
        {
          url: "https://images.unsplash.com/photo-1542272604-787c3835535d?w=800"
        }
      ]
    },
    {
      title: "Chemise Lin Naturel",
      description: "Chemise en lin naturel européen. Tissage aéré parfait pour l'été. Col italien et manches longues.",
      handle: "chemise-lin-naturel",
      status: ProductStatus.PUBLISHED,
      collection_id: capsuleCollection.id,
      metadata: {
        material: "Lin 100% naturel",
        origin: "Maroc",
        care: "Lavage à 40°C, repassage lin"
      },
      options: [
        {
          title: "Taille",
          values: ["S", "M", "L", "XL"]
        }
      ],
      variants: [
        {
          title: "Chemise Lin Naturel - S",
          sku: "MENOW-LIN-S",
          manage_inventory: true,
          prices: [
            { currency_code: "eur", amount: 8900 }
          ],
          options: {
            Taille: "S"
          }
        },
        {
          title: "Chemise Lin Naturel - M",
          sku: "MENOW-LIN-M",
          manage_inventory: true,
          prices: [
            { currency_code: "eur", amount: 8900 }
          ],
          options: {
            Taille: "M"
          }
        },
        {
          title: "Chemise Lin Naturel - L",
          sku: "MENOW-LIN-L",
          manage_inventory: true,
          prices: [
            { currency_code: "eur", amount: 8900 }
          ],
          options: {
            Taille: "L"
          }
        },
        {
          title: "Chemise Lin Naturel - XL",
          sku: "MENOW-LIN-XL",
          manage_inventory: true,
          prices: [
            { currency_code: "eur", amount: 8900 }
          ],
          options: {
            Taille: "XL"
          }
        }
      ],
      sales_channels: [{ id: defaultSalesChannel.id }],
      images: [
        {
          url: "https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=800"
        }
      ]
    },
    {
      title: "T-Shirt Coton Bio",
      description: "T-shirt en coton biologique certifié GOTS. Coupe classique et col rond. Impression sérigraphie artisanale.",
      handle: "tshirt-coton-bio",
      status: ProductStatus.PUBLISHED,
      collection_id: capsuleCollection.id,
      metadata: {
        material: "Coton bio certifié GOTS",
        origin: "Maroc",
        care: "Lavage à 30°C"
      },
      options: [
        {
          title: "Taille",
          values: ["S", "M", "L", "XL"]
        }
      ],
      variants: [
        {
          title: "T-Shirt Coton Bio - S",
          sku: "MENOW-COTON-S",
          manage_inventory: true,
          prices: [
            { currency_code: "eur", amount: 4500 }
          ],
          options: {
            Taille: "S"
          }
        },
        {
          title: "T-Shirt Coton Bio - M",
          sku: "MENOW-COTON-M",
          manage_inventory: true,
          prices: [
            { currency_code: "eur", amount: 4500 }
          ],
          options: {
            Taille: "M"
          }
        },
        {
          title: "T-Shirt Coton Bio - L",
          sku: "MENOW-COTON-L",
          manage_inventory: true,
          prices: [
            { currency_code: "eur", amount: 4500 }
          ],
          options: {
            Taille: "L"
          }
        },
        {
          title: "T-Shirt Coton Bio - XL",
          sku: "MENOW-COTON-XL",
          manage_inventory: true,
          prices: [
            { currency_code: "eur", amount: 4500 }
          ],
          options: {
            Taille: "XL"
          }
        }
      ],
      sales_channels: [{ id: defaultSalesChannel.id }],
      images: [
        {
          url: "https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=800"
        }
      ]
    }
  ]

  await createProductsWorkflow(container).run({
    input: {
      products: productsData
    }
  })

  logger.info(`✅ Created ${productsData.length} products with variants`)

  // ============================================
  // 5. CREATE INVENTORY LEVELS (STOCK)
  // ============================================
  logger.info("Setting up inventory levels...")

  const { data: stockLocations } = await query.graph({
    entity: "stock_location",
    fields: ["id", "name"]
  })

  const { data: inventoryItems } = await query.graph({
    entity: "inventory_item",
    fields: ["id"]
  })

  if (stockLocations.length === 0) {
    logger.warn("⚠️ No stock locations found. Inventory levels not created.")
  } else {
    const inventoryLevels = inventoryItems.map((inventoryItem) => ({
      location_id: stockLocations[0].id,
      stocked_quantity: 100,
      inventory_item_id: inventoryItem.id
    }))

    await createInventoryLevelsWorkflow(container).run({
      input: {
        inventory_levels: inventoryLevels
      }
    })

    logger.info(`✅ Set inventory to 100 units per variant at ${stockLocations[0].name}`)
  }

  // ============================================
  // SUMMARY
  // ============================================
  logger.info("")
  logger.info("🎉 MENOW SEED COMPLETED SUCCESSFULLY!")
  logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
  logger.info("✅ 1 Region: France (EUR)")
  logger.info("✅ 1 Collection: Capsule Menow")
  logger.info("✅ 4 Products: Cuir, Denim, Lin, Coton Bio")
  logger.info("✅ 16 Variants: 4 sizes per product (S, M, L, XL)")
  logger.info("✅ Payment: Manual/COD enabled")
  logger.info("✅ Stock: 100 units per variant")
  logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
  logger.info("")
  logger.info("🚀 Next steps:")
  logger.info("1. Create admin user: npx medusa user -e admin@menow.fr -p menow2025")
  logger.info("2. Start dev server: npm run dev")
  logger.info("3. Open admin: http://localhost:9000/app")
  logger.info("")
}
