import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { 
  Sparkles, 
  Cpu, 
  ShieldCheck, 
  Sliders, 
  Music2, 
  Command, 
  Zap, 
  CheckCircle2,
  Lock
} from 'lucide-react';
import type { AccentColor } from '../types';

interface FeaturesProps {
  activeAccent: AccentColor;
  onOpenDownload: () => void;
}

interface FeatureItem {
  icon: React.ElementType;
  title: string;
  badge: string;
  tagline: string;
  description: string;
  highlights: string[];
  techSpec: string;
}

export const Features: React.FC<FeaturesProps> = ({ activeAccent, onOpenDownload }) => {
  const [hoveredCard, setHoveredCard] = useState<number | null>(null);

  const features: FeatureItem[] = [
    {
      icon: Sparkles,
      title: 'iOS Liquid Glass Material Engine',
      badge: 'Visuals',
      tagline: 'Specular rims, real-time depth, continuous squircles',
      description:
        'Crafted from the ground up using custom Flutter shaders and layered canvas rendering. Dynamic frosted glass responds smoothly to your system accent and extracts complementary ambient palettes from the playing album art.',
      highlights: [
        '8 dynamic accent colors matching macOS Sonoma & iOS 18',
        'Multi-layer backdrop blur with customizable opacity (12px - 28px)',
        'Specular rim highlights that reflect ambient mouse movement',
        'Ultra-fluid spring physics running at a locked 120 FPS'
      ],
      techSpec: 'Custom Dart GlassContainer & BackdropFilter'
    },
    {
      icon: Cpu,
      title: 'Pure Dart Zero-Dep ID3 Parser',
      badge: 'Performance',
      tagline: 'Lightning fast tag extraction without heavy native C++ binaries',
      description:
        'A battle-tested binary parser implemented purely in Dart. Reads ID3v2.2, ID3v2.3, ID3v2.4 syncsafe integers, Vorbis comments, and MP4 atom hierarchies with minimal memory allocation.',
      highlights: [
        'Parses 1,000+ local music files in under 1.2 seconds',
        'Extracts embedded APIC / covr album artwork on the fly',
        'Handles broken and non-standard tags gracefully without crashing',
        'Zero bloat: no external C/C++ native dynamic link libraries needed'
      ],
      techSpec: 'audio_tag_reader.dart chunked byte streaming'
    },
    {
      icon: ShieldCheck,
      title: '100% Offline & Private Library',
      badge: 'Privacy',
      tagline: 'Your music stays on your disk. No telemetry, no accounts.',
      description:
        'Astra Music never connects to third-party telemetry servers or ad networks. Your audio collection, listening statistics, favorite songs, and playlists are stored exclusively on your local machine.',
      highlights: [
        'Zero data collection, tracking, or network telemetry calls',
        'Local JSON/SQLite metadata caching for near-instant boot times',
        'Folder watcher monitors your library for new additions in real-time',
        'Complete user control: wipe or export your data anytime'
      ],
      techSpec: 'Local-first encrypted JSON persistence'
    },
    {
      icon: Sliders,
      title: 'Built-in Audio Studio & Waveform Trimmer',
      badge: 'Studio Tool',
      tagline: 'Millisecond-accurate trimming, ringtones, and stems',
      description:
        'Integrated waveform trimmer with draggable start/end handles, customizable fade-in/fade-out envelopes, and multi-format audio rendering directly within the desktop application.',
      highlights: [
        'Draggable interactive waveform visualization with fine nudge controls',
        'Customizable 0.1s to 5.0s logarithmic audio fade curves',
        'Lossless trimming with instant ringtone and notification exports',
        'Export formats: M4A (AAC), MP3 (320kbps), and uncompressed WAV'
      ],
      techSpec: 'StudioTrimmer & background job pipeline'
    },
    {
      icon: Music2,
      title: 'Universal High-Resolution Audio Engine',
      badge: 'Acoustics',
      tagline: 'Bit-perfect playback for audiophile formats up to 24-bit / 192kHz',
      description:
        'Engineered for true audiophile fidelity. Supports lossless FLAC, ALAC, WAV, AIFF, alongside standard MP3, AAC, and OGG formats with smooth gapless transitions and pitch-locked speed modulation.',
      highlights: [
        'Bit-perfect bitstream passthrough for high-res DACs',
        'Seamless gapless playback with smart crossfade options',
        'Granular playback speed controls from 0.5x to 2.5x without pitch shift',
        'Precise 10-band graphic equalizer with pre-tuned acoustic presets'
      ],
      techSpec: 'DirectSound / WASAPI audio pipeline'
    },
    {
      icon: Command,
      title: 'Spotlight-Style Command Palette',
      badge: 'Productivity',
      tagline: 'Navigate your entire library with Ctrl+K without lifting your hands',
      description:
        'Power keyboard users rejoice. Press Ctrl+K (or Cmd+K) to open the floating frosted command palette. Search songs, trigger playback, adjust volume, switch accent themes, or run studio tools in milliseconds.',
      highlights: [
        'Instant fuzzy search across titles, artists, albums, and playlists',
        'Deep action commands: "Theme: Pink", "Export Clip", "Clear Queue"',
        'Full keyboard navigation with arrow keys and Enter triggers',
        'Vim-friendly shortcuts for play, pause, next, volume, and mute'
      ],
      techSpec: 'commands.dart action dispatcher'
    }
  ];

  return (
    <section id="features" className="relative py-28 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto">
      {/* Section Header */}
      <div className="text-center max-w-3xl mx-auto mb-20">
        <motion.div
          initial={{ opacity: 0, y: 15 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
          className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full liquid-glass-pill text-xs font-medium text-white/90 mb-4"
        >
          <Zap className="w-3.5 h-3.5" style={{ color: activeAccent.color }} />
          <span>Engineered for Perfection</span>
        </motion.div>

        <motion.h2
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5, delay: 0.1 }}
          className="text-3xl sm:text-4xl lg:text-5xl font-black text-white tracking-tight"
        >
          Liquid aesthetics meet{' '}
          <span
            className="transition-colors duration-500"
            style={{ color: activeAccent.color }}
          >
            extreme engineering
          </span>
        </motion.h2>

        <motion.p
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5, delay: 0.2 }}
          className="mt-4 text-base sm:text-lg text-white/60 leading-relaxed"
        >
          Astra Music isn't just an audio player. It is a handcrafted native audio experience 
          designed with Apple-grade tactile feedback, zero bloat, and complete local privacy.
        </motion.p>
      </div>

      {/* Grid of Feature Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 sm:gap-8">
        {features.map((feature, idx) => {
          const Icon = feature.icon;
          const isHovered = hoveredCard === idx;

          return (
            <motion.div
              key={feature.title}
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5, delay: idx * 0.1 }}
              onMouseEnter={() => setHoveredCard(idx)}
              onMouseLeave={() => setHoveredCard(null)}
              className="group relative rounded-3xl p-7 liquid-glass-card flex flex-col justify-between transition-all duration-500 hover:translate-y-[-6px]"
              style={{
                borderColor: isHovered ? `${activeAccent.color}60` : 'rgba(255, 255, 255, 0.12)',
                boxShadow: isHovered
                  ? `0 20px 40px -15px ${activeAccent.glow}, 0 0 20px 0 ${activeAccent.color}20`
                  : '0 8px 32px 0 rgba(0, 0, 0, 0.4)'
              }}
            >
              {/* Subtle accent hover glow behind card */}
              <div
                className="absolute inset-0 rounded-3xl opacity-0 group-hover:opacity-10 pointer-events-none transition-opacity duration-500"
                style={{
                  background: `radial-gradient(circle at 50% 0%, ${activeAccent.color}, transparent 70%)`
                }}
              />

              <div>
                {/* Header: Icon & Badge */}
                <div className="flex items-center justify-between mb-6">
                  <div
                    className="w-13 h-13 rounded-2xl flex items-center justify-center transition-all duration-500"
                    style={{
                      background: isHovered
                        ? `linear-gradient(135deg, ${activeAccent.color}40, rgba(255,255,255,0.08))`
                        : 'rgba(255, 255, 255, 0.06)',
                      border: `1px solid ${isHovered ? activeAccent.color : 'rgba(255, 255, 255, 0.12)'}`,
                      boxShadow: isHovered ? `0 0 16px ${activeAccent.glow}` : 'none'
                    }}
                  >
                    <Icon
                      className="w-6 h-6 transition-colors duration-500"
                      style={{ color: isHovered ? activeAccent.color : '#ffffff' }}
                    />
                  </div>

                  <span
                    className="text-[11px] font-semibold uppercase tracking-wider px-2.5 py-1 rounded-full border"
                    style={{
                      backgroundColor: 'rgba(255, 255, 255, 0.04)',
                      borderColor: 'rgba(255, 255, 255, 0.12)',
                      color: isHovered ? activeAccent.color : 'rgba(255, 255, 255, 0.6)'
                    }}
                  >
                    {feature.badge}
                  </span>
                </div>

                {/* Title & Tagline */}
                <h3 className="text-xl font-bold text-white group-hover:text-white transition-colors">
                  {feature.title}
                </h3>
                <p
                  className="text-xs font-medium mt-1 mb-3 transition-colors duration-300"
                  style={{ color: isHovered ? activeAccent.color : 'rgba(255, 255, 255, 0.5)' }}
                >
                  {feature.tagline}
                </p>

                {/* Description */}
                <p className="text-sm text-white/60 leading-relaxed mb-5">
                  {feature.description}
                </p>

                {/* Highlights List */}
                <ul className="space-y-2 mb-6">
                  {feature.highlights.map((highlight, hIdx) => (
                    <li key={hIdx} className="flex items-start gap-2 text-xs text-white/75">
                      <CheckCircle2
                        className="w-3.5 h-3.5 mt-0.5 shrink-0 transition-colors duration-300"
                        style={{ color: activeAccent.color }}
                      />
                      <span>{highlight}</span>
                    </li>
                  ))}
                </ul>
              </div>

              {/* Bottom Tech Spec Pill */}
              <div className="pt-4 border-t border-white/8 flex items-center justify-between text-[11px] text-white/40">
                <span className="font-mono">{feature.techSpec}</span>
                <span className="text-[10px] tracking-wider uppercase font-semibold text-white/30">Verified</span>
              </div>
            </motion.div>
          );
        })}
      </div>

      {/* Micro Interactive Banner */}
      <motion.div
        initial={{ opacity: 0, y: 30 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true }}
        transition={{ duration: 0.6, delay: 0.3 }}
        className="mt-16 rounded-3xl p-8 liquid-glass-card relative overflow-hidden flex flex-col md:flex-row items-center justify-between gap-6"
      >
        <div className="flex items-center gap-5">
          <div
            className="w-14 h-14 rounded-2xl flex items-center justify-center shrink-0 border"
            style={{
              backgroundColor: 'rgba(255, 255, 255, 0.05)',
              borderColor: `${activeAccent.color}50`,
              boxShadow: `0 0 24px ${activeAccent.glow}`
            }}
          >
            <Lock className="w-7 h-7" style={{ color: activeAccent.color }} />
          </div>
          <div>
            <h4 className="text-lg font-bold text-white">Your music library belongs solely to you</h4>
            <p className="text-sm text-white/60 mt-1 max-w-xl">
              No account creation. No credit card. No internet telemetry. Just pure audio running at peak native performance on Windows.
            </p>
          </div>
        </div>

        <button
          onClick={onOpenDownload}
          className="shrink-0 px-6 py-3 rounded-2xl font-semibold text-sm text-white transition-all duration-300 hover:scale-105 active:scale-95 flex items-center gap-2 shadow-lg"
          style={{
            backgroundColor: activeAccent.color,
            boxShadow: `0 10px 25px -5px ${activeAccent.glow}`
          }}
        >
          <Sparkles className="w-4 h-4" />
          <span>Download Astra Music</span>
        </button>
      </motion.div>
    </section>
  );
};
