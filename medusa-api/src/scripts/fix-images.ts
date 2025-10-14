import { initialize } from "@medusajs/medusa"

export default async function () {
  console.log("🖼️ Starting image fix script...")

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
  ]

  const container = await initialize()
  const productModule = container.resolve("productService")

  for (const productUpdate of imageUpdates) {
    try {
      logger.info(`📦 Processing: ${productUpdate.handle}`)

      // Find product by handle
      const products = await productService.listProducts({
        handle: [productUpdate.handle]
      })

      if (products.length === 0) {
        logger.warn(`⚠️ Product not found: ${productUpdate.handle}`)
        continue
      }

      const product = products[0]
      logger.info(`📦 Found product: ${product.title}`)

      // Update product with new thumbnail and image
      await productService.updateProducts(
        product.id,
        {
          thumbnail: productUpdate.newImageUrl,
          images: [
            {
              url: productUpdate.newImageUrl,
              rank: 0
            }
          ]
        }
      )

      logger.info(`✅ Updated ${product.title} with image: ${productUpdate.newImageUrl}`)

    } catch (error) {
      logger.error(`❌ Error updating ${productUpdate.handle}:`, error)
    }
  }

  logger.info("🎉 Image fix completed!")
  logger.info("� Note: Images are now using local paths starting with /products/")
}