#!/bin/bash
if [ ! -f "$HOME/.bashrc" ]; then
  cp /etc/skel/.bashrc "$HOME/.bashrc"
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi
exec "$@"
