#!/usr/bin/env bash
# Entry point: picks the installer for this OS and runs it.
# Works both from a clone (./install.sh) and piped from curl (see README).

set -euo pipefail

RAW_URL="https://raw.githubusercontent.com/carlsondev/convenience-scripts/main"

# Everything lives in main() so bash reads the whole script before running any
# of it; otherwise a child reading stdin could eat the rest of a piped script.
main() {
    case "$(uname -s)" in
        Linux) installer="install-linux.sh" ;;
        Darwin) installer="install-macos.sh" ;;
        *)
            echo "Unsupported OS: $(uname -s)" >&2
            exit 1
            ;;
    esac

    # Prefer the copy next to this script when run from a clone
    local script_dir=""
    if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    fi

    if [ -n "$script_dir" ] && [ -f "$script_dir/$installer" ]; then
        bash "$script_dir/$installer" "$@"
    else
        # Global (not local) so the EXIT trap can still see it
        tmp="$(mktemp)"
        trap 'rm -f "$tmp"' EXIT
        curl -fsSL "$RAW_URL/$installer" -o "$tmp"
        bash "$tmp" "$@"
    fi
}

main "$@"
