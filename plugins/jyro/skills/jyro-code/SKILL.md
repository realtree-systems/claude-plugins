---
name: jyro-code
description: Write, read, debug and review Jyro scripts (.jyro), the sandboxed scripting language that turns Input JSON into Output JSON inside a .NET host. Use whenever a .jyro file is opened, created or edited, when the user asks about Jyro syntax, semantics or its standard library, when a script is embedded in a host such as a RealTreeDB endpoint or trigger, or when a Jyro diagnostic (JM0000-JM5999) needs explaining.
---
<!-- generated from jyro-for-llms.md (jyro-doc dab294a 2026-10-12) by tools/jyro/build.py; edit tools/jyro/SKILL.md.tmpl instead -->

# Jyro

Jyro looks familiar and is not. Most wrong Jyro comes from habits carried over from JavaScript, Python or C#, listed in section 2 below. Treat that table as rules, not style.

Conventions in this document: a Jyro example may start with a comment of the form `# input: {...}`, which is the JSON the host supplied as `Input` for that run. A `json` block after an example is the `Output` the example produces. A `text` block after an example is the diagnostic the example produces. Every example has been executed.

Section numbers in this skill refer to the source document. Where each one lives:

| Sections | File | Read it when |
| --- | --- | --- |
| 1, 2, 15 | this file | Always |
| 3, 14 | [reference/patterns.md](reference/patterns.md) | Starting a script: a complete worked example and verified patterns for filtering, grouping, lookups, validation, dates, money, text, defaults, sorting, nested output |
| 4 to 11 | [reference/language.md](reference/language.md) | Unsure of a rule: lexical rules, values, truthiness, equality, scope, operator precedence, statements, functions, lambdas, unions |
| 12 | [reference/stdlib.md](reference/stdlib.md) | Before calling any library function whose exact name, parameter order or null behaviour you have not confirmed. Search it for the name rather than reading it whole |
| 13 | [reference/errors.md](reference/errors.md) | Explaining a `JMxxxx` diagnostic, or a script near the statement or loop limits |
| 16 | [reference/running.md](reference/running.md) | Running a script from the command line or a .NET host |

## Working method

1. **Establish the contract.** What `Input` looks like, what `Output` must be, and which host functions exist. A host names its own functions; never invent one. If the shape of `Input` is unknown, ask or state the assumption in a comment at the top of the script.
2. **Check names before use.** Search [reference/stdlib.md](reference/stdlib.md) for each library function you call. The library has exactly the functions listed there, PascalCase and spelled exactly.
3. **Write the script**, preferring library functions to loops (section 1: loop iterations are capped across the whole run).
4. **Verify**, in one of two ways depending on whether the CLI is installed. Find out with `command -v jyro`.
5. **Report how it was verified**: compiled, run against sample input, tested against expected output, or reviewed by hand only.

### With the jyro CLI

- A plugin hook compiles each `.jyro` file after it is written or edited, and reports the diagnostic when compilation fails. The compiler stops at the first error, so expect one error per round.
- Compile a script that is not in a `.jyro` file (embedded in C#, JSON or a database) through stdin: `printf '%s\n' "$SCRIPT" | jyro run --stdin -q`. Without `-i`, `Input` is null, so a runtime error about missing input can still mean the script compiled.
- Run with sample input: `jyro run -s script.jyro -i input.json -q`. Build the sample from the user's description of `Input`, including an edge case such as an empty array or a missing property.
- Compare with expected output: `jyro test -s script.jyro -i input.json -o expected.json`.
- Look up a topic or function in the manual that ships with the CLI: `jyro man <topic>` (for example `jyro man round`, `jyro man types`, `jyro man` for the index). Its output has colour codes; pipe it through `perl -pe 's/\e\[[0-9;]*m//g'` to strip them. When the manual and this skill disagree, the installed CLI is the authority.
- `JM4100 Undefined function` for a function the host documents means the CLI lacks the host's plugin assembly, not that the script is wrong. Say so rather than renaming the call. A `jyro.config.json` with `pluginAssemblies` set lets the hook and `jyro run` see host functions.

### Without the jyro CLI

- Go through the checklist in section 15 item by item against the finished script, then the table in section 2.
- Trace the script by hand against one concrete `Input`, writing out the `Output` it produces.
- Tell the user the script has not been compiled, and that installing the `jyro` CLI (see www.jyro.dev) lets Claude compile and run it.

## 1. What Jyro is

Jyro is a scripting language that a .NET host application compiles and runs inside a sandbox. A script is a sequence of statements that run from the first to the last. There is no entry point, no module system, and no import.

- The script reads its data through `Input`, a read-only value the host supplies, usually a JSON object.
- The script writes its result to `Output`, which starts as an empty object `{}`. The value of `Output` when the script ends is the result the host receives.
- A script has no access to files, the network, the clock, the environment, or anything outside `Input`, except through functions the host chooses to provide.
- Values are the JSON types (null, boolean, number, string, array, object) plus lambda function values. Numbers are exact decimals: `0.1 + 0.2 == 0.3`.
- The standard library of 97 functions is available in practice in every host; assume it is present unless told otherwise. A host may add its own functions and will name them.
- Every run is bounded: by default 5 seconds, 10,000 statements, 1,000 loop iterations in total across all loops, and a call depth of 64. A standard library call counts as one statement however large its input, so **prefer standard library functions to explicit loops over data**.
- A runtime error stops the script at that statement. There is no exception handling. The host receives the diagnostic and the `Output` written so far.

A minimal script:

```jyro
# input: { "name": "Ada", "scores": [72, 88, 95] }
var average = Average(Input.scores)
Output.greeting = "Hello, " & Input.name
Output.average = average
Output.grade = average >= 80 ? "pass" : "fail"
```

```json
{ "greeting": "Hello, Ada", "average": 85, "grade": "pass" }
```

## 2. Assumptions to drop

Each row is a habit from JavaScript, Python, C#, or similar languages that produces incorrect Jyro.

| Habit from other languages | Jyro |
| --- | --- |
| `+` joins strings | `&` joins strings. `+` is numeric only; a string operand is a compile error. `"Total: " & total` |
| String interpolation `${x}`, `f"{x}"`, `$"{x}"` | None. Build text with `&`: `"Order " & id & " shipped"` |
| `//` or `/* */` comments | `#` to end of line is the only comment. `//` is a parse error |
| Semicolons end statements | No separators at all. Statements follow one another; line ends are optional |
| Braces `{ }` delimit blocks | Keywords: `if c then ... end`, `while c do ... end`, `for ... do ... end`, `func F() ... end`. Every block closes with `end` |
| `else if` | `elseif`, one word |
| `&&`, `\|\|`, `!` | `and`, `or`, `not` |
| `===`, `!==` | `==`, `!=` only. They compare by value, deeply, and never equate different types |
| `let`, `const`, `function`, `def` | `var` declares a variable. `func` declares a function |
| `x = y = 0`, assignment as an expression | Assignment is a statement only |
| `for (i = 0; i < n; i++)` | `for i in 0 to n do ... end`. The end value is exclusive |
| `for (x of arr)`, `for x in list` | `foreach x in arr do ... end` |
| `for (key in obj)` | `foreach key in Keys(obj) do ... end`. A `foreach` directly over an object yields its values, not its keys |
| `arr.length`, `str.length` | `Length(arr)`, `Length(str)`. No value has methods or properties of its own |
| `arr.push(x)`, `arr.append(x)` | `arr = Append(arr, x)`. Every library function returns a new value and changes nothing |
| `str.toUpperCase()`, `str.split(",")`, `arr.map(f)` | `ToUpper(str)`, `Split(str, ",")`, `Map(arr, f)`. Functions are called by name with the value as the first argument |
| `arr[-1]` for the last element | `null`. Use `Last(arr)` or `arr[Length(arr) - 1]` |
| `arr[5] = x` extends a short array | Runtime error. An index may replace an element or append at exactly `Length(arr)` |
| `obj.missing.deeper` throws | Gives `null`. Reading through a missing property or a null never fails; there is no `?.` |
| `x ?? y`, `x \|\| y` for defaults | `??` replaces `null` only. `0`, `false`, and `""` are kept. `or` returns an operand by truthiness |
| `[]` and `{}` are falsy | They are truthy. Only `null`, `false`, `0`, and `""` are falsy |
| `typeof x === "number"`, `isinstance` | `x is number`, `x is not string`. Types: `null`, `boolean`, `number`, `string`, `array`, `object`, `function`, `any` |
| `key in obj` | `HasProperty(obj, "key")` |
| `Math.floor(x)`, `Math.round(x)` | `Floor(x)`, `Round(x, 0)`. `Round` requires the number of decimals |
| Integer division `7 / 2 == 3` | `7 / 2` is `3.5`. Use `Floor(7 / 2)` |
| `throw`, `raise`, `try/catch` | `fail "message"` ends the run with an error. There is no catch |
| `return` at the top level | `exit`, or `exit "message"`. `return` is valid only inside `func` |
| Nested functions, closures over outer variables | `func` must be at the top level, and its body sees only its parameters, its locals, and `Input`. Pass values in as arguments |
| A function writes to a global result | Neither a `func` body nor a lambda body can reference `Output`. A `func` returns a value; a lambda reads variables |
| Arrow functions with a block body `x => { ... }` | A lambda body is a single expression: `x => x.total * 2` |
| Calling a stored lambda `f(1)` | Impossible. A lambda is only ever passed to a function that calls it, such as `Map`, `Where`, `Reduce` |
| Passing a function by name `Map(xs, Double)` | Not a value. Wrap it: `Map(xs, x => Double(x))` |
| `switch` with `break` and fall-through | `switch v do case 1, 2 then ... case 3 then ... default then ... end`. No fall-through, several values per case, `default` last |
| `print`, `console.log` | None in the language. Put what should be seen into `Output` |
| Mutating `Input` | `Input` is frozen. `Clone(Input.items)` gives a writable copy |
| Trailing commas `[1, 2,]` | Parse error |
| Variables named `end`, `to`, `by`, `in`, `do`, `case`, `default`, `match`, `string`, `number`, `object`, `array` | All reserved. Choose other names (`finish`, `target`, `step`, `kind`, `text`, `count`, `item`, `items`) |
| `null` arguments are errors | Passing `null` to an optional parameter means "use the default". For a string parameter `null` reads as `""`; for an array parameter as `[]` |
| Dates are objects | Dates are strings in the form `yyyy-MM-ddTHH:mm:ss.fffZ`, always UTC. `Now()`, `DateAdd`, `DateDiff`, `FormatDate` work on them |
| Regular expressions have flags like `/i` | No flags. Lower-case both sides for case-insensitive matching. Write `\\d` inside a string literal |
| Loops over any size of data | Loop iterations are capped (1,000 in total by default). Use `Map`, `Where`, `Reduce`, `Sum`, `GroupBy`, `Range` for data of unknown size |

Three of these, demonstrated:

```jyro
Output.a = "Total: " + 42
```

```text
[JM3301] Ln 1, Col 12: The '+' operator does not accept a string operand
```

```jyro
var f = x => x + 1
Output.a = f(1)
```

```text
[JM4100] Ln 2, Col 12: Undefined function 'f'
```

```jyro
var items = [1, 2]
items[5] = 3
```

```text
[JM5300] Ln 2, Col 1: array position 5 is out of bounds for a length of 2
```

## 15. Checklist before delivering a script

1. Every string join uses `&`; `+` touches numbers only.
2. Every `if`, `while`, `for`, `foreach`, `switch`, `match`, `func`, and `union` closes with `end`; `if` branches use `then`, loops and `switch` use `do`, `elseif` is one word.
3. Comments start with `#`. No semicolons, no braces as block delimiters, no trailing commas.
4. No variable, parameter, or function is named with a reserved word (`end`, `to`, `by`, `in`, `do`, `case`, `default`, `match`, `string`, `number`, `object`, `array`, `function`, ...).
5. Every value added to an array is assigned back: `list = Append(list, x)`. No `.push`, `.length`, or any method call on a value.
6. Lambdas have a single-expression body, declare exactly the parameters the function passes, and are never called directly. Reusable logic is a top-level `func` called from the lambda.
7. `func` declarations are at the top level, read nothing but their parameters and `Input`, and never mention `Output`.
8. `Round` has its decimals argument; `SortByField` has its direction; `Merge` and `Coalesce` receive one array.
9. Intermediate objects exist before nested properties are assigned; `Input` is cloned before it is modified.
10. Loops are bounded by the data's known small size; otherwise the standard library does the iteration.
11. Business-rule violations use `fail "reason"` when the host must see a failure, or are collected into `Output` when the host expects a report.
12. The script writes everything the host needs into `Output` and nothing else; nothing is printed.
