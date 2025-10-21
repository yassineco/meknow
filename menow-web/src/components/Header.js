// Simple Header component
export default function Header() {
  return (
    <header className="header">
      <div className="container">
        <h1>MEKNOW E-Commerce</h1>
        <nav>
          <a href="/">Accueil</a>
          <a href="/products">Produits</a>
        </nav>
      </div>
    </header>
  );
}