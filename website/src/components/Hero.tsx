import React from 'react';
import { motion } from 'framer-motion';
import { Download, Shield, Cpu, Music2, ArrowRight, Laptop } from 'lucide-react';
import type { AccentColor } from '../types';

interface HeroProps {
  accent: AccentColor;
  onOpenDownload: (arch?: 'win-x64' | 'win-x86') => void;
}

export const Hero: React.FC<HeroProps> = ({ accent, onOpenDownload }) => {
  return (
    <section className="relative z-10 pt-32 pb-20 px-4 sm:px-8 max-w-7xl mx-auto flex flex-col items-center text-center">
      {/* Top Release Capsule Badge */}
      <motion.div
        initial={{ opacity: 0, y: -15 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="inline-flex items-center gap-2.5 px-4 py-1.5 rounded-full liquid-glass-pill mb-8 specular-rim"
      >
        <span
          className="w-2 h-2 rounded-full animate-ping inline-block"
          style={{ backgroundColor: accent.color }}
        />
        <span className="text-xs font-semibold text-zinc-300 tracking-wide">
          Astra Music for Windows 10 & 11 • Version 1.0.0
        </span>
      </motion.div>

      {/* Main Punchy Headline */}
      <motion.h1
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, delay: 0.1 }}
        className="text-4xl sm:text-6xl md:text-7xl lg:text-8xl font-black tracking-tight max-w-5xl liquid-gradient-text leading-[1.08] mb-6"
      >
        Pure Local Sound.
        <br />
        <span
          className="bg-clip-text text-transparent bg-gradient-to-r"
          style={{
            backgroundImage: `linear-gradient(to right, #FFFFFF, ${accent.color})`,
          }}
        >
          Liquid Glass
        </span>{' '}
        Fluidity.
      </motion.h1>

      {/* Subtitle */}
      <motion.p
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, delay: 0.2 }}
        className="text-base sm:text-xl text-zinc-400 max-w-2xl mx-auto leading-relaxed mb-10"
      >
        A high-performance native music player & local audio studio.
        Universal codec support, pure-Dart ID3v2 & FLAC album art extraction,
        and on-device FFmpeg tools. <strong>100% offline. Zero telemetry.</strong>
      </motion.p>

      {/* Primary Action Buttons */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, delay: 0.3 }}
        className="flex flex-col sm:flex-row items-center justify-center gap-4 w-full sm:w-auto mb-12"
      >
        {/* Antigravity-style primary download button */}
        <button
          onClick={() => onOpenDownload('win-x64')}
          className="w-full sm:w-auto px-8 py-4 rounded-2xl font-bold text-white text-base flex items-center justify-center gap-3 shadow-2xl hover:scale-105 active:scale-95 transition-all group"
          style={{
            backgroundColor: accent.color,
            boxShadow: `0 12px 35px -5px ${accent.glow}`,
          }}
        >
          <Download className="w-5 h-5 group-hover:translate-y-0.5 transition-transform" />
          <span>Download for Windows</span>
          <span className="text-xs bg-white/20 px-2 py-0.5 rounded-full font-mono">x64</span>
        </button>

        {/* 32-Bit / Other Architecture Selector button */}
        <button
          onClick={() => onOpenDownload('win-x86')}
          className="w-full sm:w-auto px-6 py-4 rounded-2xl font-semibold text-zinc-300 hover:text-white text-base liquid-glass border border-white/10 hover:border-white/25 flex items-center justify-center gap-2 transition-all active:scale-95"
        >
          <Laptop className="w-4 h-4 text-zinc-400" />
          <span>32-Bit / All Downloads</span>
          <ArrowRight className="w-4 h-4 text-zinc-400" />
        </button>
      </motion.div>

      {/* Feature Highlights Pills */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 0.8, delay: 0.4 }}
        className="flex flex-wrap items-center justify-center gap-6 sm:gap-10 text-xs sm:text-sm text-zinc-400"
      >
        <div className="flex items-center gap-2">
          <Shield className="w-4 h-4 text-emerald-400" />
          <span>Zero Telemetry & Offline-First</span>
        </div>
        <div className="flex items-center gap-2">
          <Cpu className="w-4 h-4 text-blue-400" />
          <span>Native DirectShow & FFmpeg</span>
        </div>
        <div className="flex items-center gap-2">
          <Music2 className="w-4 h-4 text-purple-400" />
          <span>FLAC, MP3, WAV, M4A Lossless</span>
        </div>
      </motion.div>

      {/* App Screenshots Hero Preview (Floating 3D Mockup) */}
      <motion.div
        initial={{ opacity: 0, y: 40 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.9, delay: 0.45 }}
        className="mt-16 w-full max-w-5xl rounded-[32px] overflow-hidden liquid-glass border border-white/20 p-2 sm:p-3 shadow-2xl relative specular-rim"
      >
        <div className="rounded-[26px] overflow-hidden bg-black relative aspect-[16/10] sm:aspect-[16/9]">
          <img
            src="/screenshots/home.jpg"
            alt="Astra Music Windows Desktop Interface"
            className="w-full h-full object-cover object-top"
          />
          {/* Subtle reflection overlay */}
          <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-transparent to-transparent pointer-events-none" />

          {/* Floating Callout Capsule */}
          <div className="absolute bottom-6 left-6 right-6 sm:left-8 sm:right-auto liquid-glass-pill rounded-2xl px-5 py-3.5 flex items-center justify-between gap-6 specular-rim">
            <div>
              <p className="text-xs font-bold text-white">Astra Music for Windows</p>
              <p className="text-[11px] text-zinc-400">Desktop Sidebar • Dock Player • Waveform Studio</p>
            </div>
            <button
              onClick={() => onOpenDownload('win-x64')}
              className="px-3.5 py-1.5 rounded-xl text-xs font-bold text-white shadow-md hover:opacity-90 transition-opacity"
              style={{ backgroundColor: accent.color }}
            >
              Get Free
            </button>
          </div>
        </div>
      </motion.div>
    </section>
  );
};
