// API Client pour backend Express.js
const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:9000";

// Types simples pour les produits
export interface Product {
  id: number;
  title: string;
  description: string;
  price: number;
  image_url?: string;
  stock: number;
  status: string;
  variants?: Array<{
    size: string;
    stock: number;
  }>;
}

export interface Collection {
  id: number;
  name: string;
  description?: string;
  products?: Product[];
}

// Fonctions d'API
export async function getProducts(params?: { limit?: number; offset?: number }): Promise<Product[]> {
  try {
    const url = new URL(`${API_URL}/api/products`);
    if (params?.limit) url.searchParams.append('limit', params.limit.toString());
    if (params?.offset) url.searchParams.append('offset', params.offset.toString());
    
    const response = await fetch(url.toString());
    if (!response.ok) throw new Error('Failed to fetch products');
    
    const data = await response.json();
    return data;
  } catch (error) {
    console.error('Error fetching products:', error);
    return [];
  }
}

export async function getProduct(handle: string): Promise<Product | null> {
  try {
    const response = await fetch(`${API_URL}/api/products/${handle}`);
    if (!response.ok) return null;
    
    const data = await response.json();
    return data;
  } catch (error) {
    console.error('Error fetching product:', error);
    return null;
  }
}

export async function getCollections(): Promise<Collection[]> {
  try {
    const response = await fetch(`${API_URL}/api/collections`);
    if (!response.ok) throw new Error('Failed to fetch collections');
    
    const data = await response.json();
    return data;
  } catch (error) {
    console.error('Error fetching collections:', error);
    return [];
  }
}

export async function getCollection(handle: string): Promise<Collection | null> {
  try {
    const response = await fetch(`${API_URL}/api/collections/${handle}`);
    if (!response.ok) return null;
    
    const data = await response.json();
    return data;
  } catch (error) {
    console.error('Error fetching collection:', error);
    return null;
  }
}

// Fonction pour formater les prix
export function formatPrice(price: number): string {
  return new Intl.NumberFormat('fr-FR', {
    style: 'currency',
    currency: 'EUR',
  }).format(price);
}