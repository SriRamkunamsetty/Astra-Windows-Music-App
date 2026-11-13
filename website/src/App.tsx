import React, { useState } from 'react';
import { ACCENTS } from './types';
import type { AccentColor } from './types';
import { BackgroundMesh } from './components/BackgroundMesh';
import { Navbar } from './components/Navbar';
import { Hero } from './components/Hero';
import { LivePlayerMockup } from './components/LivePlayerMockup';
import { StudioDemo } from './components/StudioDemo';
import { Features } from './components/Features';
import { ScreenshotsGallery } from './components/ScreenshotsGallery';
import { TechSpecs } from './components/TechSpecs';
import { Footer } from './components/Footer';
import { DownloadModal } from './components/DownloadModal';

export const App: React.FC = () => {
  const [activeAccent, setActiveAccent] = useState<AccentColor>(ACCENTS[0]);
  const [isDownloadOpen, setIsDownloadOpen] = useState(false);
  const [downloadArch, setDownloadArch] = useState<'win-x64' | 'win-x86'>('win-x64');

  const handleOpenDownload = (arch: 'win-x64' | 'win-x86' = 'win-x64') => {
    setDownloadArch(arch);
    setIsDownloadOpen(true);
  };

  const handleCloseDownload = () => {
    setIsDownloadOpen(false);
  };

  return (
    <div className="relative min-h-screen bg-black text-white selection:bg-blue-500/30 selection:text-white font-sans overflow-x-hidden">
      {/* Dynamic Fluid Background Glowing Mesh */}
      <BackgroundMesh accent={activeAccent} />

      {/* Floating Liquid Glass Top Navigation Bar */}
      <Navbar
        currentAccent={activeAccent}
        onSelectAccent={setActiveAccent}
        onOpenDownload={handleOpenDownload}
      />

      {/* Main Content Flow */}
      <main className="relative z-10">
        {/* Hero Section */}
        <div id="overview">
          <Hero
            accent={activeAccent}
            onOpenDownload={handleOpenDownload}
          />
        </div>

        {/* Live Interactive Player Dock & Visualizer */}
        <LivePlayerMockup
          accent={activeAccent}
          onOpenDownload={handleOpenDownload}
        />

        {/* Studio Audio Trimmer Interactive Workbench */}
        <StudioDemo
          accent={activeAccent}
          onOpenDownload={handleOpenDownload}
        />

        {/* Core Architecture & Liquid Engineering Features */}
        <Features
          activeAccent={activeAccent}
          onOpenDownload={handleOpenDownload}
        />

        {/* Interactive App Screenshots Gallery with Lightbox */}
        <ScreenshotsGallery
          activeAccent={activeAccent}
        />

        {/* 64-bit & 32-bit Architecture Specs Matrix and FAQ */}
        <TechSpecs
          activeAccent={activeAccent}
          onOpenDownload={handleOpenDownload}
        />
      </main>

      {/* Liquid Glass Footer */}
      <Footer
        activeAccent={activeAccent}
        onOpenDownload={handleOpenDownload}
      />

      {/* Antigravity-Style Download Modal with Confetti & Direct Download */}
      <DownloadModal
        isOpen={isDownloadOpen}
        onClose={handleCloseDownload}
        accent={activeAccent}
        defaultArch={downloadArch}
      />
    </div>
  );
};

export default App;
