import Medusa from "@medusajs/js-sdk";

const MEDUSA_URL = process.env.NEXT_PUBLIC_MEDUSA_URL || "http://localhost:9000";
const PUBLISHABLE_KEY = process.env.NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY!;

export const medusaClient = new Medusa({ 
  baseUrl: MEDUSA_URL, 
  publishableKey: PUBLISHABLE_KEY,
  debug: process.env.NODE_ENV === "development"
});

export async function getProducts(params?: any) {
  try {
    const { products } = await medusaClient.store.product.list(params);
    return products;
  } catch (error) {
    console.error("Error fetching products:", error);
    return [];
  }
}

export async function getProduct(handle: string) {
  try {
    const { products } = await medusaClient.store.product.list({ handle });
    return products[0] || null;
  } catch (error) {
    console.error(`Error fetching product ${handle}:`, error);
    return null;
  }
}

export async function getCollections() {
  try {
    const { collections } = await medusaClient.store.collection.list();
    return collections;
  } catch (error) {
    console.error("Error fetching collections:", error);
    return [];
  }
}

export async function getCollection(handle: string) {
  try {
    const { collections } = await medusaClient.store.collection.list({ handle: [handle] });
    return collections[0] || null;
  } catch (error) {
    console.error(`Error fetching collection ${handle}:`, error);
    return null;
  }
}

export async function createCart() {
  try {
    const { cart } = await medusaClient.store.cart.create({});
    return cart;
  } catch (error) {
    console.error("Error creating cart:", error);
    return null;
  }
}

export async function addToCart(cartId: string, variantId: string, quantity: number = 1) {
  try {
    const { cart } = await medusaClient.store.cart.createLineItem(cartId, {
      variant_id: variantId,
      quantity,
    });
    return cart;
  } catch (error) {
    console.error("Error adding to cart:", error);
    return null;
  }
}

export function formatPrice(amount: number, currencyCode: string = "EUR"): string {
  return new Intl.NumberFormat("fr-FR", {
    style: "currency",
    currency: currencyCode,
  }).format(amount / 100);
}
