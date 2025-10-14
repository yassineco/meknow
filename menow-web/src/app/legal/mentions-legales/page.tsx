export default function MentionsLegalesPage() {
  return (
    <div className="pt-48 pb-20">
      <div className="container max-w-4xl">
        <h1 className="font-display text-4xl md:text-5xl font-bold text-text-primary mb-8">
          Mentions Légales
        </h1>

        <div className="prose prose-invert max-w-none space-y-6 text-text-secondary">
          <section>
            <h2 className="font-display text-2xl font-bold text-text-primary mb-4">Éditeur du site</h2>
            <p>
              Meknow<br />
              Société [Forme juridique]<br />
              Capital social : [Montant] €<br />
              Siège social : [Adresse complète]<br />
              SIRET : [Numéro SIRET]<br />
              RCS : [Ville]<br />
              TVA intracommunautaire : [Numéro]
            </p>
            <p>
              Téléphone : +33 1 XX XX XX XX<br />
              Email : contact@meknow.fr
            </p>
          </section>

          <section>
            <h2 className="font-display text-2xl font-bold text-text-primary mb-4">Directeur de publication</h2>
            <p>[Nom et prénom du directeur de publication]</p>
          </section>

          <section>
            <h2 className="font-display text-2xl font-bold text-text-primary mb-4">Hébergement</h2>
            <p>
              Le site est hébergé par :<br />
              [Nom de l'hébergeur]<br />
              [Adresse de l'hébergeur]<br />
              [Téléphone de l'hébergeur]
            </p>
          </section>

          <section>
            <h2 className="font-display text-2xl font-bold text-text-primary mb-4">Propriété intellectuelle</h2>
            <p>
              L'ensemble du contenu de ce site (textes, images, vidéos, logos) est protégé par le 
              droit d'auteur et le droit des marques. Toute reproduction, même partielle, est interdite 
              sans autorisation préalable.
            </p>
          </section>
        </div>
      </div>
    </div>
  );
}
