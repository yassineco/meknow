"use client";

import Link from "next/link";
import Image from "next/image";
import { useState } from "react";

export default function Header() {
  const [cartCount] = useState(0);

  return (
    <header className="fixed top-0 left-0 w-full z-[1000] py-6 bg-bg-primary/80 backdrop-blur-[20px] border-b border-accent/10 transition-all">
      <div className="container">
        <div className="flex items-center justify-between">
          <Link href="/" className="flex items-center gap-4">
            <div className="relative w-[150px] h-[150px] transition-transform hover:scale-105">
              <Image
                src="/logo.png?v=20241014-meknow"
                alt="Meknow"
                fill
                className="object-contain"
                priority
              />
            </div>
          </Link>

          <nav className="hidden md:flex gap-10">
            <Link href="/collection/capsule-menow" className="text-text-secondary hover:text-accent font-medium text-[0.95rem] relative after:absolute after:bottom-[-5px] after:left-0 after:w-0 after:h-[2px] after:bg-accent after:transition-all hover:after:w-full">
              Collections
            </Link>
            <Link href="/" className="text-text-secondary hover:text-accent font-medium text-[0.95rem] relative after:absolute after:bottom-[-5px] after:left-0 after:w-0 after:h-[2px] after:bg-accent after:transition-all hover:after:w-full">
              Nouveautés
            </Link>
            <Link href="/legal/cgv" className="text-text-secondary hover:text-accent font-medium text-[0.95rem] relative after:absolute after:bottom-[-5px] after:left-0 after:w-0 after:h-[2px] after:bg-accent after:transition-all hover:after:w-full">
              À propos
            </Link>
            <Link href="/legal/cgv" className="text-text-secondary hover:text-accent font-medium text-[0.95rem] relative after:absolute after:bottom-[-5px] after:left-0 after:w-0 after:h-[2px] after:bg-accent after:transition-all hover:after:w-full">
              Contact
            </Link>
          </nav>

          <div className="flex items-center gap-4">
            <button className="p-2 text-text-primary hover:text-accent transition-colors">
              <svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="2">
                <circle cx="8" cy="8" r="6"/>
                <path d="M12.5 12.5L17 17" strokeLinecap="round"/>
              </svg>
            </button>
            <button className="relative p-2 text-text-primary hover:text-accent transition-colors">
              <svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M1 1h3l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L22 6H6" strokeLinecap="round" strokeLinejoin="round"/>
              </svg>
              {cartCount > 0 && (
                <span className="absolute -top-1 -right-1 bg-accent text-bg-primary text-xs w-5 h-5 flex items-center justify-center rounded-full font-bold">
                  {cartCount}
                </span>
              )}
            </button>
          </div>
        </div>
      </div>
    </header>
  );
}
