import { ExecArgs } from "@medusajs/framework/types"
import { createInventoryLevelsWorkflow } from "@medusajs/medusa/core-flows"

export default async function createInventoryLevels({ container }: ExecArgs) {
  const logger = container.resolve("logger")
  const query = container.resolve("query")

  logger.info("Creating inventory levels for all products...")

  const { data: stockLocations } = await query.graph({
    entity: "stock_location",
    fields: ["id", "name"]
  })

  const { data: inventoryItems } = await query.graph({
    entity: "inventory_item",
    fields: ["id"]
  })

  if (stockLocations.length === 0) {
    logger.error("No stock locations found")
    return
  }

  if (inventoryItems.length === 0) {
    logger.error("No inventory items found")
    return
  }

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

  logger.info(`✅ Created ${inventoryLevels.length} inventory levels at ${stockLocations[0].name}`)
}
