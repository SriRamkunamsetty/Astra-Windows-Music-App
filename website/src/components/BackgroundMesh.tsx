import React from 'react';
import { motion } from 'framer-motion';
import type { AccentColor } from '../types';

interface BackgroundMeshProps {
  accent: AccentColor;
}

export const BackgroundMesh: React.FC<BackgroundMeshProps> = ({ accent }) => {
  return (
    <div className="fixed inset-0 pointer-events-none overflow-hidden z-0 bg-black">
      {/* Dynamic Colored Blobs */}
      <motion.div
        className="absolute -top-[20%] -left-[10%] w-[60vw] h-[60vw] rounded-full opacity-40 blur-[130px]"
        animate={{
          backgroundColor: accent.color,
          x: [0, 60, -30, 0],
          y: [0, -40, 50, 0],
          scale: [1, 1.15, 0.9, 1],
        }}
        transition={{
          duration: 22,
          repeat: Infinity,
          ease: 'easeInOut',
        }}
      />

      <motion.div
        className="absolute top-[35%] -right-[15%] w-[55vw] h-[55vw] rounded-full opacity-30 blur-[140px]"
        animate={{
          backgroundColor: '#AF52DE', // Secondary complementary purple
          x: [0, -80, 40, 0],
          y: [0, 60, -50, 0],
          scale: [1, 0.88, 1.1, 1],
        }}
        transition={{
          duration: 26,
          repeat: Infinity,
          ease: 'easeInOut',
        }}
      />

      <motion.div
        className="absolute -bottom-[20%] left-[25%] w-[50vw] h-[50vw] rounded-full opacity-25 blur-[120px]"
        animate={{
          backgroundColor: accent.color,
          x: [0, 40, -60, 0],
          y: [0, -50, 30, 0],
          scale: [0.95, 1.2, 1, 0.95],
        }}
        transition={{
          duration: 20,
          repeat: Infinity,
          ease: 'easeInOut',
        }}
      />

      {/* Subtle Noise Texture & Vignette Overlay */}
      <div 
        className="absolute inset-0 opacity-[0.035]"
        style={{
          backgroundImage: `radial-gradient(rgba(255, 255, 255, 0.8) 1px, transparent 1px)`,
          backgroundSize: '24px 24px',
        }}
      />
      <div className="absolute inset-0 bg-radial-vignette opacity-80" />
    </div>
  );
};
