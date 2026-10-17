#!/usr/bin/env bash
# Tests for the check-jyro.sh hook and the generated skill.
# Cases that need the jyro CLI are skipped when it is not installed.
cd "$(dirname "$0")/../.." || exit 1
hook=plugins/jyro/scripts/check-jyro.sh
fixtures=$PWD/tests/jyro/fixtures
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
failed=0

# expect <name> <expected exit> <expected stderr substring or ""> <file> [env...]
expect() {
  local name=$1 want=$2 needle=$3 file=$4; shift 4
  local err status
  err=$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s"}}' "$file" | env "$@" bash "$hook" 2>&1 >/dev/null)
  status=$?
  if [ "$status" -ne "$want" ] || [[ -n $needle && $err != *"$needle"* ]]; then
    echo "FAIL $name: exit $status (want $want)"; echo "$err" | sed 's/^/    /'; failed=1
  else
    echo "ok   $name"
  fi
}

printf 'x' > "$tmp/notes.txt"
expect "non-jyro file is ignored" 0 "" "$tmp/notes.txt"
expect "missing file is ignored" 0 "" "$tmp/missing.jyro"
expect "no CLI on PATH is silent" 0 "" "$fixtures/bad.jyro" PATH=/nonexistent:/usr/bin:/bin JYRO_CLI=jyro-not-installed
expect "disabled by JYRO_HOOK_DISABLE" 0 "" "$fixtures/bad.jyro" JYRO_HOOK_DISABLE=1

if command -v "${JYRO_CLI:-jyro}" >/dev/null 2>&1; then
  mkdir -p "$tmp/with space"; cp "$fixtures/bad.jyro" "$tmp/with space/a b.jyro"
  expect "valid script passes" 0 "" "$fixtures/good.jyro"
  expect "compile error is reported" 2 "JM3301" "$fixtures/bad.jyro"
  expect "unknown function gets host note" 2 "provided by the host" "$fixtures/host.jyro"
  expect "path with spaces" 2 "JM3301" "$tmp/with space/a b.jyro"
else
  echo "skip CLI cases: jyro not installed"
fi

if [ -n "${JYRO_DOC:-}" ] || [ -f ../jyro-doc/jyro-for-llms.md ]; then
  if python3 tools/jyro/build.py --check >/dev/null; then echo "ok   generated skill is up to date"
  else echo "FAIL generated skill is out of date: run python3 tools/jyro/build.py"; failed=1; fi
else
  echo "skip build check: jyro-doc not found (set JYRO_DOC)"
fi

exit $failed
