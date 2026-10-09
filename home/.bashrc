# Omarchy environment (OMARCHY_PATH + PATH), needed even for non-interactive shells
[[ -r /usr/share/omarchy/default/bash/env-bootstrap ]] && source /usr/share/omarchy/default/bash/env-bootstrap

# If not running interactively, don't do anything else (leave this above the rc source)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source "$OMARCHY_PATH/default/bash/rc"

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'

if [[ $- == *i* && -z "${TMUX:-}" && "${HERDR_ENV:-}" != 1 ]]; then
    undead-fetch
fi

. "$HOME/.local/share/../bin/env"

# >>> Codex installer >>>
export PATH="/home/xadni/.local/bin:$PATH"
# <<< Codex installer <<<
# >>> osrs-omarchy >>>
# Random OSRS boss + system info in every new interactive terminal (osrs-fetch off to disable)
if [[ $- == *i* && -t 1 && -z ${OSRS_FETCH_SHOWN:-} && -z ${NVIM:-} && ${TERM:-} != dumb ]] && command -v osrs-fetch >/dev/null; then
  OSRS_FETCH_SHOWN=1
  osrs-fetch --auto
fi
# <<< osrs-omarchy <<<
