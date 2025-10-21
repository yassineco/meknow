import './globals.css'

export const metadata = {
  title: 'Meknow - E-commerce Premium',
  description: 'Plateforme e-commerce moderne avec gestion rubriques',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="fr">
      <body>
        <div className="min-h-screen bg-black text-white">
          {children}
        </div>
      </body>
    </html>
  )
}