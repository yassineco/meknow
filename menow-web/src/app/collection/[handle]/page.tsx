import { getCollection, getProducts } from "@/lib/medusa";
import ProductCard from "@/components/ProductCard";
import { notFound } from "next/navigation";

export default async function CollectionPage({ params }: { params: { handle: string } }) {
  const collection = await getCollection(params.handle);

  if (!collection) {
    notFound();
  }

  const products = await getProducts({ collection_id: [collection.id] });

  return (
    <div className="pt-48 pb-20">
      <div className="container">
        <div className="text-center mb-16">
          <h1 className="font-display text-5xl md:text-6xl font-bold text-text-primary mb-6">
            {collection.title}
          </h1>
          {collection.metadata?.description ? (
            <p className="text-text-secondary text-lg max-w-2xl mx-auto">
              {collection.metadata.description as string}
            </p>
          ) : null}
        </div>

        <div className="grid grid--4">
          {products.map((product: any) => (
            <ProductCard key={product.id} product={product} />
          ))}
        </div>

        {products.length === 0 && (
          <div className="text-center py-20">
            <p className="text-text-secondary text-lg">
              Aucun produit disponible dans cette collection pour le moment.
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
