#!/bin/bash

MARKER="/opt/oracle/oradata/.setup_complete"

if [ -f "$MARKER" ]; then
  echo "Setup already complete, skipping."
  exit 0
fi

echo "Running first-time database setup..."

# Create TDE wallet directory (required before CREATE KEYSTORE)
mkdir -p /opt/oracle/oradata/FREE/tde
chmod 700 /opt/oracle/oradata/FREE/tde

sqlplus -s / as sysdba @/opt/oracle/scripts/startup/setup.init

touch "$MARKER"
echo "Setup complete."
