// Simple ProductCard component
export default function ProductCard({ product }) {
  return (
    <div className="product-card">
      <div className="product-image">
        <img src={product.image || '/images/placeholder.jpg'} alt={product.name} />
      </div>
      <div className="product-info">
        <h3>{product.name}</h3>
        <p className="price">{product.price}€</p>
        <button className="btn-primary">Ajouter au panier</button>
      </div>
    </div>
  );
}