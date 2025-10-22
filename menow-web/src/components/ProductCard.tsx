import Image from "next/image";
import Link from "next/link";
import { formatPrice } from "@/lib/api";
import { getImageUrl } from "@/lib/utils";

interface ProductCardProps {
  product: any;
}

export default function ProductCard({ product }: ProductCardProps) {
  const priceInCents = product.variants?.[0]?.prices?.[0]?.amount || 0;
  const price = priceInCents / 100; // Convertir centimes en euros
  const imageUrl = getImageUrl(product.thumbnail || product.images?.[0]?.url);

  return (
    <Link href={`/produit/${product.handle}`} className="card group">
      <div className="card__image-wrapper">
        {imageUrl && imageUrl !== '/placeholder.jpg' ? (
          <img
            src={imageUrl}
            alt={product.title}
            className="card__image w-full h-full object-cover"
          />
        ) : (
          <Image
            src={imageUrl}
            alt={product.title}
            fill
            className="card__image object-cover"
            sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 25vw"
          />
        )}
        <div className="card__overlay">
          <div className="badge">
            <span>✨ Made in Morocco</span>
          </div>
        </div>
      </div>

      <div className="p-6">
        <h3 className="font-display text-xl font-bold text-text-primary mb-2 group-hover:text-accent transition-colors">
          {product.title}
        </h3>
        {product.subtitle && (
          <p className="text-text-secondary text-sm mb-4">{product.subtitle}</p>
        )}
        <div className="flex items-center justify-between">
          <span className="font-semibold text-lg text-accent">
            {formatPrice(price)}
          </span>
          <span className="text-xs text-text-secondary uppercase tracking-wide">
            Paiement comptant ✓
          </span>
        </div>
      </div>
    </Link>
  );
}
