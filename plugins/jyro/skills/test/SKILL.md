---
name: test
description: Compile a Jyro script, run it against sample input, and compare the result with expected output.
argument-hint: <script.jyro> [input.json] [expected.json]
disable-model-invocation: true
---

# Test a Jyro script

Arguments: `$ARGUMENTS`. The first is the script; the optional second is an `Input` JSON file; the optional third is the expected `Output` JSON file. With no script given, use the `.jyro` file most recently discussed or edited, and say which one.

Use the jyro-code skill for the language rules.

## When `command -v jyro` finds the CLI

1. Compile: `jyro compile -s <script> -o "$(mktemp -d)/out.jyrx" -q`. On failure, show the diagnostic, explain its cause with reference/errors.md of the jyro-code skill, and propose a fix. Do not change the file unless the user asks.
2. Run: `jyro run -s <script> -i <input> -q`, or without `-i` when no input was given. When no input was given and the script reads `Input`, build a small sample from what the script reads, save it under the system temporary directory, run with it, and show the sample used.
3. With an expected file: `jyro test -s <script> -i <input> -o <expected>`, and on a mismatch show the differing properties.
4. Report: compiled or not, the `Output` produced, and pass or fail against expected output.

## Without the CLI

Say that the `jyro` CLI is not installed, so the script cannot be compiled or run here. Then review it instead: go through the checklist in section 15 of the jyro-code skill item by item, trace the script by hand against the given or a sample `Input`, and show the `Output` that trace predicts. Label the result as a manual review.
