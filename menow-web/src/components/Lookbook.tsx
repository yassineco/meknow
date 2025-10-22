import Image from "next/image";

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

  // Transformation des catégories lookbook en format d'affichage
  const lookbookSections = [
    {
      key: "collection-premium",
      title: "Collection Premium", 
      subtitle: "Cuirs d'exception",
      fallbackImage: "https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800&q=80"
    },
    {
      key: "savoir-faire-artisanal", 
      title: "Savoir-faire artisanal",
      subtitle: "Made in Morocco",
      fallbackImage: "https://images.unsplash.com/photo-1434389677669-e08b4cac3105?w=800&q=80"
    },
    {
      key: "style-contemporain",
      title: "Style contemporain", 
      subtitle: "Design intemporel",
      fallbackImage: "https://images.unsplash.com/photo-1483985988355-763728e1935b?w=800&q=80"
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
          {lookbookSections.map((section, i) => {
            // Chercher un produit pour cette catégorie lookbook
            const sectionProduct = lookbookProducts.find(
              product => product.lookbook_category === section.key
            );
            
            const imageUrl = sectionProduct?.thumbnail || section.fallbackImage;
            const title = sectionProduct?.title || section.title;
            const subtitle = sectionProduct?.metadata?.collection || section.subtitle;

            return (
              <div key={section.key} className="card group cursor-pointer">
                <div className="card__image-wrapper aspect-square">
                  <Image
                    src={imageUrl}
                    alt={title}
                    fill
                    className="card__image object-cover"
                    sizes="(max-width: 768px) 100vw, 33vw"
                  />
                  <div className="card__overlay">
                    <div className="text-center">
                      <h3 className="font-display text-2xl font-bold text-text-primary mb-2">
                        {title}
                      </h3>
                      <p className="text-accent">{subtitle}</p>
                      {sectionProduct && (
                        <p className="text-text-secondary text-sm mt-2">
                          {sectionProduct.description}
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
