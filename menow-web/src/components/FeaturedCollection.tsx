import { getProducts } from "@/lib/api";
import ProductCard from "./ProductCard";

export default async function FeaturedCollection() {
  const products = await getProducts({ limit: 4, collection_id: ["capsule"] });

  return (
    <section className="section bg-bg-primary">
      <div className="container">
        <div className="text-center mb-12">
          <h2 className="font-display text-4xl md:text-5xl font-bold text-text-primary mb-4">
            Collection Capsule
          </h2>
          <p className="text-text-secondary text-lg max-w-2xl mx-auto">
            Nos pièces signature, fabriquées à la main au Maroc
          </p>
        </div>

        <div className="grid grid--4">
          {products.map((product: any) => (
            <ProductCard key={product.id} product={product} />
          ))}
        </div>
      </div>
    </section>
  );
}
