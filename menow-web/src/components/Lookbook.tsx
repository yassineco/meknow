import Image from "next/image";

export default function Lookbook() {
  const images = [
    {
      src: "https://images.unsplash.com/photo-1594633313593-bab3825d0caf?w=800",
      title: "Collection Automne",
      subtitle: "Cuirs premium",
    },
    {
      src: "https://images.unsplash.com/photo-1520975867597-0af37a22e31a?w=800",
      title: "Savoir-faire artisanal",
      subtitle: "Made in Morocco",
    },
    {
      src: "https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=800",
      title: "Style contemporain",
      subtitle: "Design intemporel",
    },
  ];

  return (
    <section className="section bg-bg-secondary">
      <div className="container">
        <div className="text-center mb-12">
          <h2 className="font-display text-4xl md:text-5xl font-bold text-text-primary mb-4">
            Lookbook
          </h2>
          <p className="text-text-secondary text-lg">
            Découvrez l'univers Meknow
          </p>
        </div>

        <div className="grid grid--3">
          {images.map((img, i) => (
            <div key={i} className="card group cursor-pointer">
              <div className="card__image-wrapper aspect-square">
                <Image
                  src={img.src}
                  alt={img.title}
                  fill
                  className="card__image object-cover"
                  sizes="(max-width: 768px) 100vw, 33vw"
                />
                <div className="card__overlay">
                  <div className="text-center">
                    <h3 className="font-display text-2xl font-bold text-text-primary mb-2">
                      {img.title}
                    </h3>
                    <p className="text-accent">{img.subtitle}</p>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
