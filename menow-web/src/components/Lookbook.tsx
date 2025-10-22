import Image from "next/image";
import { getImageUrl } from "@/lib/utils";

// Fonction pour récupérer les produits lookbook depuis l'API
async function getLookbookProducts() {
  try {
    const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://127.0.0.1:9000";
    const response = await fetch(`${API_URL}/api/products/lookbook`, {
      cache: 'no-store',
      next: { revalidate: 0 }
    });
    
    if (!response.ok) {
      console.error('Erreur récupération lookbook:', response.status);
      return [];
    }
    
    const data = await response.json();
    return Array.isArray(data.products) ? data.products : [];
  } catch (error) {
    console.error('Erreur récupération lookbook:', error);
    return [];
  }
}

export default async function Lookbook() {
  const lookbookProducts = await getLookbookProducts();

  // Fallback image si le produit n'a pas d'image
  const fallbackImage = "https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800&q=80";

  return (
    <section className="section bg-bg-secondary">
      <div className="container">
        <div className="text-center mb-12">
          <h2 className="font-display text-4xl md:text-5xl font-bold text-text-primary mb-4">
            Lookbook
          </h2>
          <p className="text-text-secondary text-lg">
            Découvrez l'univers Meknow
          </p>
        </div>

        <div className="grid grid--3">
          {lookbookProducts.length > 0 ? (
            lookbookProducts.map((product: any) => {
              const imageUrl = getImageUrl(product.thumbnail) || fallbackImage;
              return (
                <div key={product.id} className="card group cursor-pointer">
                  <div className="card__image-wrapper aspect-square">
                    <Image
                      src={imageUrl}
                      alt={product.title}
                      fill
                      className="card__image object-cover"
                      sizes="(max-width: 768px) 100vw, 33vw"
                    />
                    <div className="card__overlay">
                      <div className="text-center">
                        <h3 className="font-display text-2xl font-bold text-text-primary mb-2">
                          {product.title}
                        </h3>
                        <p className="text-accent">{product.metadata?.collection || ""}</p>
                        <p className="text-text-secondary text-sm mt-2">
                          {product.description}
                        </p>
                      </div>
                    </div>
                  </div>
                </div>
              );
            })
          ) : (
            <div className="col-span-3 text-center py-8">
              <p className="text-text-secondary">Aucun produit Lookbook disponible pour le moment.</p>
            </div>
          )}
        </div>
      </div>
    </section>
  );
}
