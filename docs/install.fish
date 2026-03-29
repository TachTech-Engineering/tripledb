#!/usr/bin/env fish
# IAO Environment Install Script
# Generated from NZXTcos (CachyOS) package export - March 2026
# Target: Fresh CachyOS machine (NVIDIA or AMD GPU)
#
# Usage: fish install.fish
# Run from the requirements/ directory of a cloned IAO project repo.
#
# What this script does:
#   1. Installs system packages (pacman)
#   2. Installs Playwright browser dependencies (explicit)
#   3. Installs AUR packages (yay)
#   4. Configures Flutter permissions
#   5. Installs npm global packages (with @latest for agent tools)
#   6. Installs pip packages (skips CUDA packages on AMD)
#   7. Downloads test browsers (Playwright + Puppeteer)
#   8. Detects GPU and configures CUDA paths if NVIDIA present
#   9. Runs Flutter doctor
#  10. Verifies all tools with pass/fail
#
# What this script does NOT do:
#   - Set API keys (security - manual step)
#   - Configure SSH keys (security - manual step)
#   - Clone the project repo (you already have it to run this script)
#   - Run without user present (needs sudo for pacman)
#
# NOTE: This is fish shell. No heredocs. No bash.

set -l SCRIPT_DIR (dirname (status filename))
set -l LOG_FILE "$SCRIPT_DIR/install.log"

echo "=== IAO Environment Setup ==="
echo "Target: "(hostname)" / "(uname -r)
echo "Log: $LOG_FILE"
echo ""
echo "This will install all packages for IAO project development."
echo "You will be prompted for sudo password during installation."
echo "Press Ctrl+C to cancel, Enter to continue..."
read

echo "" > $LOG_FILE
echo "Install started: "(date) >> $LOG_FILE

# ---------------------------------------------------------------------------
# Step 1/10: System packages (pacman - native repos)
# ---------------------------------------------------------------------------
echo ""
echo "[1/10] Installing system packages (pacman)..."
echo "  This installs "(wc -l < $SCRIPT_DIR/pacman-native.txt)" packages from official repos."

if test -f $SCRIPT_DIR/pacman-native.txt
    sudo pacman -S --needed - < $SCRIPT_DIR/pacman-native.txt 2>&1 | tee -a $LOG_FILE
else
    echo "  ERROR: pacman-native.txt not found in $SCRIPT_DIR" | tee -a $LOG_FILE
end

# ---------------------------------------------------------------------------
# Step 2/10: Playwright browser system dependencies (explicit)
# These are typically pulled in as implicit deps on a working machine
# but will NOT be in pacman-native.txt (it only captures explicit installs).
# Missing deps caused Playwright MCP failures in TripleDB v9.37-v9.42.
# ---------------------------------------------------------------------------
echo ""
echo "[2/10] Installing Playwright browser system dependencies..."
echo "  These are required for Chromium/Firefox to run in headless mode."

sudo pacman -S --needed \
    nss \
    at-spi2-core \
    cups \
    libdrm \
    mesa \
    libxkbcommon \
    libxcomposite \
    libxdamage \
    libxrandr \
    pango \
    cairo \
    alsa-lib \
    2>&1 | tee -a $LOG_FILE

# ---------------------------------------------------------------------------
# Step 3/10: AUR packages (yay)
# ---------------------------------------------------------------------------
echo ""
echo "[3/10] Installing AUR packages (yay)..."

if not command -q yay
    echo "  yay not found. Installing from AUR..."
    set -l YAY_TMP (mktemp -d)
    cd $YAY_TMP
    git clone https://aur.archlinux.org/yay.git 2>&1 | tee -a $LOG_FILE
    cd yay; and makepkg -si --noconfirm 2>&1 | tee -a $LOG_FILE
    cd ~
    rm -rf $YAY_TMP
else
    echo "  yay already installed: "(yay --version | head -1)
end

# AUR packages from export:
#   antigravity        - IDE (VS Code fork)
#   flutter-bin        - Flutter SDK
#   google-chrome      - Primary test browser
#   firefox-esr-bin    - Secondary test browser
#   google-cloud-cli   - Firebase/GCP tooling
#   google-cloud-cli-gsutil
#   jetbrains-toolbox  - Android Studio access
#   cnijfilter2        - Printer driver (optional)
#   falcon-sensor      - CrowdStrike (optional, enterprise)
#   spotify            - Optional
#   zoom               - Optional

# Core AUR packages (required for IAO)
echo "  Installing core AUR packages..."
yay -S --needed \
    antigravity \
    flutter-bin \
    google-chrome \
    firefox-esr-bin \
    google-cloud-cli \
    google-cloud-cli-gsutil \
    jetbrains-toolbox \
    2>&1 | tee -a $LOG_FILE

# Optional AUR packages (skip failures silently)
echo "  Installing optional AUR packages (failures are OK)..."
for pkg in cnijfilter2 falcon-sensor spotify zoom
    yay -S --needed $pkg 2>/dev/null; or echo "  Skipped optional: $pkg" | tee -a $LOG_FILE
end

# ---------------------------------------------------------------------------
# Step 4/10: Flutter permissions
# ---------------------------------------------------------------------------
echo ""
echo "[4/10] Configuring Flutter permissions..."

sudo groupadd -f flutterusers 2>&1 | tee -a $LOG_FILE
sudo gpasswd -a $USER flutterusers 2>&1 | tee -a $LOG_FILE

if test -d /opt/flutter
    sudo chown -R :flutterusers /opt/flutter 2>&1 | tee -a $LOG_FILE
    sudo chmod -R g+w /opt/flutter 2>&1 | tee -a $LOG_FILE
    echo "  Flutter permissions configured. Log out and back in for group to apply."
else
    echo "  /opt/flutter not found - flutter-bin may install elsewhere. Check with: which flutter"
end

# ---------------------------------------------------------------------------
# Step 5/10: npm global packages
# ---------------------------------------------------------------------------
echo ""
echo "[5/10] Installing npm global packages..."

# Agent tools - use @latest for auto-update on fresh installs
echo "  Installing agent tools (@latest)..."
sudo npm install -g @anthropic-ai/claude-code@latest 2>&1 | tee -a $LOG_FILE
sudo npm install -g @google/gemini-cli@latest 2>&1 | tee -a $LOG_FILE

# Pinned tools - version-specific to avoid breaking changes
echo "  Installing pinned tools..."
sudo npm install -g firebase-tools@15.10.0 2>&1 | tee -a $LOG_FILE

# ---------------------------------------------------------------------------
# Step 6/10: pip packages
# ---------------------------------------------------------------------------
echo ""
echo "[6/10] Installing pip packages..."

# Detect GPU type for CUDA decision
set -l HAS_NVIDIA 0
if command -q nvidia-smi
    set HAS_NVIDIA 1
    echo "  NVIDIA GPU detected. Installing full package set including CUDA deps."
else
    echo "  No NVIDIA GPU detected (AMD/Intel). Skipping CUDA-specific packages."
    echo "  Transcription (faster-whisper) will use CPU mode or should run on a CUDA machine."
end

if test -f $SCRIPT_DIR/pip-packages.txt
    if test $HAS_NVIDIA -eq 1
        # Full install - includes ctranslate2 with CUDA
        pip install --break-system-packages -r $SCRIPT_DIR/pip-packages.txt 2>&1 | tee -a $LOG_FILE
    else
        # Filter out CUDA-dependent packages, install the rest
        # ctranslate2 requires CUDA libs. faster-whisper depends on ctranslate2.
        # On AMD: skip both, note that transcription must run on NVIDIA machine.
        grep -vE "^(ctranslate2|faster-whisper|btrfsutil|cockpit|cupshelpers|dbus-python)" \
            $SCRIPT_DIR/pip-packages.txt > /tmp/pip-no-cuda.txt
        pip install --break-system-packages -r /tmp/pip-no-cuda.txt 2>&1 | tee -a $LOG_FILE
        rm -f /tmp/pip-no-cuda.txt
        echo ""
        echo "  NOTE: Skipped CUDA packages (ctranslate2, faster-whisper)."
        echo "  Transcription phases must run on a machine with NVIDIA GPU."
    end
else
    echo "  ERROR: pip-packages.txt not found in $SCRIPT_DIR" | tee -a $LOG_FILE
end

# ---------------------------------------------------------------------------
# Step 7/10: Test browsers (Playwright + Puppeteer)
# ---------------------------------------------------------------------------
echo ""
echo "[7/10] Downloading test browsers..."

echo "  Playwright browsers (chromium + firefox)..."
npx playwright install chromium firefox 2>&1 | tee -a $LOG_FILE
or echo "  WARNING: Playwright browser download failed" | tee -a $LOG_FILE

echo "  Puppeteer browser (chrome)..."
npx puppeteer browsers install chrome 2>&1 | tee -a $LOG_FILE
or echo "  WARNING: Puppeteer browser download failed" | tee -a $LOG_FILE

# ---------------------------------------------------------------------------
# Step 8/10: GPU detection + CUDA path (NVIDIA only)
# ---------------------------------------------------------------------------
echo ""
echo "[8/10] GPU configuration..."

if test $HAS_NVIDIA -eq 1
    echo "  NVIDIA GPU: "(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader)

    # Set LD_LIBRARY_PATH for CUDA (prevents the v2.11 20+ intervention failure).
    # faster-whisper/ctranslate2 need libcublas.so.12 at shell level, not in Python.
    # Detect the CUDA lib path - CachyOS typically puts it here:
    set -l CUDA_PATHS /usr/lib /usr/local/cuda/lib64 /opt/cuda/lib64
    for p in $CUDA_PATHS
        if test -f $p/libcublas.so.12; or test -f $p/libcublas.so
            echo "  Found CUDA libs at: $p"
            echo "  Add to your fish config:"
            echo "    set -gx LD_LIBRARY_PATH $p \$LD_LIBRARY_PATH"
            break
        end
    end
else
    echo "  AMD/Intel GPU detected. No CUDA configuration needed."
    echo "  GPU: "(lspci | grep -i "vga\|3d" | head -1 | sed 's/.*: //')
end

# ---------------------------------------------------------------------------
# Step 9/10: Flutter setup
# ---------------------------------------------------------------------------
echo ""
echo "[9/10] Running Flutter setup..."

flutter doctor --android-licenses 2>/dev/null; or true
flutter doctor -v 2>&1 | tee -a $LOG_FILE

# ---------------------------------------------------------------------------
# Step 10/10: Verification
# ---------------------------------------------------------------------------
echo ""
echo "==========================================="
echo "  Verification"
echo "==========================================="

set -l PASS 0
set -l FAIL 0
set -l WARN 0

# Define checks as "command | display name"
set -l CHECKS \
    "git --version|git" \
    "fish --version|fish" \
    "tmux -V|tmux" \
    "node --version|node" \
    "npm --version|npm" \
    "python3 --version|python3" \
    "flutter --version|flutter" \
    "firebase --version|firebase-tools" \
    "yt-dlp --version|yt-dlp" \
    "google-chrome-stable --version|google-chrome" \
    "firefox-esr --version|firefox-esr" \
    "claude --version|claude-code" \
    "gemini --version|gemini-cli" \
    "npx playwright --version|playwright" \
    "npx puppeteer --version|puppeteer"

for check in $CHECKS
    set -l cmd (echo $check | cut -d'|' -f1)
    set -l name (echo $check | cut -d'|' -f2)
    if eval $cmd >/dev/null 2>&1
        set PASS (math $PASS + 1)
        set -l ver (eval $cmd 2>/dev/null | head -1 | string trim)
        echo "  PASS: $name ($ver)"
    else
        set FAIL (math $FAIL + 1)
        echo "  FAIL: $name"
    end
end

# Conditional checks
if command -q nvidia-smi
    if nvidia-smi >/dev/null 2>&1
        set PASS (math $PASS + 1)
        echo "  PASS: nvidia-smi (CUDA available)"
    else
        set FAIL (math $FAIL + 1)
        echo "  FAIL: nvidia-smi"
    end
else
    set WARN (math $WARN + 1)
    echo "  SKIP: nvidia-smi (no NVIDIA GPU - transcription runs on CUDA machine)"
end

if command -q faster-whisper
    set PASS (math $PASS + 1)
    echo "  PASS: faster-whisper"
else if python3 -c "import faster_whisper" 2>/dev/null
    set PASS (math $PASS + 1)
    echo "  PASS: faster-whisper (python module)"
else
    if test $HAS_NVIDIA -eq 1
        set FAIL (math $FAIL + 1)
        echo "  FAIL: faster-whisper (CUDA machine should have this)"
    else
        set WARN (math $WARN + 1)
        echo "  SKIP: faster-whisper (requires NVIDIA GPU)"
    end
end

echo ""
echo "==========================================="
echo "  Results: $PASS passed, $FAIL failed, $WARN skipped"
echo "==========================================="

if test $FAIL -gt 0
    echo "  WARNING: $FAIL tools failed verification. Check output above."
else if test $WARN -gt 0
    echo "  Environment ready (with $WARN GPU-dependent items skipped)."
else
    echo "  All tools verified. Environment ready."
end

# ---------------------------------------------------------------------------
# Next Steps
# ---------------------------------------------------------------------------
echo ""
echo "==========================================="
echo "  Next Steps"
echo "==========================================="
echo ""
echo "1. Copy fish config and add your API keys:"
echo "     cp $SCRIPT_DIR/fish-config-sanitized.fish ~/.config/fish/config.fish"
echo "     nano ~/.config/fish/config.fish"
echo "   Required keys: GEMINI_API_KEY, GOOGLE_PLACES_API_KEY"
echo "   Replace REDACTED values with your actual keys."
echo ""
echo "2. Copy MCP configs (add your own API keys to these too):"
echo "     mkdir -p ~/.config/claude"
echo "     # Create claude MCP config with your Firecrawl key, Playwright, Context7"
echo "     # See gemini-settings.json for reference (keys are REDACTED)"
echo "     cp $SCRIPT_DIR/gemini-settings.json ~/.gemini/settings.json"
echo "     nano ~/.gemini/settings.json  # Add your API keys"
echo ""
echo "3. Reload shell:"
echo "     source ~/.config/fish/config.fish"
echo ""
echo "4. Setup SSH for GitHub:"
echo "     ssh-keygen -t ed25519 -C \"your-email@example.com\""
echo "     cat ~/.ssh/id_ed25519.pub"
echo "     # Add the public key to GitHub: Settings -> SSH Keys"
echo ""

if test $HAS_NVIDIA -eq 0
    echo "5. IMPORTANT - No NVIDIA GPU detected on this machine."
    echo "   Pipeline phases that use faster-whisper (transcription) must"
    echo "   run on a machine with an NVIDIA GPU and CUDA toolkit."
    echo "   All other phases (extraction, normalization, Flutter) work on AMD."
    echo ""
end

echo "Install log saved to: $LOG_FILE"
echo ""
echo "When ready to start a project:"
echo "  cd ~/dev/projects/{your-project}"
echo "  claude --dangerously-skip-permissions"
echo "  # Then: Read CLAUDE.md and execute."
