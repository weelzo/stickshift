#!/bin/zsh
# Regenerates every logo file in assets/ from one drawing.
# light = black (for light backgrounds), dark = white (for dark backgrounds).
# The mark: a slim Fire TV-style remote whose top button is an AI sparkle and whose
# direction ring holds a terminal prompt (>_). Needs rsvg-convert (brew install librsvg).
set -euo pipefail
cd "${0:A:h}/../assets"

mark() {  # $1 = color
cat <<EOF
  <g fill="$1">
    <!-- remote body; holes: sparkle button, direction ring, three buttons, volume rocker -->
    <path fill-rule="evenodd" d="M64 4a24 24 0 0 1 24 24v72a24 24 0 0 1-48 0V28A24 24 0 0 1 64 4ZM64 11Q64 20 73 20Q64 20 64 29Q64 20 55 20Q64 20 64 11ZM82 52a18 18 0 1 0-36 0a18 18 0 1 0 36 0ZM55.5 84a3.5 3.5 0 1 0-7 0a3.5 3.5 0 1 0 7 0ZM67.5 84a3.5 3.5 0 1 0-7 0a3.5 3.5 0 1 0 7 0ZM79.5 84a3.5 3.5 0 1 0-7 0a3.5 3.5 0 1 0 7 0ZM64 97a4 4 0 0 1 4 4v10a4 4 0 0 1-8 0v-10a4 4 0 0 1 4-4Z"/>
    <!-- terminal prompt inside the ring -->
    <path d="M54 45l7 7-7 7M64 60h10" fill="none" stroke="$1" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
  </g>
EOF
}

word() { echo "  <text x=\"106\" y=\"84\" fill=\"$1\" font-family=\"ui-sans-serif, -apple-system, BlinkMacSystemFont, 'Helvetica Neue', Helvetica, Arial, sans-serif\" font-size=\"54\" font-weight=\"800\" letter-spacing=\"-1\">Stickshift</text>"; }

for v in light:#111111 dark:#f5f5f5; do
  name=${v%%:*}; col=${v#*:}
  { echo '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" role="img" aria-label="Stickshift">'; mark $col; echo '</svg>'; } > logo-mark-$name.svg
  { echo '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 410 128" role="img" aria-label="Stickshift">'; mark $col; word $col; echo '</svg>'; } > logo-$name.svg
  rsvg-convert -h 512 logo-$name.svg -o logo-$name.png
  rsvg-convert -h 512 logo-mark-$name.svg -o logo-mark-$name.png
done
echo "logo files regenerated in assets/"
