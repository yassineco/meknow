import Link from "next/link";

export default function Hero() {
  return (
    <section className="relative min-h-screen flex items-center justify-center pt-32 pb-20">
      <div className="absolute inset-0 overflow-hidden">
        <div className="absolute inset-0 bg-gradient-radial from-accent/10 via-transparent to-transparent opacity-50"></div>
        <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-accent/5 rounded-full blur-3xl animate-[float_8s_ease-in-out_infinite]"></div>
        <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-accent/5 rounded-full blur-3xl animate-[float_10s_ease-in-out_infinite_2s]"></div>
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[500px] h-[500px] bg-accent/3 rounded-full blur-3xl animate-[float_12s_ease-in-out_infinite_4s]"></div>
      </div>

      <div className="container relative z-10 text-center">
        <div className="badge badge--pulse mb-8 inline-flex">
          <span>✨ Made in Morocco</span>
        </div>

        <h1 className="font-display text-6xl md:text-8xl font-bold mb-6">
          <span className="block text-text-primary/60">L'EXCELLENCE</span>
          <span className="block bg-gradient-to-r from-accent via-text-primary to-accent bg-clip-text text-transparent animate-shimmer bg-[length:200%_100%]">
            MAROCAINE
          </span>
        </h1>

        <p className="text-text-secondary text-lg md:text-xl max-w-2xl mx-auto mb-12">
          Prêt-à-porter premium alliant savoir-faire artisanal et design contemporain
        </p>

        <div className="flex flex-col sm:flex-row gap-4 justify-center items-center">
          <Link href="/collection/capsule" className="btn btn--primary">
            <span>Découvrir la collection</span>
            <svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M5 10h10M10 5l5 5-5 5" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </Link>
          <Link href="/legal/cgv" className="btn btn--ghost">
            Notre histoire
          </Link>
        </div>

        <div className="absolute bottom-8 left-1/2 -translate-x-1/2">
          <div className="scroll-indicator">
            SCROLL
          </div>
        </div>
      </div>
    </section>
  );
}
