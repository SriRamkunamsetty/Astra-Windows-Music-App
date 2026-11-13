import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, Download, Monitor, ArrowRight, Sparkles, FolderArchive, Smartphone, Globe, RefreshCw, ChevronLeft } from 'lucide-react';
import confetti from 'canvas-confetti';
import { DOWNLOAD_OPTIONS } from '../types';
import type { AccentColor, DownloadOption } from '../types';

interface DownloadModalProps {
  isOpen: boolean;
  onClose: () => void;
  accent: AccentColor;
  defaultArch?: 'win-x64' | 'win-x86';
}

export const DownloadModal: React.FC<DownloadModalProps> = ({
  isOpen,
  onClose,
  accent,
  defaultArch = 'win-x64',
}) => {
  const [selectedOption, setSelectedOption] = useState<DownloadOption>(
    DOWNLOAD_OPTIONS.find((opt) => opt.id === defaultArch) || DOWNLOAD_OPTIONS[0]
  );
  const [downloadTriggered, setDownloadTriggered] = useState(false);
  const [downloadingName, setDownloadingName] = useState('');

  useEffect(() => {
    if (isOpen) {
      const match = DOWNLOAD_OPTIONS.find((opt) => opt.id === defaultArch);
      if (match) setSelectedOption(match);
      setDownloadTriggered(false);
    }
  }, [isOpen, defaultArch]);

  const triggerDownload = (option: DownloadOption) => {
    setDownloadingName(option.title);
    setDownloadTriggered(true);

    // Launch celebratory confetti
    confetti({
      particleCount: 80,
      spread: 70,
      origin: { y: 0.6 },
      colors: [accent.color, '#FFFFFF', '#AF52DE', '#FF2D55'],
    });

    // Programmatically trigger browser download
    const link = document.createElement('a');
    link.href = option.file;
    link.setAttribute('download', option.file.split('/').pop() || 'AstraMusic.zip');
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const handleReset = () => {
    setDownloadTriggered(false);
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-6 overflow-y-auto">
          {/* Backdrop Scrim with Blur */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="fixed inset-0 bg-black/75 backdrop-blur-md"
          />

          {/* Modal Container */}
          <motion.div
            initial={{ opacity: 0, scale: 0.94, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.94, y: 20 }}
            transition={{ type: 'spring', damping: 25, stiffness: 300 }}
            className="relative w-full max-w-2xl liquid-glass rounded-[32px] p-6 sm:p-8 z-10 overflow-hidden specular-rim"
          >
            {/* Ambient Corner Glow */}
            <div
              className="absolute -top-24 -right-24 w-56 h-56 rounded-full blur-[80px] pointer-events-none opacity-40"
              style={{ backgroundColor: accent.color }}
            />

            {/* Close Button */}
            <button
              onClick={onClose}
              className="absolute top-6 right-6 p-2 rounded-full bg-white/10 hover:bg-white/20 text-white/80 hover:text-white transition-colors"
            >
              <X className="w-5 h-5" />
            </button>

            {!downloadTriggered ? (
              <div>
                {/* Header */}
                <div className="flex items-center gap-3 mb-2">
                  <div
                    className="w-10 h-10 rounded-2xl flex items-center justify-center text-white shadow-lg"
                    style={{ backgroundColor: accent.color }}
                  >
                    <Download className="w-5 h-5" />
                  </div>
                  <div>
                    <h2 className="text-2xl font-bold text-white tracking-tight">Download Astra Music</h2>
                    <p className="text-sm text-zinc-400">Select your Windows architecture or platform</p>
                  </div>
                </div>

                {/* Architecture Selection Grid */}
                <div className="grid gap-3 my-6">
                  {DOWNLOAD_OPTIONS.map((opt) => {
                    const isSelected = selectedOption.id === opt.id;
                    return (
                      <div
                        key={opt.id}
                        onClick={() => setSelectedOption(opt)}
                        className={`cursor-pointer rounded-2xl p-4 transition-all duration-200 border relative overflow-hidden ${
                          isSelected
                            ? 'bg-white/[0.09] border-white/30 shadow-lg'
                            : 'bg-white/[0.03] border-white/10 hover:bg-white/[0.06] hover:border-white/20'
                        }`}
                      >
                        {isSelected && (
                          <div
                            className="absolute left-0 top-0 bottom-0 w-1"
                            style={{ backgroundColor: accent.color }}
                          />
                        )}

                        <div className="flex items-center justify-between">
                          <div className="flex items-center gap-3.5">
                            <div
                              className={`w-10 h-10 rounded-xl flex items-center justify-center transition-colors ${
                                isSelected ? 'bg-white/20 text-white' : 'bg-white/5 text-zinc-400'
                              }`}
                            >
                              {opt.id === 'win-x64' && <Monitor className="w-5 h-5" />}
                              {opt.id === 'win-x86' && <FolderArchive className="w-5 h-5" />}
                              {opt.id === 'android' && <Smartphone className="w-5 h-5" />}
                              {opt.id === 'web' && <Globe className="w-5 h-5" />}
                            </div>

                            <div>
                              <div className="flex items-center gap-2">
                                <span className="font-semibold text-white text-base">{opt.title}</span>
                                {opt.badge && (
                                  <span
                                    className="px-2 py-0.5 rounded-full text-xs font-bold text-white tracking-wide"
                                    style={{ backgroundColor: accent.color }}
                                  >
                                    {opt.badge}
                                  </span>
                                )}
                              </div>
                              <p className="text-xs text-zinc-400 mt-0.5">{opt.subtitle}</p>
                            </div>
                          </div>

                          <div className="text-right pl-3">
                            <span className="text-xs font-medium text-zinc-400 block">{opt.size}</span>
                            <span className="text-[11px] text-zinc-500">{opt.targetOS}</span>
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>

                {/* Selected Spec Overview */}
                <div className="rounded-xl bg-white/[0.02] border border-white/5 p-3.5 mb-6 text-xs text-zinc-400 flex items-center justify-between">
                  <span>Architecture: <strong className="text-zinc-200">{selectedOption.arch}</strong></span>
                  <span>Direct Download • No Installer Bloatware</span>
                </div>

                {/* Download Action Button */}
                <div className="flex items-center gap-3">
                  <button
                    onClick={() => triggerDownload(selectedOption)}
                    className="flex-1 py-4 px-6 rounded-2xl font-bold text-white flex items-center justify-center gap-2 shadow-xl hover:opacity-95 active:scale-[0.98] transition-all"
                    style={{
                      backgroundColor: accent.color,
                      boxShadow: `0 10px 30px -5px ${accent.glow}`,
                    }}
                  >
                    <Download className="w-5 h-5" />
                    <span>Download {selectedOption.title.split('(')[0]}</span>
                    <ArrowRight className="w-4 h-4 ml-1" />
                  </button>

                  <button
                    onClick={onClose}
                    className="py-4 px-5 rounded-2xl font-medium text-zinc-400 hover:text-white bg-white/5 hover:bg-white/10 transition-colors"
                  >
                    Cancel
                  </button>
                </div>
              </div>
            ) : (
              /* Post-Download Confirmation & Next Steps Screen */
              <div className="text-center py-4">
                <div
                  className="w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4 text-white shadow-xl"
                  style={{ backgroundColor: accent.color }}
                >
                  <Sparkles className="w-8 h-8" />
                </div>

                <h3 className="text-2xl font-bold text-white mb-1">Your Download Has Started!</h3>
                <p className="text-sm text-zinc-400 mb-6">
                  Downloading <strong className="text-zinc-200">{downloadingName}</strong>
                </p>

                {/* Step-by-Step Instructions */}
                <div className="text-left bg-white/[0.04] rounded-2xl p-5 border border-white/10 mb-6 space-y-3.5">
                  <div className="flex items-start gap-3">
                    <span className="w-6 h-6 rounded-full bg-white/10 text-xs font-bold flex items-center justify-center text-white shrink-0 mt-0.5">
                      1
                    </span>
                    <div>
                      <h4 className="text-sm font-semibold text-white">Extract the Zip Archive</h4>
                      <p className="text-xs text-zinc-400">Right-click the downloaded file and choose "Extract All...".</p>
                    </div>
                  </div>

                  <div className="flex items-start gap-3">
                    <span className="w-6 h-6 rounded-full bg-white/10 text-xs font-bold flex items-center justify-center text-white shrink-0 mt-0.5">
                      2
                    </span>
                    <div>
                      <h4 className="text-sm font-semibold text-white">Launch Astra Music</h4>
                      <p className="text-xs text-zinc-400">Double-click <code className="text-blue-400 bg-white/5 px-1 py-0.5 rounded">astra_music_windows.exe</code> to start.</p>
                    </div>
                  </div>

                  <div className="flex items-start gap-3">
                    <span className="w-6 h-6 rounded-full bg-white/10 text-xs font-bold flex items-center justify-center text-white shrink-0 mt-0.5">
                      3
                    </span>
                    <div>
                      <h4 className="text-sm font-semibold text-white">Instant Offline Audio</h4>
                      <p className="text-xs text-zinc-400">Your local music files in your Music folder are automatically indexed.</p>
                    </div>
                  </div>
                </div>

                <div className="flex items-center justify-between text-xs text-zinc-400">
                  <div className="flex items-center gap-3">
                    <button
                      onClick={handleReset}
                      className="flex items-center gap-1 text-zinc-400 hover:text-white transition-colors"
                    >
                      <ChevronLeft className="w-3.5 h-3.5" />
                      <span>Back to versions</span>
                    </button>
                    <span className="text-zinc-600">•</span>
                    <button
                      onClick={() => triggerDownload(selectedOption)}
                      className="flex items-center gap-1.5 text-zinc-300 hover:text-white transition-colors"
                    >
                      <RefreshCw className="w-3.5 h-3.5" />
                      <span>Retry download</span>
                    </button>
                  </div>

                  <button
                    onClick={onClose}
                    className="py-2.5 px-5 rounded-xl font-semibold text-white bg-white/10 hover:bg-white/20 transition-all"
                  >
                    Done
                  </button>
                </div>
              </div>
            )}
          </motion.div>
        </div>
      )}
    </AnimatePresence>
  );
};
