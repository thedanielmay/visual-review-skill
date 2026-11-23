#!/bin/sh
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
cp "$HERE/fixtures/sample-runt.pdf" "./sample-runt.pdf"
