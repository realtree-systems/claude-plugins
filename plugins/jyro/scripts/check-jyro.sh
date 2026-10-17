#!/usr/bin/env bash
# PostToolUse hook: compile a .jyro file after Claude writes or edits it.
#
# Silent (exit 0) when the edited file is not a .jyro file, when the jyro CLI
# is not installed, or when the script compiles. On a compile error it prints
# the diagnostic to stderr and exits 2, which Claude Code shows to Claude.
#
# Environment:
#   JYRO_CLI           path to the jyro executable (default: jyro on PATH)
#   JYRO_HOOK_DISABLE  set to 1 to turn the check off

[ "${JYRO_HOOK_DISABLE:-}" = "1" ] && exit 0

payload=$(cat)

# Read one string field from JSON with whatever is available.
json_field() {
  local expr=$1 pyexpr=$2
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$payload" | jq -r "$expr // empty" 2>/dev/null
  elif command -v python3 >/dev/null 2>&1; then
    printf '%s' "$payload" | python3 -I -c "import json,sys
d=json.load(sys.stdin)
v=$pyexpr
print(v if isinstance(v,str) else '')" 2>/dev/null
  else
    # Last resort: first "key":"value" pair. Paths with escaped quotes are not handled.
    local key=${expr##*.}
    printf '%s' "$payload" | sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -n 1
  fi
}

file=$(json_field '.tool_input.file_path' "d.get('tool_input',{}).get('file_path')")
case "$file" in
  *.jyro) ;;
  *) exit 0 ;;
esac
[ -f "$file" ] || exit 0

jyro=${JYRO_CLI:-jyro}
command -v "$jyro" >/dev/null 2>&1 || exit 0

# Host functions: a jyro.config.json in the script's directory or above may
# name plugin assemblies that define them. jyro compile has no --config
# option, so pass its plugin settings through as flags.
plugin_args=()
dir=$(cd "$(dirname "$file")" && pwd)
config=""
while [ -n "$dir" ]; do
  if [ -f "$dir/jyro.config.json" ]; then config="$dir/jyro.config.json"; break; fi
  [ "$dir" = "/" ] && break
  dir=$(dirname "$dir")
done
if [ -n "$config" ]; then
  payload=$(cat "$config")
  a=$(json_field '.pluginAssemblies' "d.get('pluginAssemblies')")
  d=$(json_field '.pluginDirectories' "d.get('pluginDirectories')")
  r=$(json_field '.pluginRecursiveDirectories' "d.get('pluginRecursiveDirectories')")
  [ -n "$a" ] && plugin_args+=(--plugin "$a")
  [ -n "$d" ] && plugin_args+=(--plugin-directory "$d")
  [ -n "$r" ] && plugin_args+=(--plugin-recursive "$r")
fi

tmp=$(mktemp -d 2>/dev/null || mktemp -d -t jyro)
trap 'rm -rf "$tmp"' EXIT

# Run from the config's directory so relative plugin paths resolve as they do for jyro run.
run_dir=$(dirname "${config:-$file}")
output=$(cd "$run_dir" && "$jyro" compile -s "$file" -o "$tmp/out.jyrx" -q "${plugin_args[@]}" 2>&1)
status=$?
[ $status -eq 0 ] && exit 0

{
  echo "jyro compile failed for $file:"
  echo "$output"
  echo "The compiler reports only the first error, so more may follow once this one is fixed."
  if [[ $output == *JM4100* ]]; then
    echo "JM4100 also appears when a function is provided by the host application rather than the standard library. If the host documents this function, the script may be correct and the CLI lacks the host's plugin assembly (set pluginAssemblies in jyro.config.json). Otherwise the name is misspelt or does not exist."
  fi
} >&2
exit 2
