import React, { useState, useRef, useEffect } from 'react';
import { motion } from 'framer-motion';
import {
  Play,
  Pause,
  SkipForward,
  SkipBack,
  Shuffle,
  Repeat,
  Volume2,
  VolumeX,
  Heart,
  Maximize2,
  Sparkles,
} from 'lucide-react';
import { SAMPLE_TRACKS } from '../types';
import type { AccentColor } from '../types';

interface LivePlayerMockupProps {
  accent: AccentColor;
  onOpenDownload: (arch?: 'win-x64' | 'win-x86') => void;
}

export const LivePlayerMockup: React.FC<LivePlayerMockupProps> = ({
  accent,
  onOpenDownload,
}) => {
  const [currentTrackIndex, setCurrentTrackIndex] = useState(0);
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(36);
  const [volume, setVolume] = useState(0.8);
  const [isMuted, setIsMuted] = useState(false);
  const [isShuffle, setIsShuffle] = useState(false);
  const [repeatMode, setRepeatMode] = useState<'off' | 'all' | 'one'>('off');
  const [speed, setSpeed] = useState(1.0);
  const [isFavorite, setIsFavorite] = useState(false);

  const audioRef = useRef<HTMLAudioElement | null>(null);
  const currentTrack = SAMPLE_TRACKS[currentTrackIndex];

  useEffect(() => {
    if (audioRef.current) {
      audioRef.current.playbackRate = speed;
      audioRef.current.volume = isMuted ? 0 : volume;
    }
  }, [speed, volume, isMuted]);

  const togglePlay = () => {
    if (!audioRef.current) return;
    if (isPlaying) {
      audioRef.current.pause();
      setIsPlaying(false);
    } else {
      audioRef.current.play().then(() => setIsPlaying(true)).catch(() => {});
    }
  };

  const nextTrack = () => {
    let nextIdx = currentTrackIndex + 1;
    if (isShuffle) {
      nextIdx = Math.floor(Math.random() * SAMPLE_TRACKS.length);
    } else if (nextIdx >= SAMPLE_TRACKS.length) {
      nextIdx = 0;
    }
    setCurrentTrackIndex(nextIdx);
    setCurrentTime(0);
    setIsPlaying(true);
  };

  const prevTrack = () => {
    if (currentTime > 3) {
      if (audioRef.current) audioRef.current.currentTime = 0;
      setCurrentTime(0);
      return;
    }
    const prevIdx = currentTrackIndex === 0 ? SAMPLE_TRACKS.length - 1 : currentTrackIndex - 1;
    setCurrentTrackIndex(prevIdx);
    setCurrentTime(0);
    setIsPlaying(true);
  };

  const handleTimeUpdate = () => {
    if (audioRef.current) {
      setCurrentTime(audioRef.current.currentTime);
      if (audioRef.current.duration && !isNaN(audioRef.current.duration)) {
        setDuration(audioRef.current.duration);
      }
    }
  };

  const handleSeek = (e: React.ChangeEvent<HTMLInputElement>) => {
    const time = parseFloat(e.target.value);
    setCurrentTime(time);
    if (audioRef.current) {
      audioRef.current.currentTime = time;
    }
  };

  const cycleSpeed = () => {
    const speeds = [1.0, 1.25, 1.5, 2.0, 0.75];
    const curIdx = speeds.indexOf(speed);
    const nextSpeed = speeds[(curIdx + 1) % speeds.length];
    setSpeed(nextSpeed);
  };

  const formatTime = (secs: number) => {
    const m = Math.floor(secs / 60);
    const s = Math.floor(secs % 60);
    return `${m}:${s.toString().padStart(2, '0')}`;
  };

  return (
    <section id="live-player" className="relative z-10 py-20 px-4 sm:px-8 max-w-6xl mx-auto">
      {/* Hidden audio element */}
      <audio
        ref={audioRef}
        src={currentTrack.src}
        onTimeUpdate={handleTimeUpdate}
        onEnded={nextTrack}
        autoPlay={isPlaying}
      />

      {/* Header */}
      <div className="text-center mb-12">
        <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full liquid-glass text-xs font-semibold uppercase tracking-wider text-white mb-4">
          <Sparkles className="w-3.5 h-3.5 text-blue-400" />
          <span>Interactive Live Player</span>
        </div>
        <h2 className="text-3xl sm:text-5xl font-extrabold tracking-tight text-white mb-4">
          Experience the Desktop Player Dock
        </h2>
        <p className="text-base sm:text-lg text-zinc-400 max-w-2xl mx-auto">
          Try the real audio playback engine, interactive scrubber, speed controls, and dynamic Liquid Glass aesthetics directly in your browser.
        </p>
      </div>

      {/* Interactive Mockup Window Container */}
      <motion.div
        className="liquid-glass-dock rounded-[32px] p-6 sm:p-8 specular-rim shadow-2xl relative overflow-hidden"
        initial={{ opacity: 0, y: 30 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true }}
        transition={{ duration: 0.6 }}
      >
        {/* Glow ambient background */}
        <div
          className="absolute -top-32 -left-32 w-80 h-80 rounded-full blur-[100px] pointer-events-none opacity-30 transition-colors duration-700"
          style={{ backgroundColor: accent.color }}
        />

        {/* Mac-style Window Bar Controls */}
        <div className="flex items-center justify-between pb-6 border-b border-white/10 mb-6">
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 rounded-full bg-[#FF5F56] border border-[#E0443E]" />
            <div className="w-3 h-3 rounded-full bg-[#FFBD2E] border border-[#DEA123]" />
            <div className="w-3 h-3 rounded-full bg-[#27C93F] border border-[#1AAB29]" />
            <span className="ml-3 text-xs font-medium text-zinc-400">Astra Music — Windows Desktop Edition</span>
          </div>

          <div className="flex items-center gap-2">
            <span
              className="text-[11px] font-bold uppercase tracking-wider px-2 py-0.5 rounded-full text-white"
              style={{ backgroundColor: accent.color }}
            >
              {currentTrack.quality}
            </span>
          </div>
        </div>

        {/* Track Showcase & Ambient Card */}
        <div className="grid md:grid-cols-12 gap-8 items-center mb-8">
          {/* Left Column: Big Vinyl / Cover Art with Pulse */}
          <div className="md:col-span-5 flex justify-center">
            <div className="relative group">
              <motion.div
                className="w-56 h-56 sm:w-64 sm:h-64 rounded-[28px] shadow-2xl overflow-hidden relative border border-white/20 p-1"
                animate={{ scale: isPlaying ? 1 : 0.94 }}
                transition={{ duration: 0.4 }}
              >
                <div
                  className="w-full h-full rounded-[24px] flex flex-col items-center justify-center p-6 text-center relative"
                  style={{
                    background: `linear-gradient(135deg, ${currentTrack.coverGradient[0]}, ${currentTrack.coverGradient[1]})`,
                  }}
                >
                  {/* Subtle vinyl radial highlight */}
                  <div className="absolute inset-0 rounded-[24px] bg-[radial-gradient(ellipse_at_top,_var(--tw-gradient-stops))] from-white/30 via-transparent to-transparent pointer-events-none" />

                  {/* Equalizer animation bars inside artwork */}
                  <div className="flex items-end justify-center gap-1.5 h-12 mb-3">
                    {[0, 1, 2, 3].map((bar) => (
                      <motion.div
                        key={bar}
                        className="w-2 bg-white rounded-full"
                        animate={{
                          height: isPlaying ? [12, 40, 18, 34, 12] : 10,
                        }}
                        transition={{
                          duration: 0.9,
                          repeat: Infinity,
                          repeatType: 'reverse',
                          delay: bar * 0.18,
                        }}
                      />
                    ))}
                  </div>

                  <span className="text-xl font-bold text-white tracking-tight drop-shadow-md">
                    {currentTrack.album}
                  </span>
                  <span className="text-xs text-white/80 font-medium mt-1">
                    Embedded ID3v2 APIC
                  </span>
                </div>
              </motion.div>
            </div>
          </div>

          {/* Right Column: Track Details & Interactive Track Selector */}
          <div className="md:col-span-7">
            <div className="flex items-start justify-between mb-4">
              <div>
                <span className="text-xs font-semibold text-zinc-400 uppercase tracking-widest block mb-1">
                  Now Playing
                </span>
                <h3 className="text-2xl sm:text-3xl font-bold text-white tracking-tight">
                  {currentTrack.title}
                </h3>
                <p className="text-base text-zinc-300 font-medium mt-0.5">
                  {currentTrack.artist} • <span className="text-zinc-400">{currentTrack.album}</span>
                </p>
              </div>

              <button
                onClick={() => setIsFavorite(!isFavorite)}
                className={`p-3 rounded-full transition-all ${
                  isFavorite ? 'bg-red-500/20 text-red-500 scale-110' : 'bg-white/5 text-zinc-400 hover:text-white'
                }`}
              >
                <Heart className={`w-6 h-6 ${isFavorite ? 'fill-current' : ''}`} />
              </button>
            </div>

            {/* Track Selector Pills */}
            <div className="mt-6">
              <span className="text-xs font-bold text-zinc-400 uppercase tracking-wider block mb-2.5">
                Sample Library
              </span>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                {SAMPLE_TRACKS.map((t, idx) => (
                  <button
                    key={t.id}
                    onClick={() => {
                      setCurrentTrackIndex(idx);
                      setCurrentTime(0);
                      setIsPlaying(true);
                    }}
                    className={`p-2.5 rounded-xl text-left border transition-all ${
                      currentTrackIndex === idx
                        ? 'bg-white/15 border-white/40 shadow-md'
                        : 'bg-white/[0.03] border-white/10 hover:bg-white/[0.08]'
                    }`}
                  >
                    <span className="text-xs font-bold text-white block truncate">{t.title}</span>
                    <span className="text-[11px] text-zinc-400 block truncate">{t.artist}</span>
                  </button>
                ))}
              </div>
            </div>
          </div>
        </div>

        {/* Bottom Persistent Dock Section (Pixel-matched to Flutter Desktop Player Bar) */}
        <div className="pt-6 border-t border-white/10">
          {/* Scrubber Bar */}
          <div className="space-y-1 mb-4">
            <input
              type="range"
              min="0"
              max={duration || 36}
              step="0.1"
              value={currentTime}
              onChange={handleSeek}
              className="w-full h-1.5 bg-white/20 rounded-lg appearance-none cursor-pointer accent-blue-500 hover:h-2.5 transition-all"
              style={{ accentColor: accent.color }}
            />
            <div className="flex justify-between text-xs text-zinc-400 font-mono">
              <span>{formatTime(currentTime)}</span>
              <span>-{formatTime(Math.max(0, duration - currentTime))}</span>
            </div>
          </div>

          {/* Controls Bar */}
          <div className="flex flex-wrap items-center justify-between gap-4">
            {/* Speed & Format Badge */}
            <div className="flex items-center gap-2">
              <button
                onClick={cycleSpeed}
                className="px-3 py-1.5 rounded-xl bg-white/10 hover:bg-white/15 text-xs font-bold text-white transition-colors"
                title="Cycle Playback Speed"
              >
                {speed}x
              </button>

              <span className="text-xs text-zinc-400 font-mono hidden sm:inline">
                {currentTrack.format} 44.1kHz
              </span>
            </div>

            {/* Transport Core Buttons */}
            <div className="flex items-center gap-4 sm:gap-6">
              <button
                onClick={() => setIsShuffle(!isShuffle)}
                className={`p-2 rounded-full transition-colors ${
                  isShuffle ? 'text-white' : 'text-zinc-500 hover:text-zinc-300'
                }`}
                style={isShuffle ? { color: accent.color } : {}}
              >
                <Shuffle className="w-4 h-4 sm:w-5 sm:h-5" />
              </button>

              <button
                onClick={prevTrack}
                className="p-2 rounded-full text-zinc-300 hover:text-white transition-colors"
              >
                <SkipBack className="w-5 h-5 sm:w-6 sm:h-6" />
              </button>

              {/* Central Big Play/Pause Button */}
              <button
                onClick={togglePlay}
                className="w-12 h-12 sm:w-14 sm:h-14 rounded-full flex items-center justify-center text-white shadow-xl hover:scale-105 active:scale-95 transition-all"
                style={{
                  backgroundColor: accent.color,
                  boxShadow: `0 8px 24px -2px ${accent.glow}`,
                }}
              >
                {isPlaying ? (
                  <Pause className="w-6 h-6 fill-current" />
                ) : (
                  <Play className="w-6 h-6 fill-current ml-0.5" />
                )}
              </button>

              <button
                onClick={nextTrack}
                className="p-2 rounded-full text-zinc-300 hover:text-white transition-colors"
              >
                <SkipForward className="w-5 h-5 sm:w-6 sm:h-6" />
              </button>

              <button
                onClick={() => {
                  const modes: ('off' | 'all' | 'one')[] = ['off', 'all', 'one'];
                  const next = modes[(modes.indexOf(repeatMode) + 1) % modes.length];
                  setRepeatMode(next);
                }}
                className={`p-2 rounded-full transition-colors ${
                  repeatMode !== 'off' ? 'text-white' : 'text-zinc-500 hover:text-zinc-300'
                }`}
                style={repeatMode !== 'off' ? { color: accent.color } : {}}
              >
                <Repeat className="w-4 h-4 sm:w-5 sm:h-5" />
              </button>
            </div>

            {/* Volume & Fullscreen */}
            <div className="flex items-center gap-3">
              <button
                onClick={() => setIsMuted(!isMuted)}
                className="text-zinc-400 hover:text-white transition-colors"
              >
                {isMuted || volume === 0 ? (
                  <VolumeX className="w-5 h-5" />
                ) : (
                  <Volume2 className="w-5 h-5" />
                )}
              </button>

              <input
                type="range"
                min="0"
                max="1"
                step="0.05"
                value={isMuted ? 0 : volume}
                onChange={(e) => {
                  setVolume(parseFloat(e.target.value));
                  setIsMuted(false);
                }}
                className="w-16 sm:w-20 h-1.5 bg-white/20 rounded-lg appearance-none cursor-pointer"
                style={{ accentColor: accent.color }}
              />

              <button
                onClick={() => onOpenDownload('win-x64')}
                className="p-2 text-zinc-400 hover:text-white transition-colors ml-1"
                title="Get Desktop App"
              >
                <Maximize2 className="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>
      </motion.div>
    </section>
  );
};
