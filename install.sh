#!/usr/bin/env bash
set -e

REPO="https://github.com/XWBarton/glyph-quorum.git"
DIR="glyph-quorum"
PORT="${PORT:-3000}"
# If you're behind a reverse proxy / Cloudflare Tunnel set this to your public URL
# e.g. PUBLIC_URL=https://quorum.example.com ./install.sh
PUBLIC_URL="${PUBLIC_URL:-}"

bold()  { printf "\033[1m%s\033[0m\n" "$*"; }
info()  { printf "  \033[34m→\033[0m  %s\n" "$*"; }
ok()    { printf "  \033[32m✓\033[0m  %s\n" "$*"; }
err()   { printf "  \033[31m✗\033[0m  %s\n" "$*"; exit 1; }

bold ""
bold "  Glyph Quorum — installer"
bold ""

# ── Node.js ──────────────────────────────────────────────────────────────────
if ! command -v node &>/dev/null; then
  info "Installing Node.js 20..."
  if command -v apt-get &>/dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - &>/dev/null
    sudo apt-get install -y nodejs &>/dev/null
  elif command -v brew &>/dev/null; then
    brew install node &>/dev/null
  else
    err "Could not install Node.js — please install it manually (https://nodejs.org)"
  fi
fi
ok "Node.js $(node -v)"

# ── Typst ─────────────────────────────────────────────────────────────────────
if ! command -v typst &>/dev/null; then
  info "Installing Typst..."
  if command -v brew &>/dev/null; then
    brew install typst &>/dev/null
  else
    curl -fsSL https://typst.community/typst-install/install.sh | sh &>/dev/null
    export PATH="$HOME/.local/bin:$PATH"
  fi
fi
ok "Typst $(typst --version 2>/dev/null | head -1)"

# ── Clone / update ────────────────────────────────────────────────────────────
if [ -d "$DIR/.git" ]; then
  info "Updating existing installation..."
  git -C "$DIR" pull --ff-only &>/dev/null
else
  info "Cloning repository..."
  git clone "$REPO" "$DIR" &>/dev/null
fi
ok "Repository ready"

# ── Install dependencies ──────────────────────────────────────────────────────
info "Installing dependencies..."
npm --prefix "$DIR" install &>/dev/null
ok "Dependencies installed"

# ── Write public URL env for client build ─────────────────────────────────────
if [ -n "$PUBLIC_URL" ]; then
  WS_URL="${PUBLIC_URL/https:/wss:}"
  WS_URL="${WS_URL/http:/ws:}"
  echo "VITE_WS_URL=$WS_URL" > "$DIR/client/.env.production"
  info "Public URL set to $PUBLIC_URL"
fi

# ── Build ─────────────────────────────────────────────────────────────────────
info "Building..."
npm --prefix "$DIR" run build &>/dev/null
ok "Build complete"

# ── Start ─────────────────────────────────────────────────────────────────────
bold ""
bold "  Starting Glyph Quorum on port $PORT..."
bold ""
info "Open http://localhost:$PORT in your browser"
info "Press Ctrl+C to stop"
bold ""

cd "$DIR/server"
PORT=$PORT node dist/index.js
