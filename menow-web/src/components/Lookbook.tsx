import Image from "next/image";
import { getProducts } from "@/lib/api";

export default async function Lookbook() {
  // 🎯 Récupérer les produits du lookbook via l'API
  let lookbookData;
  try {
    const response = await fetch(`${process.env.API_URL}/api/products/lookbook`, {
      cache: 'no-store' // Pas de cache pour avoir les données temps réel
    });
    lookbookData = await response.json();
  } catch (error) {
    console.error('Erreur récupération lookbook:', error);
    // Fallback vers les images statiques si API indisponible
    lookbookData = { grouped: {} };
  }

  // Transformation des catégories lookbook en format d'affichage
  const lookbookSections = [
    {
      key: "collection-premium",
      title: "Collection Premium", 
      subtitle: "Cuirs d'exception",
      fallbackImage: "https://images.unsplash.com/photo-1594633313593-bab3825d0caf?w=800"
    },
    {
      key: "savoir-faire-artisanal", 
      title: "Savoir-faire artisanal",
      subtitle: "Made in Morocco",
      fallbackImage: "https://images.unsplash.com/photo-1520975867597-0af37a22e31a?w=800"
    },
    {
      key: "style-contemporain",
      title: "Style contemporain", 
      subtitle: "Design intemporel",
      fallbackImage: "https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=800"
    }
  ];

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
          {lookbookSections.map((section) => {
            // Récupérer les produits de cette catégorie lookbook
            const categoryProducts = lookbookData.grouped?.[section.key] || [];
            const featuredProduct = categoryProducts[0]; // Premier produit de la catégorie
            
            // Image à utiliser (produit réel ou fallback)
            const imageUrl = featuredProduct 
              ? `${process.env.NEXT_PUBLIC_API_URL}${featuredProduct.thumbnail}`
              : section.fallbackImage;

            return (
              <div key={section.key} className="card group cursor-pointer">
                <div className="card__image-wrapper aspect-square">
                  <Image
                    src={imageUrl}
                    alt={section.title}
                    fill
                    className="card__image object-cover"
                    sizes="(max-width: 768px) 100vw, 33vw"
                  />
                  <div className="card__overlay">
                    <div className="text-center">
                      <h3 className="font-display text-2xl font-bold text-text-primary mb-2">
                        {section.title}
                      </h3>
                      <p className="text-accent">
                        {featuredProduct ? featuredProduct.title : section.subtitle}
                      </p>
                      {categoryProducts.length > 0 && (
                        <p className="text-text-secondary text-sm mt-2">
                          {categoryProducts.length} produit{categoryProducts.length > 1 ? 's' : ''}
                        </p>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
