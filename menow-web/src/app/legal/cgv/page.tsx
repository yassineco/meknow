export default function CGVPage() {
  return (
    <div className="pt-48 pb-20">
      <div className="container max-w-4xl">
        <h1 className="font-display text-4xl md:text-5xl font-bold text-text-primary mb-8">
          Conditions Générales de Vente
        </h1>

        <div className="prose prose-invert max-w-none space-y-6 text-text-secondary">
          <section>
            <h2 className="font-display text-2xl font-bold text-text-primary mb-4">1. Objet</h2>
            <p>
              Les présentes conditions générales de vente régissent les ventes de produits Meknow 
              réalisées via la boutique en ligne. Toute commande implique l'acceptation sans réserve 
              de ces conditions.
            </p>
          </section>

          <section>
            <h2 className="font-display text-2xl font-bold text-text-primary mb-4">2. Prix</h2>
            <p>
              Les prix sont indiqués en euros toutes taxes comprises (TTC), incluant la TVA française 
              applicable au jour de la commande. Meknow se réserve le droit de modifier ses prix à tout moment.
            </p>
          </section>

          <section>
            <h2 className="font-display text-2xl font-bold text-text-primary mb-4">3. Paiement</h2>
            <p>
              Meknow accepte le paiement comptant à la livraison (COD) pour la France métropolitaine. 
              Le règlement s'effectue en espèces ou par carte bancaire auprès du transporteur au moment 
              de la livraison. Le paiement en ligne par carte bancaire sera disponible prochainement.
            </p>
          </section>

          <section>
            <h2 className="font-display text-2xl font-bold text-text-primary mb-4">4. Livraison</h2>
            <p>
              Les livraisons sont effectuées en France métropolitaine uniquement. Les délais de livraison 
              sont de 5 à 10 jours ouvrés à compter de la validation de la commande. Les frais de livraison 
              sont indiqués lors de la commande.
            </p>
          </section>

          <section>
            <h2 className="font-display text-2xl font-bold text-text-primary mb-4">5. Droit de rétractation</h2>
            <p>
              Conformément à la législation française, vous disposez d'un délai de 14 jours à compter 
              de la réception de votre commande pour exercer votre droit de rétractation sans avoir 
              à justifier de motifs ni à payer de pénalités.
            </p>
          </section>

          <section>
            <h2 className="font-display text-2xl font-bold text-text-primary mb-4">6. Garanties</h2>
            <p>
              Tous nos produits bénéficient de la garantie légale de conformité et de la garantie 
              contre les vices cachés prévues par le Code de la consommation français.
            </p>
          </section>
        </div>
      </div>
    </div>
  );
}
