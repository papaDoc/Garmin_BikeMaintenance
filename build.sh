#!/usr/bin/env bash
set -euo pipefail

MONKEYC="/c/Users/rricard/AppData/Roaming/Garmin/ConnectIQ/Sdks/connectiq-sdk-win-9.1.0-2026-03-09-6a872a80b/bin/monkeyc"
KEY=${1:-developer_key}

"$MONKEYC" -f monkey.jungle -d edge830 -o BikeMaint_edge830.iq -y "$KEY" -e -r
"$MONKEYC" -f monkey.jungle -d edge830 -o BikeMaint_edge830.prg -y "$KEY" -r
"$MONKEYC" -f monkey.jungle -d edge840 -o BikeMaint_edge840.iq -y "$KEY" -e -r
"$MONKEYC" -f monkey.jungle -d edge840 -o BikeMaint_edge840.prg -y "$KEY" -r
