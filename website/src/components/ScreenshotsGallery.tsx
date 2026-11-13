import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Monitor, Smartphone, Maximize2, X, ChevronLeft, ChevronRight, Eye } from 'lucide-react';
import type { AccentColor } from '../types';

interface ScreenshotsGalleryProps {
  activeAccent: AccentColor;
}

interface ScreenshotItem {
  id: string;
  title: string;
  caption: string;
  category: 'desktop' | 'mobile';
  src: string;
  aspect: 'landscape' | 'portrait';
}

const SCREENSHOTS: ScreenshotItem[] = [
  {
    id: 'desk-home',
    title: 'Windows Desktop: Liquid Glass Shell',
    caption: 'Dynamic 3-pane glass hierarchy with real-time accent tinting, active queue, and responsive navigation sidebar.',
    category: 'desktop',
    src: '/screenshots/home.jpg',
    aspect: 'landscape'
  },
  {
    id: 'desk-search',
    title: 'Instant Local Library Search',
    caption: 'Fuzzy indexed search engine querying thousands of tracks, artists, albums, and genres in single milliseconds.',
    category: 'desktop',
    src: '/screenshots/search.jpg',
    aspect: 'landscape'
  },
  {
    id: 'mob-now-playing',
    title: 'Now Playing Liquid Canvas',
    caption: 'Full-screen immersive audio player with adaptive album-derived gradient meshes and haptic transport controls.',
    category: 'mobile',
    src: '/screenshots/02_now_playing.png',
    aspect: 'portrait'
  },
  {
    id: 'mob-home',
    title: 'Mobile Home & Recent Additions',
    caption: 'Card-based fluid discovery with continuous squircle corners, quick-play shortcuts, and library statistics.',
    category: 'mobile',
    src: '/screenshots/01_home.png',
    aspect: 'portrait'
  },
  {
    id: 'mob-library',
    title: 'Categorized Audio Library',
    caption: 'Hierarchical browsing across tracks, artists, albums, folders, and curated playlists with multi-sort filters.',
    category: 'mobile',
    src: '/screenshots/03_library.png',
    aspect: 'portrait'
  },
  {
    id: 'mob-studio',
    title: 'Studio Suite & Audio Tools',
    caption: 'Built-in audio workbench for ringtone creation, audio trimming, tag editing, and sample rate conversion.',
    category: 'mobile',
    src: '/screenshots/04_studio.png',
    aspect: 'portrait'
  },
  {
    id: 'mob-cutter',
    title: 'Waveform Ringtone Cutter',
    caption: 'Visual millisecond waveform trimming with draggable boundary handles and instant preview playback.',
    category: 'mobile',
    src: '/screenshots/05_cutter.png',
    aspect: 'portrait'
  },
  {
    id: 'mob-search',
    title: 'Mobile Real-Time Filter',
    caption: 'High-speed local query engine with category chips for instant audio discovery.',
    category: 'mobile',
    src: '/screenshots/06_search.png',
    aspect: 'portrait'
  }
];

export const ScreenshotsGallery: React.FC<ScreenshotsGalleryProps> = ({ activeAccent }) => {
  const [activeCategory, setActiveCategory] = useState<'desktop' | 'mobile'>('desktop');
  const [lightboxIndex, setLightboxIndex] = useState<number | null>(null);

  const filteredScreenshots = SCREENSHOTS.filter((item) => item.category === activeCategory);
  const [selectedIndex, setSelectedIndex] = useState(0);

  const currentItem = filteredScreenshots[selectedIndex] || filteredScreenshots[0];

  const handleCategoryChange = (cat: 'desktop' | 'mobile') => {
    setActiveCategory(cat);
    setSelectedIndex(0);
  };

  const openLightbox = (index: number) => {
    setLightboxIndex(index);
  };

  const closeLightbox = () => {
    setLightboxIndex(null);
  };

  const nextLightbox = () => {
    if (lightboxIndex !== null) {
      setLightboxIndex((lightboxIndex + 1) % filteredScreenshots.length);
    }
  };

  const prevLightbox = () => {
    if (lightboxIndex !== null) {
      setLightboxIndex(
        (lightboxIndex - 1 + filteredScreenshots.length) % filteredScreenshots.length
      );
    }
  };

  return (
    <section id="screenshots" className="relative py-28 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto">
      {/* Section Header */}
      <div className="text-center max-w-3xl mx-auto mb-16">
        <motion.div
          initial={{ opacity: 0, y: 15 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
          className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full liquid-glass-pill text-xs font-medium text-white/90 mb-4"
        >
          <Eye className="w-3.5 h-3.5" style={{ color: activeAccent.color }} />
          <span>Interactive Visual Gallery</span>
        </motion.div>

        <motion.h2
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5, delay: 0.1 }}
          className="text-3xl sm:text-4xl lg:text-5xl font-black text-white tracking-tight"
        >
          Every pixel crafted with{' '}
          <span
            className="transition-colors duration-500"
            style={{ color: activeAccent.color }}
          >
            tactile elegance
          </span>
        </motion.h2>

        <motion.p
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5, delay: 0.2 }}
          className="mt-4 text-base sm:text-lg text-white/60 leading-relaxed"
        >
          Explore actual screenshots from the native Windows Desktop app and its sister iOS-styled mobile experience.
        </motion.p>

        {/* Platform Selector Switch */}
        <div className="mt-8 inline-flex items-center p-1.5 rounded-2xl liquid-glass-dock border border-white/10 shadow-2xl">
          <button
            onClick={() => handleCategoryChange('desktop')}
            className={`flex items-center gap-2.5 px-6 py-2.5 rounded-xl font-medium text-sm transition-all duration-300 ${
              activeCategory === 'desktop'
                ? 'text-white shadow-lg'
                : 'text-white/60 hover:text-white'
            }`}
            style={{
              backgroundColor: activeCategory === 'desktop' ? activeAccent.color : 'transparent',
              boxShadow: activeCategory === 'desktop' ? `0 4px 20px ${activeAccent.glow}` : 'none'
            }}
          >
            <Monitor className="w-4 h-4" />
            <span>Windows Desktop (Liquid Glass)</span>
          </button>

          <button
            onClick={() => handleCategoryChange('mobile')}
            className={`flex items-center gap-2.5 px-6 py-2.5 rounded-xl font-medium text-sm transition-all duration-300 ${
              activeCategory === 'mobile'
                ? 'text-white shadow-lg'
                : 'text-white/60 hover:text-white'
            }`}
            style={{
              backgroundColor: activeCategory === 'mobile' ? activeAccent.color : 'transparent',
              boxShadow: activeCategory === 'mobile' ? `0 4px 20px ${activeAccent.glow}` : 'none'
            }}
          >
            <Smartphone className="w-4 h-4" />
            <span>Mobile Companion (iOS Fluid)</span>
          </button>
        </div>
      </div>

      {/* Featured Main Showcase Frame */}
      {currentItem && (
        <div className="relative">
          <AnimatePresence mode="wait">
            <motion.div
              key={currentItem.id}
              initial={{ opacity: 0, scale: 0.98, y: 15 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.98, y: -15 }}
              transition={{ duration: 0.4 }}
              className="relative rounded-3xl overflow-hidden liquid-glass-card p-3 sm:p-5 border border-white/15 shadow-2xl max-w-5xl mx-auto group cursor-pointer"
              onClick={() => openLightbox(selectedIndex)}
            >
              {/* Top macOS-style window controls */}
              <div className="flex items-center justify-between pb-3 px-3 border-b border-white/8 mb-3">
                <div className="flex items-center gap-2">
                  <span className="w-3 h-3 rounded-full bg-red-500/80 inline-block" />
                  <span className="w-3 h-3 rounded-full bg-yellow-500/80 inline-block" />
                  <span className="w-3 h-3 rounded-full bg-green-500/80 inline-block" />
                  <span className="ml-3 text-xs font-mono text-white/50">{currentItem.title}</span>
                </div>
                <div className="flex items-center gap-2 text-white/50 text-xs">
                  <span className="hidden sm:inline">Click to expand</span>
                  <Maximize2 className="w-4 h-4 text-white/70 group-hover:scale-110 transition-transform" />
                </div>
              </div>

              {/* Screenshot Media Container */}
              <div
                className={`relative rounded-2xl overflow-hidden bg-black/60 flex items-center justify-center ${
                  currentItem.aspect === 'landscape' ? 'max-h-[620px]' : 'max-h-[640px]'
                }`}
              >
                <img
                  src={currentItem.src}
                  alt={currentItem.title}
                  className={`w-full object-contain rounded-2xl shadow-inner transition-transform duration-500 group-hover:scale-[1.01] ${
                    currentItem.aspect === 'portrait' ? 'max-w-md h-auto' : 'h-auto max-h-[620px]'
                  }`}
                />

                {/* Hover overlay hint */}
                <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity duration-300 flex items-center justify-center pointer-events-none">
                  <div className="px-5 py-2.5 rounded-2xl liquid-glass text-white font-medium text-xs sm:text-sm flex items-center gap-2 shadow-2xl">
                    <Maximize2 className="w-4 h-4" />
                    <span>View Fullscreen Lightbox</span>
                  </div>
                </div>
              </div>

              {/* Caption Footer */}
              <div className="mt-4 px-3 flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                <div>
                  <h3 className="text-base font-bold text-white">{currentItem.title}</h3>
                  <p className="text-xs text-white/60 mt-0.5">{currentItem.caption}</p>
                </div>
                <div className="text-xs font-mono text-white/40 shrink-0">
                  {selectedIndex + 1} / {filteredScreenshots.length}
                </div>
              </div>
            </motion.div>
          </AnimatePresence>

          {/* Thumbnail Strip */}
          <div className="mt-8 flex items-center justify-center gap-3 overflow-x-auto pb-4 max-w-4xl mx-auto px-4">
            {filteredScreenshots.map((item, idx) => {
              const isSelected = selectedIndex === idx;
              return (
                <button
                  key={item.id}
                  onClick={() => setSelectedIndex(idx)}
                  className={`relative rounded-xl overflow-hidden transition-all duration-300 shrink-0 p-1 ${
                    isSelected ? 'scale-105' : 'opacity-50 hover:opacity-90'
                  }`}
                  style={{
                    border: `2px solid ${isSelected ? activeAccent.color : 'rgba(255, 255, 255, 0.1)'}`,
                    boxShadow: isSelected ? `0 0 16px ${activeAccent.glow}` : 'none'
                  }}
                >
                  <img
                    src={item.src}
                    alt={item.title}
                    className={`object-cover rounded-lg ${
                      item.aspect === 'portrait' ? 'w-14 h-24' : 'w-24 h-15'
                    }`}
                  />
                  <div className="absolute bottom-1 right-1 text-[9px] font-mono px-1 rounded bg-black/70 text-white/80">
                    {idx + 1}
                  </div>
                </button>
              );
            })}
          </div>
        </div>
      )}

      {/* Fullscreen Lightbox Modal */}
      <AnimatePresence>
        {lightboxIndex !== null && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-50 bg-black/90 backdrop-blur-2xl flex items-center justify-center p-4 sm:p-8"
            onClick={closeLightbox}
          >
            {/* Top Bar Controls */}
            <div className="absolute top-6 left-6 right-6 flex items-center justify-between z-10">
              <div className="text-white">
                <h4 className="text-sm sm:text-base font-bold">
                  {filteredScreenshots[lightboxIndex].title}
                </h4>
                <p className="text-xs text-white/50">
                  {filteredScreenshots[lightboxIndex].caption}
                </p>
              </div>
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  closeLightbox();
                }}
                className="p-2.5 rounded-full liquid-glass-pill hover:bg-white/20 text-white transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Navigation Arrows */}
            <button
              onClick={(e) => {
                e.stopPropagation();
                prevLightbox();
              }}
              className="absolute left-4 sm:left-8 top-1/2 -translate-y-1/2 p-3 rounded-full liquid-glass hover:bg-white/20 text-white transition-colors z-10"
            >
              <ChevronLeft className="w-6 h-6" />
            </button>

            <button
              onClick={(e) => {
                e.stopPropagation();
                nextLightbox();
              }}
              className="absolute right-4 sm:right-8 top-1/2 -translate-y-1/2 p-3 rounded-full liquid-glass hover:bg-white/20 text-white transition-colors z-10"
            >
              <ChevronRight className="w-6 h-6" />
            </button>

            {/* Main Lightbox Image */}
            <motion.div
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.9, opacity: 0 }}
              transition={{ type: 'spring', damping: 25, stiffness: 300 }}
              className="max-w-6xl max-h-[85vh] flex items-center justify-center"
              onClick={(e) => e.stopPropagation()}
            >
              <img
                src={filteredScreenshots[lightboxIndex].src}
                alt={filteredScreenshots[lightboxIndex].title}
                className="max-w-full max-h-[82vh] object-contain rounded-2xl shadow-2xl border border-white/10"
              />
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </section>
  );
};
