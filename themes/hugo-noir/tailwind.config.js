
/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: 'class',
  content: [
    "./layouts/**/*.{html,js}",
    "../../layouts/**/*.{html,js}",
    "../../content/**/*.{md,html}",
  ],
  theme: {
    extend: {},
  },
  plugins: [
    require('@tailwindcss/typography'),
  ],
}

