# Jyro for Claude Code

A Claude Code plugin for reading, writing and debugging [Jyro](https://www.jyro.dev) scripts.

- **The `jyro-code` skill** teaches Claude the current Jyro language: the habits from other languages that produce wrong Jyro, the full standard library, the error codes and verified patterns. Claude loads it whenever it works on a `.jyro` file or a question about Jyro, and reads the detailed reference files only when it needs them.
- **A compile hook** runs `jyro compile` on every `.jyro` file Claude writes or edits, and hands any diagnostic straight back to Claude, which fixes it in the same turn.
- **`/jyro:test <script> [input.json] [expected.json]`** compiles a script, runs it, and compares the result with expected output.

## Install

In Claude Code:

```
/plugin marketplace add realtree-systems/claude-plugins
/plugin install jyro@realtree-systems
```

## With or without the jyro CLI

The plugin works either way.

| | jyro CLI installed | No CLI |
| --- | --- | --- |
| Skill | Full language reference, plus `jyro man` for lookups | Full language reference |
| Compile hook | Checks every `.jyro` edit | Does nothing, silently |
| Verification | Claude compiles, runs and tests the script | Claude reviews against the checklist, traces by hand, and says the script was not compiled |
| `/jyro:test` | Compiles, runs, compares | Manual review, labelled as such |

Install the CLI from [www.jyro.dev](https://www.jyro.dev) to get compiler feedback.

### Host functions

Scripts that call functions provided by a host application, not the standard library, fail a plain compile with `JM4100 Undefined function`. Put a `jyro.config.json` (from `jyro init-config`) in the script's directory or any directory above it, with `pluginAssemblies`, `pluginDirectories` or `pluginRecursiveDirectories` naming the host's plugin assembly. The hook passes those settings to the compiler. Without them, the hook still tells Claude that an undefined function may be a host function.

### Settings

| Environment variable | Effect |
| --- | --- |
| `JYRO_CLI` | Path to the `jyro` executable, when it is not on `PATH` |
| `JYRO_HOOK_DISABLE=1` | Turns the compile hook off |

The hook needs `bash`. It reads the hook payload with `jq` or `python3` when either is present, and with `sed` otherwise.

## Development

The skill is generated from [`jyro-for-llms.md`](https://github.com/realtree-systems/jyro-doc/blob/main/jyro-for-llms.md) in `jyro-doc`. Do not edit the files under `skills/jyro-code/` directly. Run these from the repository root:

- `tools/jyro/SKILL.md.tmpl` is the hand-written part of `SKILL.md`. Sections 1, 2 and 15 of the document are copied into it.
- `tools/jyro/build.py` copies the other sections into `reference/` and fills the template. Run it after `jyro-for-llms.md` changes:

  ```
  python3 tools/jyro/build.py            # finds a jyro-doc checkout beside this repository, or set JYRO_DOC
  python3 tools/jyro/build.py --check    # exit 1 when the generated files are stale
  ```

- `tests/jyro/run.sh` tests the hook, with and without the CLI, and checks that the generated skill is current.
- To try local changes: `claude --plugin-dir plugins/jyro`.

## Licence

The skill's content is derived from the Jyro documentation, which is licensed under [CC BY-NC-SA 4.0](LICENCE), so this plugin is distributed under the same licence, not the MIT licence at the repository root.
