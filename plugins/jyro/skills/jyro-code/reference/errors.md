<!-- generated from jyro-for-llms.md (jyro-doc dab294a 2026-10-12) by tools/jyro/build.py; do not edit -->

# Jyro errors and limits

## 13. Errors and limits

Compilation errors (parse, validation, linking) stop the script before it runs: unknown names, wrong argument counts, misplaced declarations, a `+` with a string literal, a non-exhaustive `match`. Runtime errors stop the script at the failing statement; `Output` as written so far is returned with the diagnostic. A diagnostic reads `[JM5200] Ln 2, Col 16: Division by zero`: the code, the one-based line and column, and the message.

Common runtime errors and their causes:

| Diagnostic | Cause |
| --- | --- |
| JM5200 `DivisionByZero`, JM5201 `ModuloByZero` | `/` or `%` by zero |
| JM5206 `UnsupportedBinaryOperation` | Arithmetic or `<` on a non-number, or `<` between different types |
| JM5209 `ConcatWithInvalidType` | `&` with an array, object, or function operand |
| JM5210 `StringOperandInAdditionRuntime` | `+` with a string that arrived at run time |
| JM5300 `IndexOutOfRange` | Writing an array element beyond `Length` |
| JM5306 `SetPropertyOnNonObject` | Writing `a.b = v` where `a` is null or not an object |
| JM5100 `InvalidType` | A typed variable or parameter given a value it cannot convert |
| JM5104 `ArgumentTypeMismatch` | A library function given the wrong type |
| JM5105 `CallbackExpected`, JM5106 `CallbackArityMismatch` | A non-lambda, or a lambda with the wrong number of parameters, given to `Map` and the like |
| JM5402 `NotIterable` | `foreach` over a number, boolean, or null value |
| JM5007 `InputValueIsReadOnly` | Writing through a reference into `Input` |
| JM5004 `ScriptFailure` | `fail` |
| JM5900 to JM5903 | The statement, loop, call depth, or time limit |

| Limit | Default |
| --- | --- |
| Execution time | 5 seconds |
| Statements executed | 10,000 |
| Loop iterations, all loops together | 1,000 |
| Call depth | 64 |
| Value size | 16,777,216 elements, properties, or code units |

```jyro
var total = 0
for i in 1 to 5001 do
    total += i
end
```

```text
[JM5901] Ln 2, Col 1: Script execution exceeded maximum loop iteration limit of 1000
```

```jyro
# input: { "n": 5000 }
var values = Range(1, Input.n + 1)
Output.count = Length(values)
Output.total = Sum(values)
Output.evens = Length(Where(values, v => v % 2 == 0))
```

```json
{ "count": 5000, "total": 12502500, "evens": 2500 }
```
