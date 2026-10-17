<!-- generated from jyro-for-llms.md (jyro-doc dab294a 2026-10-12) by tools/jyro/build.py; do not edit -->

# Running Jyro scripts

## 16. How scripts are run

A host compiles the script once and runs it many times with different `Input`. The command line tool runs one script with a JSON file as `Input`:

```bash
jyro run -s script.jyro -i input.json
```

The tool prints `Output` as JSON. With `-p '{ ... }'` it adds the given JSON as `Input._parameters`. Compilation errors and runtime errors are printed as diagnostics in the form shown in section 13, and the exit code is 1. A host embedding Jyro in .NET supplies `Input` through `JyroRunner.WithInputJson` or `WithInput` and reads `Output` from the result; it may also provide extra functions, which it documents by name and signature, and may lower or raise the limits in section 13.
