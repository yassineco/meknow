// API Client pour backend Express.js
const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8080";

// Types simples pour les produits
export interface Product {
  id: string;
  title: string;
  description: string;
  price: number;
  image_url?: string;
  thumbnail?: string;
  images?: Array<{ url: string }>;
  subtitle?: string;
  stock: number;
  status: string;
  category?: string;
  options?: Array<{
    values: string[];
  }>;
  variants?: Array<{
    id: string;
    title: string;
    size: string;
    stock: number;
    price: number;
    option1: string;
  }>;
}

export interface Collection {
  id: string;
  name: string;
  title: string;
  description?: string;
  metadata?: {
    description?: string;
  };
  products?: Product[];
}

// Fonctions d'API
export async function getProducts(params?: { 
  limit?: number; 
  offset?: number;
  collection_id?: string[];
  category?: string;
}): Promise<Product[]> {
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

// Fonction pour obtenir l'URL des images
export function getImageUrl(imageUrl?: string): string {
  if (!imageUrl) {
    return '/placeholder.png'; // Image par défaut
  }
  
  // Si l'URL est relative, ajouter le base URL
  if (imageUrl.startsWith('/')) {
    return `${process.env.NEXT_PUBLIC_BASE_URL || ''}${imageUrl}`;
  }
  
  return imageUrl;
}

