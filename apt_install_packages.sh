#!/bin/sh
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-02-15 21:31:10 +0000 (Fri, 15 Feb 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Install Deb packages in a forgiving way - useful for installing Perl CPAN and Python PyPI modules that may or may not be available
#
# combine with later use of the following scripts to only build packages that aren't available in the Linux distribution:
#
# perl_cpanm_install_if_absent.sh
# python_pip_install_if_absent.sh

set -eu
[ -n "${DEBUG:-}" ] && set -x

usage(){
    echo "Installs Debian / Ubuntu deb package lists"
    echo
    echo "Takes a list of deb packages as arguments or .txt files containing lists of packages (one per line)"
    echo
    echo "usage: ${0##*} <list_of_packages>"
    echo
    exit 3
}

for arg; do
    case "$arg" in
        -*) usage
            ;;
    esac
done

echo "Installing Deb Packages"

export DEBIAN_FRONTEND=noninteractive

opts="--no-install-recommends"
if [ -n "${TRAVIS:-}" ]; then
    echo "running in quiet mode"
    opts="$opts -qq"
fi

packages=""

process_args(){
    for arg; do
        if [ -f "$arg" ]; then
            echo "adding packages from file:  $arg"
            packages="$packages $(sed 's/#.*//;/^[[:space:]]*$$/d' "$arg")"
            echo
        else
            packages="$packages $arg"
        fi
    done
}

if [ -n "${*:-}" ]; then
    process_args "$@"
else
    # shellcheck disable=SC2046
    process_args $(cat)
fi

if [ -z "${packages// }" ]; then
    exit 0
fi

# uniq
packages="$(echo "$packages" | tr ' ' ' \n' | sort -u | tr '\n' ' ')"

SUDO=""
# $EUID is not defined in posix sh
# shellcheck disable=SC2039
[ "${EUID:-$(id -u)}" != 0 ] && SUDO=sudo

# shellcheck disable=SC2086
[ -n "${NO_UPDATE:-}" ] || $SUDO apt-get $opts update

if [ -n "${NO_FAIL:-}" ]; then
    # shellcheck disable=SC2086
    for package in $packages; do
        $SUDO apt-get install -y $opts "$package" || :
    done
else
    # shellcheck disable=SC2086
    $SUDO apt-get install -y $opts $packages
fi
