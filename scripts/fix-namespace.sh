#!/bin/bash
# Fix serverNamespace configuration for lazy-mcp
# This script ensures lazy-mcp-proxy doesn't add server name prefixes to tool names

set -e

CONFIG_FILE="$HOME/lazy-mcp/config.json"

echo "=== Fixing serverNamespace Configuration ==="
echo ""

# Check if config exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo "✗ Error: Config file not found at $CONFIG_FILE"
  exit 1
fi

echo "✓ Found config file: $CONFIG_FILE"

# Backup
BACKUP_FILE="${CONFIG_FILE}.backup-$(date +%Y%m%d-%H%M%S)"
cp "$CONFIG_FILE" "$BACKUP_FILE"
echo "✓ Created backup: $BACKUP_FILE"
echo ""

# Fix configuration using Python
echo "Updating configuration..."
python3 << 'PYTHON_SCRIPT'
import json
import sys

config_file = sys.argv[1]

try:
    with open(config_file, 'r') as f:
        config = json.load(f)

    # Ensure structure exists
    if 'mcpProxy' not in config:
        config['mcpProxy'] = {}
    if 'options' not in config['mcpProxy']:
        config['mcpProxy']['options'] = {}

    # Set namespace options
    old_namespace = config['mcpProxy']['options'].get('serverNamespace', 'NOT_SET')
    old_prefix = config['mcpProxy']['options'].get('toolPrefix', 'NOT_SET')

    config['mcpProxy']['options']['serverNamespace'] = False
    config['mcpProxy']['options']['toolPrefix'] = ''

    with open(config_file, 'w') as f:
        json.dump(config, f, indent=2)

    print(f"  serverNamespace: {old_namespace} → False")
    print(f"  toolPrefix: {old_prefix} → '' (empty)")
    print("✓ Configuration updated")

except Exception as e:
    print(f"✗ Error updating config: {e}")
    sys.exit(1)
PYTHON_SCRIPT python3 "$CONFIG_FILE"

echo ""

# Verify
echo "Verifying configuration..."
if grep -q '"serverNamespace": false' "$CONFIG_FILE"; then
  echo "✓ serverNamespace verified: false"
else
  echo "✗ Configuration verification failed"
  echo "Please check $CONFIG_FILE manually"
  exit 1
fi

# Restart proxy
echo ""
echo "Restarting lazy-mcp-proxy..."

# Kill existing process
if pgrep -f mcp-proxy > /dev/null; then
  pkill -f mcp-proxy 2>/dev/null || true
  echo "  Stopped existing proxy"
  sleep 2
fi

# Start new process
PROXY_BIN="$HOME/lazy-mcp/build/mcp-proxy"
PROXY_LOG="$HOME/lazy-mcp/proxy.log"

if [ ! -f "$PROXY_BIN" ]; then
  echo "✗ Error: mcp-proxy binary not found at $PROXY_BIN"
  exit 1
fi

nohup "$PROXY_BIN" --config "$CONFIG_FILE" > "$PROXY_LOG" 2>&1 &
PROXY_PID=$!

sleep 3

# Verify restart
if pgrep -f mcp-proxy > /dev/null; then
  echo "✓ lazy-mcp-proxy restarted successfully (PID: $PROXY_PID)"
  echo "  Log: $PROXY_LOG"
else
  echo "✗ Failed to restart lazy-mcp-proxy"
  echo "Check logs: tail -f $PROXY_LOG"
  exit 1
fi

echo ""
echo "=== Fix Complete ==="
echo ""
echo "Next steps:"
echo "1. Restart Claude Code"
echo "2. Test with: 'Analyze this text for sentiment'"
echo "3. Verify no 'tool not found' errors occur"
echo ""
echo "Backup saved at: $BACKUP_FILE"
