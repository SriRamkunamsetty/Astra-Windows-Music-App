/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        astra: {
          dark: '#000000',
          darkSurface: '#0B0B0E',
          darkCard: '#151518',
          darkCell: '#1C1C1E',
          accentRed: '#FA233B',
          accentPink: '#FF2D55',
          accentOrange: '#FF9500',
          accentYellow: '#FFCC00',
          accentGreen: '#34C759',
          accentBlue: '#007AFF',
          accentPurple: '#AF52DE',
          accentGraphite: '#8E8E93',
        }
      },
      fontFamily: {
        sans: ['Inter', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Roboto', 'sans-serif'],
      },
      backdropBlur: {
        xs: '2px',
        glass: '24px',
        'glass-lg': '40px',
      },
      animation: {
        'blob-spin': 'blobSpin 28s cubic-bezier(0.4, 0, 0.2, 1) infinite',
        'pulse-slow': 'pulseSlow 6s ease-in-out infinite',
        'float': 'float 4s ease-in-out infinite',
      },
      keyframes: {
        blobSpin: {
          '0%, 100%': { transform: 'translate(0px, 0px) scale(1)' },
          '33%': { transform: 'translate(30px, -50px) scale(1.15)' },
          '66%': { transform: 'translate(-20px, 20px) scale(0.9)' },
        },
        pulseSlow: {
          '0%, 100%': { opacity: '0.4' },
          '50%': { opacity: '0.85' },
        },
        float: {
          '0%, 100%': { transform: 'translateY(0px)' },
          '50%': { transform: 'translateY(-10px)' },
        }
      }
    },
  },
  plugins: [],
}
