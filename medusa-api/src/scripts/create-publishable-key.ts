import { ExecArgs } from "@medusajs/framework/types"
import { Modules } from "@medusajs/framework/utils"

export default async function createPublishableKey({ container }: ExecArgs) {
  const logger = container.resolve("logger")
  const query = container.resolve("query")
  const remoteLink = container.resolve("remoteLink")

  logger.info("Creating publishable API key and associating with sales channel...")

  const apiKeyModuleService = container.resolve(Modules.API_KEY)
  const salesChannelService = container.resolve(Modules.SALES_CHANNEL)

  const { data: existingKeys } = await query.graph({
    entity: "api_key",
    fields: ["id", "title", "token"],
    filters: { type: "publishable" }
  })

  let apiKey
  if (existingKeys && existingKeys.length > 0) {
    apiKey = existingKeys[0]
    logger.info(`✅ Publishable API key already exists: ${apiKey.token}`)
  } else {
    apiKey = await apiKeyModuleService.createApiKeys({
      title: "Menow Storefront Key",
      type: "publishable",
      created_by: "admin"
    })
    logger.info(`✅ Publishable API key created: ${apiKey.token}`)
  }

  const [defaultSalesChannel] = await salesChannelService.listSalesChannels({
    name: "Default Sales Channel"
  })

  if (!defaultSalesChannel) {
    logger.error("Default sales channel not found")
    return
  }

  const { data: existingLinks } = await query.graph({
    entity: "publishable_api_key_sales_channel",
    fields: ["id"],
    filters: { 
      publishable_key_id: apiKey.id,
      sales_channel_id: defaultSalesChannel.id
    }
  })

  if (!existingLinks || existingLinks.length === 0) {
    await remoteLink.create({
      publishable_api_key: {
        publishable_api_key_id: apiKey.id
      },
      sales_channel: {
        sales_channel_id: defaultSalesChannel.id
      }
    })
    logger.info(`✅ Associated with sales channel: ${defaultSalesChannel.name}`)
  } else {
    logger.info(`✅ Already associated with sales channel: ${defaultSalesChannel.name}`)
  }
  logger.info("")
  logger.info("Add this to your frontend .env.local:")
  logger.info(`NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY=${apiKey.token}`)
  logger.info("")
}
