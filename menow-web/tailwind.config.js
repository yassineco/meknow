/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        'bg-primary': '#0B0B0C',
        'bg-secondary': '#121214',
        'bg-tertiary': '#1E1E22',
        'text-primary': '#F3F3F3',
        'text-secondary': '#B5B5B5',
        'accent': '#F2C14E',
        'accent-dark': '#D4A73B',
        'border': '#1E1E22',
      },
      fontFamily: {
        display: ['Playfair Display', 'serif'],
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
}
