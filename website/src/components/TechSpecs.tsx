import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Cpu, 
  HelpCircle, 
  ChevronDown, 
  Check, 
  Layers 
} from 'lucide-react';
import type { AccentColor } from '../types';

interface TechSpecsProps {
  activeAccent: AccentColor;
  onOpenDownload: (archId?: 'win-x64' | 'win-x86') => void;
}

interface SpecRow {
  label: string;
  x64: string;
  x86: string;
  description: string;
}

const SPEC_ROWS: SpecRow[] = [
  {
    label: 'Target Architecture',
    x64: 'Native x86_64 / ARM64',
    x86: '32-bit x86 Portable / PWA',
    description: 'Hardware instruction set and execution mode'
  },
  {
    label: 'Engine Runtime',
    x64: 'Native Flutter C++ Engine',
    x86: 'Stand-alone Portable Runtime',
    description: 'Underlying runtime and rendering loop'
  },
  {
    label: 'Operating System',
    x64: 'Windows 10 / 11 (64-bit)',
    x86: 'Windows 7 / 8 / 10 / 11 (32-bit & 64-bit)',
    description: 'Compatible Windows editions'
  },
  {
    label: 'RAM Footprint',
    x64: '~45 MB (Ultralight)',
    x86: '~60 MB (Portable)',
    description: 'Idle memory consumption with active library'
  },
  {
    label: 'Audio Pipeline',
    x64: 'DirectSound / WASAPI Native',
    x86: 'High-Res WebAudio / WASAPI',
    description: 'Hardware audio output subsystem'
  },
  {
    label: 'Tag Extraction',
    x64: 'Pure Dart Chunked Parser',
    x86: 'Pure Dart WebAssembly Parser',
    description: 'ID3v1, ID3v2.2-2.4, Vorbis, MP4 atoms'
  },
  {
    label: 'Installation Required',
    x64: 'None (Zip / Standalone Exe)',
    x86: 'None (Portable / USB friendly)',
    description: 'Registry free, runs straight from extracted folder'
  },
  {
    label: 'Offline Capability',
    x64: '100% Air-Gapped Offline',
    x86: '100% Air-Gapped Offline',
    description: 'Zero telemetry, no internet connection required'
  }
];

const FAQS = [
  {
    q: 'How do 64-bit and 32-bit Windows support differ in Astra Music?',
    a: 'Astra Music provides tailored packages for both environments. For modern PCs running 64-bit Windows 10/11, the native x64 package compiles directly against Microsoft C++ and Flutter Windows runner for maximum hardware performance and sub-50MB RAM usage. For legacy machines running 32-bit Windows, we provide a stand-alone portable package and WebAssembly edition that runs everywhere without needing 64-bit CPU instructions or administrative privileges.'
  },
  {
    q: 'Do I need administrative privileges or an installer to run Astra Music?',
    a: 'No. Astra Music is 100% portable. You simply download the zip archive, extract it anywhere (such as your desktop, Documents, or a USB thumb drive), and double click "astra_music_windows.exe". It does not touch your Windows registry or install bloatware services.'
  },
  {
    q: 'How does the Pure-Dart ID3 tag parser work without native DLL dependencies?',
    a: 'Unlike traditional audio players that depend on bloated C++ libraries like TagLib or FFmpeg for simple tag reads, Astra Music contains a custom chunked binary reader (audio_tag_reader.dart). It opens local audio files with read-only byte streams, seeks directly to ID3v2 / Vorbis / MP4 atom headers, and extracts titles, artists, genres, and album artwork with zero external dynamic libraries.'
  },
  {
    q: 'Can Astra Music play high-resolution lossless audio files?',
    a: 'Yes. Astra Music supports bit-perfect 24-bit / 96kHz and 192kHz playback for FLAC, ALAC, WAV, and AIFF. It passes audio bitstreams directly through the Windows audio stack with gapless transitions and custom equalizer processing.'
  },
  {
    q: 'How does the Studio Audio Trimmer work?',
    a: 'The built-in Studio audio trimmer allows you to select any song from your library, inspect its visual waveform, place millisecond-precise start and end handles, configure audio fade-ins and fade-outs, and export custom clips or ringtones in M4A, MP3, or uncompressed WAV format.'
  },
  {
    q: 'Is my personal data or listening history sent to the cloud?',
    a: 'Never. Astra Music has zero analytics trackers, zero telemetry, and zero ads. Your library metadata, play counts, favorites, and playlists are stored locally on your device in human-readable JSON files.'
  }
];

export const TechSpecs: React.FC<TechSpecsProps> = ({ activeAccent, onOpenDownload }) => {
  const [openFaq, setOpenFaq] = useState<number | null>(0);

  const toggleFaq = (index: number) => {
    setOpenFaq(openFaq === index ? null : index);
  };

  return (
    <section id="specs" className="relative py-28 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto">
      {/* Section Header */}
      <div className="text-center max-w-3xl mx-auto mb-16">
        <motion.div
          initial={{ opacity: 0, y: 15 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
          className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full liquid-glass-pill text-xs font-medium text-white/90 mb-4"
        >
          <Cpu className="w-3.5 h-3.5" style={{ color: activeAccent.color }} />
          <span>Architecture & Compatibility</span>
        </motion.div>

        <motion.h2
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5, delay: 0.1 }}
          className="text-3xl sm:text-4xl lg:text-5xl font-black text-white tracking-tight"
        >
          Built for{' '}
          <span
            className="transition-colors duration-500"
            style={{ color: activeAccent.color }}
          >
            both 64-bit & 32-bit
          </span>{' '}
          Windows
        </motion.h2>

        <motion.p
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5, delay: 0.2 }}
          className="mt-4 text-base sm:text-lg text-white/60 leading-relaxed"
        >
          Whether you are running the newest Windows 11 high-refresh workstation or keeping a trusty 32-bit Windows laptop alive, Astra Music is engineered to deliver fluid 120 FPS audio playback.
        </motion.p>
      </div>

      {/* Comparison Table Card */}
      <motion.div
        initial={{ opacity: 0, y: 30 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true }}
        transition={{ duration: 0.6 }}
        className="rounded-3xl liquid-glass-card overflow-hidden border border-white/12 shadow-2xl mb-20"
      >
        {/* Table Header */}
        <div className="grid grid-cols-1 md:grid-cols-12 bg-white/5 border-b border-white/10 p-5 sm:p-6 text-sm font-bold text-white items-center">
          <div className="md:col-span-4 flex items-center gap-2 text-white/80">
            <Layers className="w-4 h-4" style={{ color: activeAccent.color }} />
            <span>Capability / Specification</span>
          </div>

          <div className="md:col-span-4 mt-3 md:mt-0 flex items-center justify-between md:justify-start gap-3">
            <div className="flex items-center gap-2">
              <span className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: activeAccent.color }} />
              <span className="font-semibold text-white">Windows 64-bit (x64)</span>
            </div>
            <span
              className="text-[10px] uppercase font-bold tracking-wider px-2 py-0.5 rounded-full text-white"
              style={{ backgroundColor: activeAccent.color }}
            >
              Native
            </span>
          </div>

          <div className="md:col-span-4 mt-3 md:mt-0 flex items-center justify-between md:justify-start gap-3">
            <div className="flex items-center gap-2">
              <span className="w-2.5 h-2.5 rounded-full bg-white/40" />
              <span className="font-semibold text-white/80">Windows 32-bit (x86)</span>
            </div>
            <span className="text-[10px] uppercase font-bold tracking-wider px-2 py-0.5 rounded-full bg-white/10 text-white/60">
              Portable
            </span>
          </div>
        </div>

        {/* Table Rows */}
        <div className="divide-y divide-white/6">
          {SPEC_ROWS.map((row) => (
            <div
              key={row.label}
              className="grid grid-cols-1 md:grid-cols-12 p-4 sm:p-5 text-sm hover:bg-white/[0.02] transition-colors items-center gap-2 md:gap-0"
            >
              {/* Feature info */}
              <div className="md:col-span-4">
                <div className="font-semibold text-white/90">{row.label}</div>
                <div className="text-xs text-white/40 mt-0.5">{row.description}</div>
              </div>

              {/* 64-bit column */}
              <div className="md:col-span-4 flex items-center gap-2 text-white/90 font-mono text-xs sm:text-sm">
                <Check className="w-4 h-4 shrink-0" style={{ color: activeAccent.color }} />
                <span>{row.x64}</span>
              </div>

              {/* 32-bit column */}
              <div className="md:col-span-4 flex items-center gap-2 text-white/70 font-mono text-xs sm:text-sm">
                <Check className="w-4 h-4 text-emerald-400 shrink-0" />
                <span>{row.x86}</span>
              </div>
            </div>
          ))}
        </div>

        {/* Table Footer Action Bar */}
        <div className="p-6 bg-white/[0.03] border-t border-white/10 flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="text-xs text-white/50 text-center sm:text-left">
            <span className="font-semibold text-white/80">Zero dependencies:</span> No .NET Framework runtime or Visual C++ redistributable setup wizard required.
          </div>
          <div className="flex items-center gap-3">
            <button
              onClick={() => onOpenDownload('win-x64')}
              className="px-5 py-2.5 rounded-xl text-xs font-semibold text-white transition-all hover:scale-105 active:scale-95 shadow-lg"
              style={{
                backgroundColor: activeAccent.color,
                boxShadow: `0 4px 15px ${activeAccent.glow}`
              }}
            >
              Download 64-bit (14.8 MB)
            </button>
            <button
              onClick={() => onOpenDownload('win-x86')}
              className="px-5 py-2.5 rounded-xl text-xs font-semibold text-white/80 liquid-glass hover:text-white transition-all hover:scale-105 active:scale-95"
            >
              Download 32-bit (725 KB)
            </button>
          </div>
        </div>
      </motion.div>

      {/* Frequently Asked Questions */}
      <div className="max-w-4xl mx-auto">
        <div className="text-center mb-10">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full liquid-glass-pill text-xs font-medium text-white/80 mb-3">
            <HelpCircle className="w-3.5 h-3.5" style={{ color: activeAccent.color }} />
            <span>Answers to Technical Questions</span>
          </div>
          <h3 className="text-2xl sm:text-3xl font-bold text-white">Frequently Asked Questions</h3>
        </div>

        <div className="space-y-4">
          {FAQS.map((faq, idx) => {
            const isOpen = openFaq === idx;
            return (
              <motion.div
                key={idx}
                initial={{ opacity: 0, y: 15 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.4, delay: idx * 0.05 }}
                className="rounded-2xl liquid-glass-card overflow-hidden border border-white/10 transition-all duration-300"
                style={{
                  borderColor: isOpen ? `${activeAccent.color}50` : 'rgba(255, 255, 255, 0.1)'
                }}
              >
                <button
                  onClick={() => toggleFaq(idx)}
                  className="w-full p-5 text-left flex items-center justify-between gap-4 group"
                >
                  <span className="font-semibold text-sm sm:text-base text-white group-hover:text-white/90">
                    {faq.q}
                  </span>
                  <div
                    className="p-1.5 rounded-full liquid-glass transition-transform duration-300 shrink-0"
                    style={{
                      transform: isOpen ? 'rotate(180deg)' : 'rotate(0deg)',
                      color: isOpen ? activeAccent.color : 'rgba(255,255,255,0.6)'
                    }}
                  >
                    <ChevronDown className="w-4 h-4" />
                  </div>
                </button>

                <AnimatePresence>
                  {isOpen && (
                    <motion.div
                      initial={{ height: 0, opacity: 0 }}
                      animate={{ height: 'auto', opacity: 1 }}
                      exit={{ height: 0, opacity: 0 }}
                      transition={{ duration: 0.3 }}
                    >
                      <div className="px-5 pb-5 pt-1 text-sm text-white/65 leading-relaxed border-t border-white/6">
                        {faq.a}
                      </div>
                    </motion.div>
                  )}
                </AnimatePresence>
              </motion.div>
            );
          })}
        </div>
      </div>
    </section>
  );
};
