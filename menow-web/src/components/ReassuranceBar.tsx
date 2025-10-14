export default function ReassuranceBar() {
  const badges = [
    {
      icon: "✨",
      title: "Fabrication marocaine",
      desc: "Savoir-faire artisanal",
    },
    {
      icon: "🚚",
      title: "Livraison France",
      desc: "Rapide et sécurisée",
    },
    {
      icon: "↩️",
      title: "Retours 30 jours",
      desc: "Satisfait ou remboursé",
    },
    {
      icon: "💰",
      title: "Paiement comptant",
      desc: "À la livraison",
    },
  ];

  return (
    <section className="py-12 bg-bg-secondary border-y border-border">
      <div className="container">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
          {badges.map((badge, i) => (
            <div key={i} className="text-center">
              <div className="text-4xl mb-3">{badge.icon}</div>
              <h3 className="font-semibold text-text-primary mb-1">{badge.title}</h3>
              <p className="text-sm text-text-secondary">{badge.desc}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
