import React, { useState } from 'react';
import { Download, Music, ChevronDown, Check } from 'lucide-react';
import { ACCENTS } from '../types';
import type { AccentColor } from '../types';

interface NavbarProps {
  currentAccent: AccentColor;
  onSelectAccent: (accent: AccentColor) => void;
  onOpenDownload: (arch?: 'win-x64' | 'win-x86') => void;
}

export const Navbar: React.FC<NavbarProps> = ({
  currentAccent,
  onSelectAccent,
  onOpenDownload,
}) => {
  const [accentDropdownOpen, setAccentDropdownOpen] = useState(false);

  return (
    <header className="fixed top-0 left-0 right-0 z-40 px-4 sm:px-8 pt-4 pb-2">
      <nav className="max-w-7xl mx-auto liquid-glass rounded-full px-5 py-3 flex items-center justify-between specular-rim">
        {/* Brand Logo & Name */}
        <a href="#" className="flex items-center gap-3 group">
          <div
            className="w-9 h-9 rounded-xl flex items-center justify-center text-white shadow-md transition-transform group-hover:scale-105"
            style={{ backgroundColor: currentAccent.color }}
          >
            <Music className="w-5 h-5" />
          </div>
          <div className="flex flex-col">
            <span className="font-bold text-white text-base tracking-tight flex items-center gap-1.5">
              Astra Music
              <span className="text-[10px] font-semibold uppercase px-1.5 py-0.5 rounded-full bg-white/10 text-zinc-300">
                v1.0
              </span>
            </span>
            <span className="text-[11px] text-zinc-400 font-medium">Liquid Glass Player</span>
          </div>
        </a>

        {/* Desktop Navigation Links */}
        <div className="hidden md:flex items-center gap-7 text-sm font-medium text-zinc-300">
          <a href="#features" className="hover:text-white transition-colors">Features</a>
          <a href="#live-player" className="hover:text-white transition-colors">Live Player</a>
          <a href="#studio" className="hover:text-white transition-colors">Audio Studio</a>
          <a href="#gallery" className="hover:text-white transition-colors">Screenshots</a>
          <a href="#tech-specs" className="hover:text-white transition-colors">Specs</a>
        </div>

        {/* Right Controls: Accent Color Picker + Download CTA */}
        <div className="flex items-center gap-3">
          {/* Accent Color Palette Switcher */}
          <div className="relative">
            <button
              onClick={() => setAccentDropdownOpen(!accentDropdownOpen)}
              className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-white/5 hover:bg-white/10 border border-white/10 transition-colors text-xs font-medium text-zinc-300"
              title="Change Liquid Glass Accent"
            >
              <span
                className="w-3.5 h-3.5 rounded-full inline-block shadow-sm"
                style={{ backgroundColor: currentAccent.color }}
              />
              <span className="hidden sm:inline">{currentAccent.name}</span>
              <ChevronDown className="w-3.5 h-3.5 text-zinc-400" />
            </button>

            {/* Accent Dropdown Menu */}
            {accentDropdownOpen && (
              <div
                className="absolute right-0 mt-2 w-48 liquid-glass rounded-2xl p-2 shadow-2xl border border-white/15 z-50 specular-rim"
                onClick={() => setAccentDropdownOpen(false)}
              >
                <div className="text-[11px] font-bold text-zinc-400 uppercase tracking-wider px-2 py-1 mb-1">
                  Accent Color
                </div>
                <div className="grid grid-cols-2 gap-1">
                  {ACCENTS.map((accent) => (
                    <button
                      key={accent.id}
                      onClick={() => onSelectAccent(accent)}
                      className={`flex items-center gap-2 px-2.5 py-1.5 rounded-xl text-xs font-medium transition-colors ${
                        currentAccent.id === accent.id ? 'bg-white/15 text-white' : 'text-zinc-300 hover:bg-white/10'
                      }`}
                    >
                      <span
                        className="w-3 h-3 rounded-full"
                        style={{ backgroundColor: accent.color }}
                      />
                      <span>{accent.name}</span>
                      {currentAccent.id === accent.id && <Check className="w-3 h-3 ml-auto text-white" />}
                    </button>
                  ))}
                </div>
              </div>
            )}
          </div>

          {/* Download CTA Button */}
          <button
            onClick={() => onOpenDownload('win-x64')}
            className="flex items-center gap-2 px-4 py-2 rounded-full font-semibold text-xs sm:text-sm text-white shadow-lg hover:opacity-95 active:scale-95 transition-all"
            style={{
              backgroundColor: currentAccent.color,
              boxShadow: `0 4px 18px -2px ${currentAccent.glow}`,
            }}
          >
            <Download className="w-4 h-4" />
            <span>Download</span>
          </button>
        </div>
      </nav>
    </header>
  );
};
