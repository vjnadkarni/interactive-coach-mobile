#!/bin/bash

# kill-sessions.sh
# Interactive session killer for Galeno Genie mobile app
# Kills Flutter processes, app processes, and optionally checks HeyGen sessions

set -e

echo "═══════════════════════════════════════════════════════════"
echo "  Galeno Genie - Session Termination Tool"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Function to kill processes
kill_processes() {
    local name=$1
    local pids=$(pgrep -f "$name" 2>/dev/null || true)

    if [ -n "$pids" ]; then
        echo "Found $name processes:"
        ps aux | grep -E "$name" | grep -v grep | head -5
        echo ""
        read -p "Kill these processes? [y/N]: " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            echo "$pids" | xargs kill -9 2>/dev/null || true
            echo "✅ Killed $name processes"
        else
            echo "⏭️  Skipped $name processes"
        fi
        echo ""
    else
        echo "✅ No $name processes found"
        echo ""
    fi
}

# 1. Check and kill Flutter processes
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Checking Flutter processes..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kill_processes "flutter run"

# 2. Check and kill Dart processes
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Checking Dart processes..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kill_processes "dart"

# 3. Check and kill iOS device logging processes
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Checking iOS device processes..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kill_processes "idevicesyslog"

# 4. Check and kill iproxy processes
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. Checking iproxy processes..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kill_processes "iproxy"

# 5. Check for app running on iPhone
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. Checking if app is running on iPhone..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚠️  Manual action required:"
echo "   1. On your iPhone, swipe up from the bottom"
echo "   2. Swipe away the 'Galeno Genie' app card"
echo "   3. This will force-close the app and terminate any sessions"
echo ""
read -p "Press Enter after you've closed the app on iPhone..."
echo "✅ App closed on iPhone"
echo ""

# 6. Check for Next.js dev server (optional)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6. Checking Next.js dev server..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if lsof -ti:3000 >/dev/null 2>&1; then
    echo "Found Next.js dev server on port 3000:"
    lsof -i:3000 | head -5
    echo ""
    read -p "Kill Next.js dev server? [y/N]: " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        lsof -ti:3000 | xargs kill -9 2>/dev/null || true
        echo "✅ Killed Next.js dev server"
    else
        echo "⏭️  Kept Next.js dev server running"
    fi
else
    echo "✅ No Next.js dev server running"
fi
echo ""

# 7. Check for backend server (optional)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "7. Checking FastAPI backend server..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if lsof -ti:8000 >/dev/null 2>&1; then
    echo "Found FastAPI backend on port 8000:"
    lsof -i:8000 | head -5
    echo ""
    read -p "Kill backend server? [y/N]: " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        lsof -ti:8000 | xargs kill -9 2>/dev/null || true
        echo "✅ Killed backend server"
    else
        echo "⏭️  Kept backend server running"
    fi
else
    echo "✅ No backend server running"
fi
echo ""

# 8. Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "8. Verification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Checking for any remaining Flutter/Dart processes..."
remaining=$(ps aux | grep -E "flutter|dart|idevice|iproxy" | grep -v grep | wc -l)
if [ "$remaining" -eq 0 ]; then
    echo "✅ All Flutter/Dart processes terminated"
else
    echo "⚠️  Found $remaining remaining processes:"
    ps aux | grep -E "flutter|dart|idevice|iproxy" | grep -v grep
fi
echo ""

# 9. HeyGen session check reminder
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "9. HeyGen Session Check (Optional)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "To verify no active HeyGen sessions are consuming credits:"
echo ""
echo "  1. Visit: https://app.heygen.com/"
echo "  2. Check for any active streaming sessions"
echo "  3. Manually terminate if any are listed"
echo ""
echo "Note: Sessions should auto-terminate when the app is closed,"
echo "but you can verify in the HeyGen dashboard to be sure."
echo ""

echo "═══════════════════════════════════════════════════════════"
echo "  ✅ Session cleanup complete!"
echo "═══════════════════════════════════════════════════════════"
