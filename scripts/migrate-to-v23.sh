#!/bin/bash
# migrate-to-v23.sh
# Migration script for existing Genius Team projects to v23.0 plugin

set -e

echo "=== Genius Team v23.0 Migration ==="

if [ ! -d ".genius" ]; then
  echo "No .genius/ found. Run add.sh first."
  exit 1
fi

TARGET_FILE=".genius/plugin-mode.json"
BACKUP_FILE=""

rollback() {
  trap - ERR
  echo "ERROR: migration failed, rolling back..." >&2
  if [ -n "$BACKUP_FILE" ] && [ -f "$BACKUP_FILE" ]; then
    mv "$BACKUP_FILE" "$TARGET_FILE"
    echo "Restored previous $TARGET_FILE from backup."
  elif [ -f "$TARGET_FILE" ]; then
    rm -f "$TARGET_FILE"
    echo "Removed partially written $TARGET_FILE."
  fi
}
trap rollback ERR

if [ -f "$TARGET_FILE" ]; then
  BACKUP_FILE="${TARGET_FILE}.bak-$(date -u +%Y%m%d%H%M%S)"
  cp "$TARGET_FILE" "$BACKUP_FILE"
  echo "Backed up existing $TARGET_FILE to $BACKUP_FILE"
fi

echo "Creating plugin-mode.json..."
cat > "$TARGET_FILE" << EOF
{
  "plugin_version": "23.0.0",
  "auto_trigger": true,
  "dual_mode": true,
  "guard_enforced": true,
  "migrated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

echo "Verifying migration..."
if [ ! -s "$TARGET_FILE" ]; then
  echo "Verification failed: $TARGET_FILE missing or empty." >&2
  rollback
  exit 1
fi
if grep -q '\$(' "$TARGET_FILE"; then
  echo "Verification failed: unexpanded command substitution found in $TARGET_FILE." >&2
  rollback
  exit 1
fi
if command -v python3 >/dev/null 2>&1; then
  if ! python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$TARGET_FILE" >/dev/null 2>&1; then
    echo "Verification failed: $TARGET_FILE is not valid JSON." >&2
    rollback
    exit 1
  fi
fi
echo "Verification passed."

trap - ERR
echo "Migration complete. Install the private plugin and restart your Claude/Codex session."
echo "Skills will now auto-trigger globally."