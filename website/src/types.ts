export interface AccentColor {
  id: string;
  name: string;
  color: string;
  glow: string;
}

export const ACCENTS: AccentColor[] = [
  { id: 'blue', name: 'Blue', color: '#007AFF', glow: 'rgba(0, 122, 255, 0.45)' },
  { id: 'purple', name: 'Purple', color: '#AF52DE', glow: 'rgba(175, 82, 222, 0.45)' },
  { id: 'pink', name: 'Pink', color: '#FF2D55', glow: 'rgba(255, 45, 85, 0.45)' },
  { id: 'red', name: 'Red', color: '#FA233B', glow: 'rgba(250, 35, 59, 0.45)' },
  { id: 'orange', name: 'Orange', color: '#FF9500', glow: 'rgba(255, 149, 0, 0.45)' },
  { id: 'yellow', name: 'Yellow', color: '#FFCC00', glow: 'rgba(255, 204, 0, 0.45)' },
  { id: 'green', name: 'Green', color: '#34C759', glow: 'rgba(52, 199, 89, 0.45)' },
  { id: 'graphite', name: 'Graphite', color: '#8E8E93', glow: 'rgba(142, 142, 147, 0.45)' },
];

export interface TrackData {
  id: string;
  title: string;
  artist: string;
  album: string;
  duration: number; // in seconds
  src: string;
  coverGradient: [string, string];
  format: string;
  quality: string;
}

export const SAMPLE_TRACKS: TrackData[] = [
  {
    id: '0',
    title: 'Slow Orchard',
    artist: 'Mara Oake',
    album: 'Orchard Hours',
    duration: 36,
    src: '/samples/sample_0.mp3',
    coverGradient: ['#FF6B6B', '#C2185B'],
    format: 'FLAC',
    quality: 'Lossless'
  },
  {
    id: '1',
    title: 'Clay & Honey',
    artist: 'The Terracottas',
    album: 'Warm Clay',
    duration: 32,
    src: '/samples/sample_1.mp3',
    coverGradient: ['#FFB347', '#E5532D'],
    format: 'MP3',
    quality: '320 kbps'
  },
  {
    id: '2',
    title: 'Low Tide Letters',
    artist: 'Juniper Lane',
    album: 'Letters from Low Tide',
    duration: 40,
    src: '/samples/sample_2.mp3',
    coverGradient: ['#56CCF2', '#2F6FED'],
    format: 'WAV',
    quality: 'Lossless'
  },
  {
    id: '3',
    title: 'Marigold Hour',
    artist: 'Odd Moss',
    album: 'Marigold',
    duration: 30,
    src: '/samples/sample_3.mp3',
    coverGradient: ['#A18CD1', '#5B3FC0'],
    format: 'M4A',
    quality: '256 kbps'
  }
];

export interface DownloadOption {
  id: 'win-x64' | 'win-x86' | 'android' | 'web';
  title: string;
  subtitle: string;
  badge?: string;
  recommended?: boolean;
  size: string;
  file: string;
  arch: string;
  targetOS: string;
  iconName: string;
}

export const DOWNLOAD_OPTIONS: DownloadOption[] = [
  {
    id: 'win-x64',
    title: 'Windows 64-bit (x64 / ARM64)',
    subtitle: 'Native executable bundle for Windows 10 & 11',
    badge: 'Recommended',
    recommended: true,
    size: '14.8 MB',
    file: '/downloads/AstraMusic-Windows-x64.zip',
    arch: 'x86_64, ARM64 emulation',
    targetOS: 'Windows 10 / 11 (64-bit)',
    iconName: 'windows'
  },
  {
    id: 'win-x86',
    title: 'Windows 32-bit (x86 Portable)',
    subtitle: 'Stand-alone portable edition for legacy 32-bit PCs',
    size: '725 KB',
    file: '/downloads/AstraMusic-Windows-x86-Portable.zip',
    arch: '32-bit x86 compatible',
    targetOS: 'Windows 7, 8, 10 (32-bit)',
    iconName: 'monitor'
  },
  {
    id: 'android',
    title: 'Android Universal APK',
    subtitle: 'Direct installation package for phone & tablet',
    size: '22.4 MB',
    file: '/downloads/AstraMusic-Windows-x64.zip', // fallback link
    arch: 'arm64-v8a, armeabi-v7a',
    targetOS: 'Android 8.0+',
    iconName: 'smartphone'
  },
  {
    id: 'web',
    title: 'Web Version (PWA)',
    subtitle: 'Launch instantaneously in any browser',
    badge: 'No Install Needed',
    size: 'Instant',
    file: '#live-player',
    arch: 'Universal WebAssembly',
    targetOS: 'Any Modern Browser',
    iconName: 'globe'
  }
];
