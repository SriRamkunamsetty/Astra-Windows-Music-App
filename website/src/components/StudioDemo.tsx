import React, { useState } from 'react';
import { Scissors, Film, RefreshCw, Layers, Play, Pause, ChevronRight } from 'lucide-react';
import type { AccentColor } from '../types';

interface StudioDemoProps {
  accent: AccentColor;
  onOpenDownload: (arch?: 'win-x64' | 'win-x86') => void;
}

export const StudioDemo: React.FC<StudioDemoProps> = ({ accent, onOpenDownload }) => {
  const [activeTool, setActiveTool] = useState<'trim' | 'video' | 'conv' | 'merge'>('trim');
  const [startSec, setStartSec] = useState(4.2);
  const [endSec, setEndSec] = useState(18.6);
  const [format, setFormat] = useState('M4A');
  const [isPlayingPreview, setIsPlayingPreview] = useState(false);

  // Procedural waveform bars
  const totalDuration = 32.0;
  const barsCount = 48;
  const waveformBars = Array.from({ length: barsCount }, (_, i) => {
    const x = i / barsCount;
    const h = 0.2 + 0.8 * Math.abs(Math.sin(x * Math.PI * 4) * Math.cos(x * Math.PI * 2.5));
    return Math.max(0.12, Math.min(1.0, h));
  });

  const nudge = (isStart: boolean, delta: number) => {
    if (isStart) {
      setStartSec((prev) => Math.max(0, Math.min(endSec - 0.5, parseFloat((prev + delta).toFixed(1)))));
    } else {
      setEndSec((prev) => Math.min(totalDuration, Math.max(startSec + 0.5, parseFloat((prev + delta).toFixed(1)))));
    }
  };

  return (
    <section id="studio" className="relative z-10 py-24 px-4 sm:px-8 max-w-7xl mx-auto">
      {/* Section Header */}
      <div className="text-center mb-16">
        <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full liquid-glass text-xs font-semibold uppercase tracking-wider text-white mb-4">
          <Scissors className="w-3.5 h-3.5 text-orange-400" />
          <span>Local FFmpeg Studio</span>
        </div>
        <h2 className="text-3xl sm:text-5xl font-extrabold tracking-tight text-white mb-4">
          Powerful On-Device Audio Studio
        </h2>
        <p className="text-base sm:text-lg text-zinc-400 max-w-2xl mx-auto">
          Every edit, clip, crossfade, and conversion runs 100% locally on your computer via high-performance FFmpeg. Zero uploads, zero quality loss.
        </p>
      </div>

      <div className="grid lg:grid-cols-12 gap-8 items-start">
        {/* Left: Studio Tools Navigation Tabs */}
        <div className="lg:col-span-4 space-y-3">
          {[
            {
              id: 'trim',
              title: 'Waveform Cutter',
              desc: 'Sub-second audio trimming with draggable visual markers & preview.',
              icon: Scissors,
              color: '#FF9500',
            },
            {
              id: 'video',
              title: 'Video to Audio',
              desc: 'Extract lossless audio streams from MP4, MOV, MKV & WebM.',
              icon: Film,
              color: '#007AFF',
            },
            {
              id: 'conv',
              title: 'Format Converter',
              desc: 'Transcode between MP3, AAC, FLAC, WAV & OGG with custom bitrates.',
              icon: RefreshCw,
              color: '#34C759',
            },
            {
              id: 'merge',
              title: 'Audio Merger',
              desc: 'Concatenate multiple songs sequentially or with 2-second crossfade.',
              icon: Layers,
              color: '#AF52DE',
            },
          ].map((tool) => {
            const isSelected = activeTool === tool.id;
            const Icon = tool.icon;
            return (
              <div
                key={tool.id}
                onClick={() => setActiveTool(tool.id as any)}
                className={`p-4 sm:p-5 rounded-2xl cursor-pointer transition-all border relative overflow-hidden ${
                  isSelected
                    ? 'liquid-glass border-white/30 shadow-xl'
                    : 'bg-white/[0.02] border-white/5 hover:bg-white/[0.05] hover:border-white/10'
                }`}
              >
                {isSelected && (
                  <div
                    className="absolute left-0 top-0 bottom-0 w-1"
                    style={{ backgroundColor: tool.color }}
                  />
                )}
                <div className="flex items-start gap-3.5">
                  <div
                    className="w-10 h-10 rounded-xl flex items-center justify-center shrink-0 text-white shadow-md"
                    style={{ backgroundColor: tool.color }}
                  >
                    <Icon className="w-5 h-5" />
                  </div>
                  <div>
                    <h4 className="text-base font-bold text-white mb-0.5">{tool.title}</h4>
                    <p className="text-xs text-zinc-400 leading-relaxed">{tool.desc}</p>
                  </div>
                </div>
              </div>
            );
          })}
        </div>

        {/* Right: Interactive Live Tool Workspace */}
        <div className="lg:col-span-8">
          <div className="liquid-glass rounded-[32px] p-6 sm:p-8 specular-rim shadow-2xl relative overflow-hidden">
            {/* Header info */}
            <div className="flex items-center justify-between pb-6 border-b border-white/10 mb-6">
              <div>
                <h3 className="text-xl font-bold text-white">Waveform Trimmer & Slicer</h3>
                <p className="text-xs text-zinc-400 mt-0.5">Sample track: "Slow Orchard.mp3" • 44.1 kHz Stereo</p>
              </div>

              <div className="flex items-center gap-2">
                {['M4A', 'MP3', 'WAV'].map((fmt) => (
                  <button
                    key={fmt}
                    onClick={() => setFormat(fmt)}
                    className={`px-3 py-1 rounded-xl text-xs font-bold transition-all ${
                      format === fmt ? 'bg-white text-black shadow-md' : 'bg-white/10 text-zinc-400 hover:text-white'
                    }`}
                  >
                    {fmt}
                  </button>
                ))}
              </div>
            </div>

            {/* Visual Interactive Waveform */}
            <div className="bg-black/40 rounded-2xl p-6 border border-white/10 mb-6 relative">
              <div className="h-32 flex items-center justify-between gap-1 relative select-none">
                {waveformBars.map((h, i) => {
                  const barTime = (i / barsCount) * totalDuration;
                  const isInside = barTime >= startSec && barTime <= endSec;

                  return (
                    <div
                      key={i}
                      className="flex-1 h-full flex items-center justify-center cursor-pointer"
                      onClick={() => {
                        if (Math.abs(barTime - startSec) < Math.abs(barTime - endSec)) {
                          setStartSec(parseFloat(barTime.toFixed(1)));
                        } else {
                          setEndSec(parseFloat(barTime.toFixed(1)));
                        }
                      }}
                    >
                      <div
                        className="w-full rounded-full transition-all duration-150"
                        style={{
                          height: `${h * 100}%`,
                          backgroundColor: isInside ? accent.color : 'rgba(255, 255, 255, 0.15)',
                        }}
                      />
                    </div>
                  );
                })}

                {/* Left Drag Marker */}
                <div
                  className="absolute top-0 bottom-0 w-0.5 z-20 pointer-events-none"
                  style={{
                    left: `${(startSec / totalDuration) * 100}%`,
                    backgroundColor: '#FFFFFF',
                  }}
                >
                  <div
                    className="absolute -top-3 -left-3 w-6 h-6 rounded-full flex items-center justify-center text-[10px] font-bold text-white shadow-lg pointer-events-auto cursor-ew-resize"
                    style={{ backgroundColor: accent.color }}
                  >
                    S
                  </div>
                </div>

                {/* Right Drag Marker */}
                <div
                  className="absolute top-0 bottom-0 w-0.5 z-20 pointer-events-none"
                  style={{
                    left: `${(endSec / totalDuration) * 100}%`,
                    backgroundColor: '#FFFFFF',
                  }}
                >
                  <div
                    className="absolute -bottom-3 -left-3 w-6 h-6 rounded-full flex items-center justify-center text-[10px] font-bold text-white shadow-lg pointer-events-auto cursor-ew-resize"
                    style={{ backgroundColor: accent.color }}
                  >
                    E
                  </div>
                </div>
              </div>

              {/* Timestamp Readouts */}
              <div className="grid grid-cols-3 text-center pt-4 border-t border-white/10 mt-4">
                <div>
                  <span className="text-[11px] text-zinc-400 font-medium uppercase block">Start</span>
                  <span className="text-base font-bold text-white font-mono">{startSec.toFixed(1)}s</span>
                </div>
                <div>
                  <span className="text-[11px] text-zinc-400 font-medium uppercase block">Clip Length</span>
                  <span className="text-base font-bold text-blue-400 font-mono" style={{ color: accent.color }}>
                    {(endSec - startSec).toFixed(1)}s
                  </span>
                </div>
                <div>
                  <span className="text-[11px] text-zinc-400 font-medium uppercase block">End</span>
                  <span className="text-base font-bold text-white font-mono">{endSec.toFixed(1)}s</span>
                </div>
              </div>
            </div>

            {/* Precision Nudge Controls */}
            <div className="grid sm:grid-cols-2 gap-4 mb-6">
              <div className="liquid-glass-card rounded-2xl p-3.5 flex items-center justify-between">
                <span className="text-xs font-bold text-zinc-300">Start Nudge</span>
                <div className="flex items-center gap-2">
                  <button
                    onClick={() => nudge(true, -0.1)}
                    className="px-3 py-1.5 rounded-xl bg-white/10 hover:bg-white/20 text-xs font-bold text-white"
                  >
                    -0.1s
                  </button>
                  <button
                    onClick={() => nudge(true, 0.1)}
                    className="px-3 py-1.5 rounded-xl bg-white/10 hover:bg-white/20 text-xs font-bold text-white"
                  >
                    +0.1s
                  </button>
                </div>
              </div>

              <div className="liquid-glass-card rounded-2xl p-3.5 flex items-center justify-between">
                <span className="text-xs font-bold text-zinc-300">End Nudge</span>
                <div className="flex items-center gap-2">
                  <button
                    onClick={() => nudge(false, -0.1)}
                    className="px-3 py-1.5 rounded-xl bg-white/10 hover:bg-white/20 text-xs font-bold text-white"
                  >
                    -0.1s
                  </button>
                  <button
                    onClick={() => nudge(false, 0.1)}
                    className="px-3 py-1.5 rounded-xl bg-white/10 hover:bg-white/20 text-xs font-bold text-white"
                  >
                    +0.1s
                  </button>
                </div>
              </div>
            </div>

            {/* Actions: Preview & Download App */}
            <div className="flex flex-col sm:flex-row items-center gap-3">
              <button
                onClick={() => setIsPlayingPreview(!isPlayingPreview)}
                className="w-full sm:w-auto flex-1 py-3.5 px-6 rounded-2xl font-bold text-white liquid-glass border border-white/20 hover:bg-white/10 flex items-center justify-center gap-2 transition-all"
              >
                {isPlayingPreview ? <Pause className="w-4 h-4" /> : <Play className="w-4 h-4 ml-0.5" />}
                <span>{isPlayingPreview ? 'Stop Clip Preview' : 'Preview Cut Selection'}</span>
              </button>

              <button
                onClick={() => onOpenDownload('win-x64')}
                className="w-full sm:w-auto py-3.5 px-6 rounded-2xl font-bold text-white flex items-center justify-center gap-2 shadow-xl hover:opacity-95 transition-all"
                style={{
                  backgroundColor: accent.color,
                  boxShadow: `0 8px 24px -2px ${accent.glow}`,
                }}
              >
                <span>Export in Astra App</span>
                <ChevronRight className="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};
