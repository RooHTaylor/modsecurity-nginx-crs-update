#!/usr/bin/env bash

usage() {
    cat <<EOF
Usage: $0 [options]

Options:
  -U, --uninstall     Uninstall
  -h, --help          Show this help

Examples:
  sudo ./install.sh
  sudo ./install.sh -U
EOF
}

UNINSTALL=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        -U|--uninstall)
            UNINSTALL=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [[ $EUID -ne 0 ]]; then
    die "This script must be run as root (try sudo)"
fi

if [[ $UNINSTALL -eq 1 ]]; then
    echo "Uninstalling"

    rm -f "/usr/local/bin/update-modsecurity-nginx"

    echo "Uninstall complete"
    exit 0
fi

echo "Installing"

cp update-modsecurity-nginx /usr/local/bin/.

echo "Installation complete"