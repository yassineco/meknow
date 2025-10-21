// API Client pour backend Express.js
// Pour SSR : utiliser l'URL interne, pour le client : utiliser l'URL publique
const getApiUrl = () => {
  // Si on est côté serveur (SSR)
  if (typeof window === 'undefined') {
    return process.env.API_URL || "http://127.0.0.1:9000";
  }
  // Si on est côté client (navigateur)  
  return process.env.NEXT_PUBLIC_API_URL || "http://localhost:9000";
};

const API_URL = getApiUrl();

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

// Fonction pour transformer les produits Express vers format Next.js
function transformExpressProduct(expressProduct: any): Product {
  const firstVariant = expressProduct.variants?.[0];
  const priceInEuros = firstVariant?.prices?.[0]?.amount ? firstVariant.prices[0].amount / 100 : 0;
  const totalStock = expressProduct.variants?.reduce((sum: number, v: any) => sum + (v.inventory_quantity || 0), 0) || 0;

  return {
    id: expressProduct.id,
    title: expressProduct.title,
    description: expressProduct.description || '',
    price: priceInEuros,
    image_url: expressProduct.thumbnail,
    thumbnail: expressProduct.thumbnail,
    images: expressProduct.thumbnail ? [{ url: expressProduct.thumbnail }] : [],
    subtitle: expressProduct.metadata?.collection || '',
    stock: totalStock,
    status: expressProduct.status || 'published',
    category: expressProduct.metadata?.collection,
    options: expressProduct.variants?.length > 0 ? [{
      values: expressProduct.variants.map((v: any) => v.title)
    }] : [],
    variants: expressProduct.variants?.map((variant: any) => ({
      id: variant.id,
      title: variant.title,
      size: variant.title,
      stock: variant.inventory_quantity || 0,
      price: variant.prices?.[0]?.amount ? variant.prices[0].amount / 100 : priceInEuros,
      option1: variant.title
    })) || []
  };
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
    if (params?.collection_id) {
      params.collection_id.forEach(id => url.searchParams.append('collection_id', id));
    }
    
    const response = await fetch(url.toString());
    if (!response.ok) throw new Error('Failed to fetch products');
    
    const data = await response.json();
    
    // L'API backend-minimal.js retourne { products: [...], count: number }
    if (Array.isArray(data.products)) {
      // Transformer les produits Express pour Next.js
      return data.products.map(transformExpressProduct);
    }
    
    // Fallback pour autres formats
    if (data.success && Array.isArray(data.products)) {
      return data.products.map(transformExpressProduct);
    }
    
    console.warn('API returned unexpected format:', data);
    return [];
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
    
    // L'API retourne { success: true, product: {...} }
    if (data.success && data.product) {
      return transformExpressProduct(data.product);
    }
    
    return null;
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
    
    // L'API Express retourne { success: true, collection: {...} }
    if (data.success && data.collection) {
      return {
        id: data.collection.id,
        name: data.collection.title,
        title: data.collection.title,
        description: data.collection.description,
        metadata: data.collection.metadata || {}
      };
    }
    
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

