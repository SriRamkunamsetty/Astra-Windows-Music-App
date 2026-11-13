import React from 'react';
import { 
  Sparkles, 
  Heart, 
  ShieldCheck, 
  Download, 
  Monitor 
} from 'lucide-react';
import type { AccentColor } from '../types';

interface FooterProps {
  activeAccent: AccentColor;
  onOpenDownload: (archId?: 'win-x64' | 'win-x86') => void;
}

export const Footer: React.FC<FooterProps> = ({ activeAccent, onOpenDownload }) => {
  return (
    <footer className="relative mt-24 border-t border-white/10 bg-black/60 backdrop-blur-2xl">
      {/* Subtle top rim glow */}
      <div
        className="absolute top-0 left-1/2 -translate-x-1/2 w-3/4 h-[1px]"
        style={{
          background: `linear-gradient(90deg, transparent, ${activeAccent.color}, transparent)`
        }}
      />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
        <div className="grid grid-cols-1 md:grid-cols-12 gap-10 lg:gap-12 mb-14">
          {/* Brand Info */}
          <div className="md:col-span-5 space-y-4">
            <div className="flex items-center gap-3">
              <div
                className="w-10 h-10 rounded-2xl flex items-center justify-center p-2 shadow-lg border"
                style={{
                  backgroundColor: 'rgba(255, 255, 255, 0.05)',
                  borderColor: `${activeAccent.color}60`,
                  boxShadow: `0 0 20px ${activeAccent.glow}`
                }}
              >
                <img
                  src="/screenshots/logo.png"
                  alt="Astra Music"
                  className="w-full h-full object-contain"
                  onError={(e) => {
                    // Fallback to Music2 icon if image fails
                    (e.target as HTMLElement).style.display = 'none';
                  }}
                />
              </div>
              <span className="text-xl font-bold tracking-tight text-white">
                Astra<span style={{ color: activeAccent.color }}>Music</span>
              </span>
            </div>

            <p className="text-sm text-white/60 leading-relaxed max-w-sm">
              The next-generation desktop and mobile audio player crafted with the Apple iOS/macOS Liquid Glass design language, ultra-fluid 120 FPS animations, and a zero-dependency pure Dart audio engine.
            </p>

            <div className="flex items-center gap-3 pt-2">
              <div className="flex items-center gap-1.5 px-3 py-1 rounded-full liquid-glass-pill text-[11px] font-medium text-white/70">
                <ShieldCheck className="w-3.5 h-3.5 text-emerald-400" />
                <span>100% Offline & Private</span>
              </div>
              <div className="flex items-center gap-1.5 px-3 py-1 rounded-full liquid-glass-pill text-[11px] font-medium text-white/70">
                <Sparkles className="w-3.5 h-3.5" style={{ color: activeAccent.color }} />
                <span>Zero Telemetry</span>
              </div>
            </div>
          </div>

          {/* Quick Links */}
          <div className="md:col-span-3 space-y-3">
            <h4 className="text-xs font-bold uppercase tracking-wider text-white/90">Navigation</h4>
            <ul className="space-y-2 text-sm text-white/60">
              <li>
                <a href="#overview" className="hover:text-white transition-colors">
                  Overview & Hero
                </a>
              </li>
              <li>
                <a href="#live-player" className="hover:text-white transition-colors">
                  Interactive Player Dock
                </a>
              </li>
              <li>
                <a href="#studio" className="hover:text-white transition-colors">
                  Studio Audio Trimmer
                </a>
              </li>
              <li>
                <a href="#features" className="hover:text-white transition-colors">
                  Engineering Features
                </a>
              </li>
              <li>
                <a href="#screenshots" className="hover:text-white transition-colors">
                  App Screenshots Gallery
                </a>
              </li>
              <li>
                <a href="#specs" className="hover:text-white transition-colors">
                  64-bit & 32-bit Specifications
                </a>
              </li>
            </ul>
          </div>

          {/* Downloads & Architectures */}
          <div className="md:col-span-4 space-y-3">
            <h4 className="text-xs font-bold uppercase tracking-wider text-white/90">Download Astra Music</h4>
            <div className="space-y-2.5">
              <button
                onClick={() => onOpenDownload('win-x64')}
                className="w-full p-3 rounded-2xl liquid-glass border border-white/10 hover:border-white/20 text-left flex items-center justify-between group transition-all"
              >
                <div className="flex items-center gap-3">
                  <Monitor className="w-4 h-4 text-white/80 group-hover:scale-110 transition-transform" />
                  <div>
                    <div className="text-xs font-semibold text-white">Windows 64-bit (x64)</div>
                    <div className="text-[10px] text-white/50">Native Release ZIP • 14.8 MB</div>
                  </div>
                </div>
                <Download className="w-4 h-4 text-white/40 group-hover:text-white transition-colors" />
              </button>

              <button
                onClick={() => onOpenDownload('win-x86')}
                className="w-full p-3 rounded-2xl liquid-glass border border-white/10 hover:border-white/20 text-left flex items-center justify-between group transition-all"
              >
                <div className="flex items-center gap-3">
                  <Monitor className="w-4 h-4 text-white/80 group-hover:scale-110 transition-transform" />
                  <div>
                    <div className="text-xs font-semibold text-white">Windows 32-bit (x86 Portable)</div>
                    <div className="text-[10px] text-white/50">Portable ZIP • 725 KB</div>
                  </div>
                </div>
                <Download className="w-4 h-4 text-white/40 group-hover:text-white transition-colors" />
              </button>

              <button
                onClick={() => onOpenDownload()}
                className="w-full p-2.5 rounded-xl bg-white/5 hover:bg-white/10 text-white/80 text-xs font-medium text-center transition-colors"
              >
                View all platforms (Android & Web PWA)
              </button>
            </div>
          </div>
        </div>

        {/* Bottom Credits & Legal */}
        <div className="pt-8 border-t border-white/8 flex flex-col sm:flex-row items-center justify-between gap-4 text-xs text-white/50">
          <div className="flex items-center gap-2">
            <span>Crafted with</span>
            <Heart className="w-3.5 h-3.5 text-rose-500 fill-rose-500 inline" />
            <span>by Mohan Sri Ram Kunamsetty</span>
          </div>

          <div className="flex items-center gap-6">
            <span>Open Source under MIT License</span>
            <span>Windows & Android Native</span>
          </div>
        </div>
      </div>
    </footer>
  );
};
