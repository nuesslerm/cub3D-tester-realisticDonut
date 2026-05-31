#!/usr/bin/env bash
# Bash adapter for realisticDonut/42_cub_tester.
# Replaces pgrep-based checking with timeout+xvfb-run for CI reliability.
# Usage: bash test.sh [binary_path]

set -uo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
BINARY="${1:-"$DIR/../../cub3D"}"

if [ ! -x "$BINARY" ]; then
	echo "Error: binary not found or not executable: $BINARY" >&2
	exit 1
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

PASS=0
FAIL=0

# Valid map: binary opens a window and keeps running.
# Run from $DIR so relative texture paths (./textures_xpm/) resolve correctly.
# timeout exit 124 = ran for full duration = PASS.
# Any other non-zero immediate exit = startup/parse error = FAIL.
run_valid()
{
	local map="$1"
	(cd "$DIR" && timeout 3s xvfb-run -a "$BINARY" "$map") >/dev/null 2>&1
	local code=$?
	if [ "$code" -eq 124 ] || [ "$code" -eq 0 ]; then
		printf "  ${GREEN}PASS${NC} %s\n" "$map"
		PASS=$((PASS + 1))
	else
		printf "  ${RED}FAIL${NC} %s (exit %d)\n" "$map" "$code"
		FAIL=$((FAIL + 1))
	fi
}

# Invalid map: binary must exit non-zero immediately.
run_invalid()
{
	local map="$1"
	(cd "$DIR" && "$BINARY" "$map") >/dev/null 2>&1
	local code=$?
	if [ "$code" -ne 0 ]; then
		printf "  ${GREEN}PASS${NC} %s\n" "$map"
		PASS=$((PASS + 1))
	else
		printf "  ${RED}FAIL${NC} %s (expected non-zero exit)\n" "$map"
		FAIL=$((FAIL + 1))
	fi
}

echo "=== Valid Maps (69-86) ==="
i=69
while [ $i -le 86 ]; do
	run_valid "valid_maps/$i.cub"
	i=$((i + 1))
done

echo ""
echo "=== Invalid Maps (0-176) ==="
i=0
while [ $i -le 176 ]; do
	run_invalid "invalid_maps/$i.cub"
	i=$((i + 1))
done

echo ""
TOTAL=$((PASS + FAIL))
echo "Results: $PASS/$TOTAL passed"
if [ "$FAIL" -eq 0 ]; then
	echo -e "${GREEN}All Valid Maps Passed!${NC}"
	echo -e "${GREEN}All Invalid Maps Passed!${NC}"
	echo -e "${GREEN}PERFECT PARSING BABY!${NC}"
	exit 0
else
	exit 1
fi
