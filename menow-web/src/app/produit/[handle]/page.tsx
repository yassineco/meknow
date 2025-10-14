import Image from "next/image";
import { getProduct } from "@/lib/medusa";
import { formatPrice } from "@/lib/medusa";
import { getImageUrl } from "@/lib/utils";
import { notFound } from "next/navigation";

export default async function ProductPage({ params }: { params: { handle: string } }) {
  const product = await getProduct(params.handle);

  if (!product) {
    notFound();
  }

  const mainImage = getImageUrl(product.thumbnail || product.images?.[0]?.url);
  const price = 0; // Prix sera récupéré via une API séparée

  return (
    <div className="pt-48 pb-20">
      <div className="container">
        <div className="grid md:grid-cols-2 gap-12">
          <div className="space-y-4">
            <div className="relative aspect-[3/4] overflow-hidden bg-bg-secondary">
              <Image
                src={mainImage}
                alt={product.title}
                fill
                className="object-cover"
                priority
              />
            </div>
            <div className="grid grid-cols-3 gap-4">
              {product.images?.slice(1, 4).map((img: any, i: number) => (
                <div key={i} className="relative aspect-square overflow-hidden bg-bg-secondary">
                  <Image
                    src={getImageUrl(img.url)}
                    alt={`${product.title} ${i + 2}`}
                    fill
                    className="object-cover hover:scale-110 transition-transform cursor-pointer"
                  />
                </div>
              ))}
            </div>
          </div>

          <div>
            <div className="badge mb-6">
              <span>✨ Made in Morocco</span>
            </div>

            <h1 className="font-display text-4xl md:text-5xl font-bold text-text-primary mb-4">
              {product.title}
            </h1>

            {product.subtitle && (
              <p className="text-text-secondary text-lg mb-6">{product.subtitle}</p>
            )}

            <div className="flex items-baseline gap-4 mb-8">
              <span className="font-display text-4xl font-bold text-accent">
                {formatPrice(price)}
              </span>
              <span className="text-text-secondary text-sm">TTC</span>
            </div>

            <div className="bg-accent/10 border border-accent/30 p-4 rounded mb-8">
              <p className="text-accent font-semibold">
                💰 Paiement comptant disponible à la livraison
              </p>
            </div>

            <div className="mb-8">
              <h3 className="font-semibold text-text-primary mb-4">Taille</h3>
              <div className="flex gap-3">
                {product.options?.[0]?.values?.map((size: any, i: number) => (
                  <button
                    key={i}
                    className="btn btn--ghost px-6 py-3"
                  >
                    {size.value}
                  </button>
                ))}
              </div>
            </div>

            <button className="btn btn--primary w-full mb-8 justify-center">
              Ajouter au panier
            </button>

            <div className="prose prose-invert max-w-none">
              <h3 className="font-semibold text-text-primary mb-4">Description</h3>
              <p className="text-text-secondary leading-relaxed">
                {product.description}
              </p>
            </div>

            <div className="mt-8 pt-8 border-t border-border space-y-4">
              <div className="flex items-start gap-4">
                <span className="text-2xl">🚚</span>
                <div>
                  <h4 className="font-semibold text-text-primary">Livraison France</h4>
                  <p className="text-text-secondary text-sm">Livraison rapide et sécurisée</p>
                </div>
              </div>
              <div className="flex items-start gap-4">
                <span className="text-2xl">↩️</span>
                <div>
                  <h4 className="font-semibold text-text-primary">Retours 30 jours</h4>
                  <p className="text-text-secondary text-sm">Satisfait ou remboursé</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
