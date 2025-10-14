export default function RetoursPage() {
  return (
    <div className="pt-48 pb-20">
      <div className="container max-w-4xl">
        <h1 className="font-display text-4xl md:text-5xl font-bold text-text-primary mb-8">
          Politique de Retours
        </h1>

        <div className="prose prose-invert max-w-none space-y-6 text-text-secondary">
          <section>
            <h2 className="font-display text-2xl font-bold text-text-primary mb-4">Délai de rétractation</h2>
            <p>
              Vous disposez d'un délai de 30 jours à compter de la réception de votre commande 
              pour nous retourner un article qui ne vous convient pas, sans avoir à justifier de motifs.
            </p>
          </section>

          <section>
            <h2 className="font-display text-2xl font-bold text-text-primary mb-4">Conditions de retour</h2>
            <p>
              Pour être accepté, votre retour doit respecter les conditions suivantes :
            </p>
            <ul className="list-disc pl-6 space-y-2">
              <li>L'article doit être dans son état d'origine</li>
              <li>Les étiquettes doivent être intactes</li>
              <li>L'article ne doit pas avoir été porté (sauf pour l'essayage)</li>
              <li>L'article doit être retourné dans son emballage d'origine</li>
            </ul>
          </section>

          <section>
            <h2 className="font-display text-2xl font-bold text-text-primary mb-4">Procédure de retour</h2>
            <ol className="list-decimal pl-6 space-y-2">
              <li>Contactez notre service client à contact@meknow.fr pour obtenir un numéro de retour</li>
              <li>Emballez soigneusement l'article avec tous ses accessoires</li>
              <li>Indiquez le numéro de retour sur le colis</li>
              <li>Retournez le colis à l'adresse indiquée par notre service client</li>
            </ol>
          </section>

          <section>
            <h2 className="font-display text-2xl font-bold text-text-primary mb-4">Frais de retour</h2>
            <p>
              Les frais de retour sont à votre charge, sauf en cas d'article défectueux ou d'erreur 
              de notre part. Nous vous recommandons d'utiliser un mode d'envoi avec suivi.
            </p>
          </section>

          <section>
            <h2 className="font-display text-2xl font-bold text-text-primary mb-4">Remboursement</h2>
            <p>
              Une fois votre retour réceptionné et vérifié, nous procéderons au remboursement 
              dans un délai de 14 jours. Le remboursement sera effectué par le même moyen de paiement 
              que celui utilisé pour la commande initiale.
            </p>
          </section>

          <section>
            <h2 className="font-display text-2xl font-bold text-text-primary mb-4">Échange</h2>
            <p>
              Si vous souhaitez échanger un article (taille, couleur), veuillez procéder à un retour 
              puis passer une nouvelle commande. Cela vous permettra de garantir la disponibilité 
              de l'article souhaité.
            </p>
          </section>

          <section>
            <h2 className="font-display text-2xl font-bold text-text-primary mb-4">Contact</h2>
            <p>
              Pour toute question concernant les retours :<br />
              Email : contact@meknow.fr<br />
              Téléphone : +33 1 XX XX XX XX<br />
              Lun-Ven : 9h-18h
            </p>
          </section>
        </div>
      </div>
    </div>
  );
}
