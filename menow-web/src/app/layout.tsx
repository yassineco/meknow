import type { Metadata } from "next";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import "@/styles/globals.css";
import "@/styles/theme.css";

export const metadata: Metadata = {
  title: "Meknow - Prêt-à-porter Premium Made in Morocco",
  description: "Prêt-à-porter premium fabriqué au Maroc. Cuir artisanal, design contemporain, savoir-faire d'exception.",
  keywords: ["mode", "prêt-à-porter", "cuir", "Maroc", "premium", "artisanal"],
  openGraph: {
    title: "Meknow - Prêt-à-porter Premium Made in Morocco",
    description: "Prêt-à-porter premium fabriqué au Maroc",
    type: "website",
    locale: "fr_FR",
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="fr">
      <body>
        <div className="grain"></div>
        <Header />
        <main>{children}</main>
        <Footer />
      </body>
    </html>
  );
}
