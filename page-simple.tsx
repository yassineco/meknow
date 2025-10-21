export default function HomePage() {
  return (
    <div className="container mx-auto px-4 py-8">
      <header className="text-center mb-12">
        <h1 className="text-4xl font-bold mb-4">
          🛍️ MEKNOW E-COMMERCE
        </h1>
        <p className="text-xl text-gray-300">
          Plateforme e-commerce premium avec gestion rubriques
        </p>
      </header>

      <main>
        <section className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8 mb-12">
          <div className="bg-gray-900 p-6 rounded-lg">
            <h3 className="text-xl font-semibold mb-3">🎨 Frontend Next.js</h3>
            <p className="text-gray-400">
              Interface moderne et responsive construite avec Next.js 14
            </p>
          </div>
          
          <div className="bg-gray-900 p-6 rounded-lg">
            <h3 className="text-xl font-semibold mb-3">🔧 API Backend</h3>
            <p className="text-gray-400">
              API Express.js avec gestion complète des produits et rubriques
            </p>
          </div>
          
          <div className="bg-gray-900 p-6 rounded-lg">
            <h3 className="text-xl font-semibold mb-3">👑 Admin Interface</h3>
            <p className="text-gray-400">
              Dashboard d'administration pour gérer produits et collections
            </p>
          </div>
        </section>

        <section className="text-center">
          <h2 className="text-2xl font-bold mb-6">🚀 Plateforme Opérationnelle</h2>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <a 
              href="/admin" 
              className="bg-blue-600 hover:bg-blue-700 px-6 py-3 rounded-lg font-semibold transition-colors"
            >
              👑 Accès Admin
            </a>
            <a 
              href="/api/health" 
              className="bg-green-600 hover:bg-green-700 px-6 py-3 rounded-lg font-semibold transition-colors"
            >
              🔧 Status API
            </a>
          </div>
        </section>
      </main>

      <footer className="mt-16 pt-8 border-t border-gray-800 text-center text-gray-500">
        <p>© 2025 Meknow E-commerce - Déployé avec Docker 🐳</p>
      </footer>
    </div>
  )
}