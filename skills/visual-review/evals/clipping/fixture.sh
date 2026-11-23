#!/bin/sh
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
cp "$HERE/fixtures/sample-clipping.pdf" "./sample-clipping.pdf"
