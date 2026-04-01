#!/bin/bash
set -e

# Source our common vars
scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${scripts_path}/vars.sh

debug_msg "Starting 00_prereq_check.sh"

# Local OS detection fallback
case "$(uname -s)" in
    Linux)  _host_os="linux" ;;
    Darwin) _host_os="macos" ;;
    *)      error_msg "Unsupported OS: $(uname -s)"; exit 1 ;;
esac

# Check for required utils
if [ "${_host_os}" == "linux" ]; then
    _required_bins="losetup docker curl sudo"
else
    _required_bins="docker curl"
fi

for bin in ${_required_bins}; do
    if ! which ${bin} > /dev/null; then
        error_msg "${bin} is missing! Exiting..."
        exit 1
    fi
done

# Make sure loop module is loaded (Linux only; on macOS Docker handles this in the VM)
if [ "${_host_os}" == "linux" ]; then
    if [ ! -d /sys/module/loop ]; then
        error_msg "Loop module isn't loaded into the kernel! This is REQUIRED! Exiting..."
        exit 1
    fi
fi

debug_msg "Finished 00_prereq_check.sh"
