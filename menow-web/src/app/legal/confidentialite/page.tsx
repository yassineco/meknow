export default function ConfidentialitePage() {
  return (
    <div className="pt-48 pb-20">
      <div className="container max-w-4xl">
        <h1 className="font-display text-4xl md:text-5xl font-bold text-text-primary mb-8">
          Politique de Confidentialité (RGPD)
        </h1>

        <div className="prose prose-invert max-w-none space-y-6 text-text-secondary">
          <section>
            <h2 className="font-display text-2xl font-bold text-text-primary mb-4">1. Collecte des données</h2>
            <p>
              Dans le cadre de votre navigation et de vos commandes sur notre site, nous collectons 
              les données personnelles suivantes : nom, prénom, adresse email, adresse de livraison, 
              numéro de téléphone.
            </p>
          </section>

          <section>
            <h2 className="font-display text-2xl font-bold text-text-primary mb-4">2. Finalités</h2>
            <p>
              Vos données sont collectées pour :
            </p>
            <ul className="list-disc pl-6 space-y-2">
              <li>Traiter et suivre vos commandes</li>
              <li>Assurer la livraison de vos produits</li>
              <li>Vous contacter en cas de besoin concernant votre commande</li>
              <li>Respecter nos obligations légales et comptables</li>
            </ul>
          </section>

          <section>
            <h2 className="font-display text-2xl font-bold text-text-primary mb-4">3. Base légale</h2>
            <p>
              Le traitement de vos données personnelles est fondé sur l'exécution du contrat de vente 
              et sur le respect de nos obligations légales (facturation, comptabilité).
            </p>
          </section>

          <section>
            <h2 className="font-display text-2xl font-bold text-text-primary mb-4">4. Durée de conservation</h2>
            <p>
              Vos données sont conservées pendant la durée nécessaire à l'exécution de vos commandes, 
              et 3 ans après votre dernière commande, conformément aux obligations légales.
            </p>
          </section>

          <section>
            <h2 className="font-display text-2xl font-bold text-text-primary mb-4">5. Vos droits</h2>
            <p>
              Conformément au RGPD, vous disposez des droits suivants sur vos données personnelles :
            </p>
            <ul className="list-disc pl-6 space-y-2">
              <li>Droit d'accès</li>
              <li>Droit de rectification</li>
              <li>Droit à l'effacement</li>
              <li>Droit à la limitation du traitement</li>
              <li>Droit d'opposition</li>
              <li>Droit à la portabilité</li>
            </ul>
            <p className="mt-4">
              Pour exercer ces droits, contactez-nous à : contact@meknow.fr
            </p>
          </section>

          <section>
            <h2 className="font-display text-2xl font-bold text-text-primary mb-4">6. Hébergement des données</h2>
            <p>
              Vos données sont hébergées dans l'Union Européenne, conformément au RGPD. 
              Nous utilisons des serveurs situés en France et en Europe uniquement.
            </p>
          </section>

          <section>
            <h2 className="font-display text-2xl font-bold text-text-primary mb-4">7. Sécurité</h2>
            <p>
              Nous mettons en œuvre toutes les mesures techniques et organisationnelles appropriées 
              pour protéger vos données personnelles contre tout accès non autorisé, perte ou destruction.
            </p>
          </section>
        </div>
      </div>
    </div>
  );
}
