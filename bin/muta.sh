#!/bin/bash

STARTPWD="$(pwd)"
cd -- "$(dirname "$0")/.." || exit 1
BASEDIR="$(pwd)"
cd -- "$STARTPWD" || exit 1

. "$BASEDIR/lib/muta.lib.sh"

muta "$@"
