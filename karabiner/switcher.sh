#!/bin/zsh
# Prints open apps, most recently used first, one per line. Used by AppSwitcher.app.
# Note: lsappinfo writes spaces as "_"; an app with a real "_" in its name won't open.
lsappinfo visibleProcessList | grep -oE '"[^"]+"' | tr -d '"' | tr '_' ' ' \
  | awk '!seen[$0]++' | grep -vxE 'AppSwitcher|Karabiner-EventViewer|BoyaCheck'
