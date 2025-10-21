import Hero from "@/components/Hero";
import ReassuranceBar from "@/components/ReassuranceBar";
import FeaturedCollection from "@/components/FeaturedCollection";
import Lookbook from "@/components/Lookbook";

// 🚀 REVALIDATION AUTOMATIQUE - Mise à jour toutes les 30 secondes
export const revalidate = 30;

export default function Home() {
  return (
    <>
      <Hero />
      <ReassuranceBar />
      <FeaturedCollection />
      <Lookbook />
    </>
  );
}
