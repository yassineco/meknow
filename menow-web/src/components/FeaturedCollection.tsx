import ProductCard from "./ProductCard";

// Fonction pour récupérer les produits catalogue depuis l'API
async function getCatalogProducts() {
  try {
    const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://127.0.0.1:9000";
    const response = await fetch(`${API_URL}/api/products?limit=8`, {
      cache: 'no-store',
      next: { revalidate: 0 }
    });
    
    if (!response.ok) {
      console.error('Erreur récupération produits:', response.status);
      return [];
    }
    
    const data = await response.json();
    const allProducts = Array.isArray(data.products) ? data.products : [];
    
    // Filtrer uniquement les produits qui ont "catalog" dans display_sections
    return allProducts.filter((product: any) => 
      product.display_sections && product.display_sections.includes('catalog')
    );
  } catch (error) {
    console.error('Erreur récupération produits catalogue:', error);
    return [];
  }
}

export default async function FeaturedCollection() {
  try {
    // 🚀 Récupère uniquement les produits du CATALOGUE
    const products = await getCatalogProducts();

    return (
      <section className="section bg-bg-primary">
        <div className="container">
          <div className="text-center mb-12">
            <h2 className="font-display text-4xl md:text-5xl font-bold text-text-primary mb-4">
              Nos Produits
            </h2>
            <p className="text-text-secondary text-lg max-w-2xl mx-auto">
              Tous nos produits disponibles - Mise à jour automatique
            </p>
          </div>

          <div className="grid grid--4">
            {Array.isArray(products) && products.length > 0 ? (
              products.map((product: any) => (
                <ProductCard key={product.id} product={product} />
              ))
            ) : (
              <div className="col-span-4 text-center py-8">
                <p className="text-text-secondary">Aucun produit disponible pour le moment.</p>
              </div>
            )}
          </div>
        </div>
      </section>
    );
  } catch (error) {
    console.error('Error in FeaturedCollection:', error);
    return (
      <section className="section bg-bg-primary">
        <div className="container">
          <div className="text-center py-12">
            <p className="text-text-secondary">Erreur lors du chargement des produits.</p>
          </div>
        </div>
      </section>
    );
  }
}
