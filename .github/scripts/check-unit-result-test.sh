#!/usr/bin/env bash
set -euo pipefail
dir="${RUNNER_TEMP:?}/p47-unit-classification"
mkdir -p "$dir"
gate=".github/scripts/check-unit-result.sh"
printf 'P47_UNIT_OK description_bank \nP47_UNIT_FAIL catalog_fields_match_brief \n' > "$dir/known.log"
printf 'P47_UNIT_OK description_bank \nP47_UNIT_FAIL catalog_fields_match_brief \nP47_UNIT_FAIL another_failure \n' > "$dir/extra.log"
printf 'P47_UNIT_OK description_bank \nP47_UNIT_FAIL catalog_fields_match_brief \nSCRIPT ERROR: example\n' > "$dir/script.log"
printf 'P47_UNIT_FAIL catalog_fields_match_brief \n' > "$dir/incomplete.log"
printf 'P47_UNIT_OK description_bank \n' > "$dir/passing.log"
: > "$dir/reference-present"
bash "$gate" "$dir/known.log" 1 "$dir/reference-absent" > "$dir/known.out"
bash "$gate" "$dir/passing.log" 0 "$dir/reference-present" > "$dir/passing.out"
if bash "$gate" "$dir/extra.log" 1 "$dir/reference-absent" > "$dir/extra.out"; then exit 1; fi
if bash "$gate" "$dir/script.log" 1 "$dir/reference-absent" > "$dir/script.out"; then exit 1; fi
if bash "$gate" "$dir/incomplete.log" 1 "$dir/reference-absent" > "$dir/incomplete.out"; then exit 1; fi
if bash "$gate" "$dir/known.log" 1 "$dir/reference-present" > "$dir/reference.out"; then exit 1; fi
if bash "$gate" "$dir/known.log" 124 "$dir/reference-absent" > "$dir/timeout.out"; then exit 1; fi
echo "Unit result classification: 7 cases passed."
