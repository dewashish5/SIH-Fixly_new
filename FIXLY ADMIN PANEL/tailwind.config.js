/** @type {import('tailwindcss').Config} */
export default {
  darkMode: 'class',
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#E6F4FA',
          100: '#CCE9F5',
          200: '#99D3EB',
          300: '#66BDE1',
          400: '#3398C5',
          500: '#01668F',
          600: '#015577',
          700: '#01455F',
          800: '#013548',
          900: '#012532',
          DEFAULT: '#01668F',
        },
        accent: {
          50: '#FFF3E6',
          100: '#FFE7CC',
          200: '#FFCF99',
          300: '#FFB766',
          400: '#FF8F33',
          500: '#FD6E01',
          600: '#DD6001',
          700: '#BC5101',
          800: '#9B4201',
          900: '#7A3401',
          DEFAULT: '#FD6E01',
        },
        brand: {
          // Maintaining old brand for compatibility if needed, but updating main surfaces
          50: '#f0fdf4',
          100: '#dcfce7',
          200: '#bbf7d0',
          300: '#86efac',
          400: '#4ade80',
          500: '#22c55e',
          600: '#16a34a',
          700: '#15803d',
          800: '#166534',
          900: '#14532d',
          DEFAULT: '#1e7e45',
          hover: '#176537',
          light: '#eaf7ee',
        },
        surface: {
          app: '#F8FAFB', // AppColors.background
          card: '#FFFFFF', // AppColors.surface
          sidebar: '#FFFFFF',
          border: '#E5E7EB', // AppColors.border
          subtle: '#E6F4FA', // AppColors.primary50
          dark: {
            app: '#0B1419', // AppColors.backgroundDark
            card: '#122029', // AppColors.surfaceDark
            sidebar: '#122029',
            border: '#1E3340', // AppColors.borderDark
            subtle: '#1A2C36', // AppColors.surfaceContainerDark
            elevated: '#243744', // AppColors.surfaceContainerHighDark
          }
        },
        text: {
          primary: '#17212B', // AppColors.textPrimary
          secondary: '#64748B', // AppColors.textSecondary
          muted: '#94A3B8', // AppColors.textMuted
          dark: {
            primary: '#F8FAFB', // AppColors.textPrimaryDark
            secondary: '#94A3B8', // AppColors.textSecondaryDark
            muted: '#64748B', // AppColors.textMutedDark
          }
        },
        status: {
          success: '#16A34A',
          warning: '#F59E0B',
          error: '#DC2626',
        }
      },
      fontFamily: {
        sans: ['"Plus Jakarta Sans"', 'Inter', 'sans-serif'],
      },
      boxShadow: {
        card: '0 1px 3px rgba(0, 0, 0, 0.02), 0 2px 8px rgba(18, 29, 22, 0.04)',
        hover: '0 8px 24px rgba(1, 102, 143, 0.08)',
        pill: '0 4px 14px rgba(1, 102, 143, 0.25)',
      },
      borderRadius: {
        'card': '16px',
        'badge': '9999px',
      }
    },
  },
  plugins: [],
}
