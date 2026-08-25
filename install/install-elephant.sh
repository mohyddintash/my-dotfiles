#!/bin/bash
set -euo pipefail
# elephant is walker's provider-plugin suite — always installed as a set.
yay -S --needed --noconfirm \
  elephant elephant-bluetooth elephant-calc elephant-clipboard \
  elephant-desktopapplications elephant-files elephant-menus \
  elephant-providerlist elephant-runner elephant-symbols elephant-todo \
  elephant-unicode elephant-websearch
