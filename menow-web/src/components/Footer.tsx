import Link from "next/link";

export default function Footer() {
  return (
    <footer className="bg-bg-secondary border-t border-border py-12">
      <div className="container">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8 mb-8">
          <div>
            <h3 className="font-display text-xl mb-4 text-accent">MEKNOW</h3>
            <p className="text-text-secondary text-sm">
              L'excellence marocaine dans le prêt-à-porter premium.
            </p>
          </div>

          <div>
            <h4 className="font-semibold mb-4 text-text-primary">Légal</h4>
            <ul className="space-y-2">
              <li>
                <Link href="/legal/cgv" className="text-text-secondary text-sm hover:text-accent transition-colors">
                  Conditions générales de vente
                </Link>
              </li>
              <li>
                <Link href="/legal/mentions-legales" className="text-text-secondary text-sm hover:text-accent transition-colors">
                  Mentions légales
                </Link>
              </li>
              <li>
                <Link href="/legal/confidentialite" className="text-text-secondary text-sm hover:text-accent transition-colors">
                  Politique de confidentialité (RGPD)
                </Link>
              </li>
              <li>
                <Link href="/legal/retours" className="text-text-secondary text-sm hover:text-accent transition-colors">
                  Politique de retours
                </Link>
              </li>
            </ul>
          </div>

          <div>
            <h4 className="font-semibold mb-4 text-text-primary">Contact</h4>
            <ul className="space-y-2 text-text-secondary text-sm">
              <li>contact@meknow.fr</li>
              <li>+33 1 XX XX XX XX</li>
              <li>Lun-Ven: 9h-18h</li>
            </ul>
          </div>

          <div>
            <h4 className="font-semibold mb-4 text-text-primary">Suivez-nous</h4>
            <div className="flex gap-4">
              <a href="#" className="text-text-secondary hover:text-accent transition-colors">
                Instagram
              </a>
              <a href="#" className="text-text-secondary hover:text-accent transition-colors">
                Facebook
              </a>
            </div>
          </div>
        </div>

        <div className="pt-8 border-t border-border text-center text-text-secondary text-sm">
          <p>&copy; 2025 Meknow. Tous droits réservés.</p>
        </div>
      </div>
    </footer>
  );
}
