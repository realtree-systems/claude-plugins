<!-- generated from jyro-for-llms.md (jyro-doc dab294a 2026-10-12) by tools/jyro/build.py; do not edit -->

# Jyro language reference

## 4. Lexical rules

**Comments.** `#` starts a comment that runs to the end of the line. There is no block comment.

**Identifiers.** Start with a letter or `_`, continue with letters, digits, or `_`. Case-sensitive. Standard library functions are PascalCase (`ToUpper`, `SortByField`); the exact spelling must be used.

**Reserved words** (38), which cannot be used as variable, parameter, or function names:

```text
and array boolean break by case continue default delete do downto else elseif end exit
fail false for foreach func if in is match not null number object or return string switch
then to true union var while
```

`any` and `function` are type names after `:` or `is` and are otherwise ordinary identifiers. A reserved word is allowed as a property name after `.` and as an object key: `Output.default = 1` and `{ for: 1 }` are valid.

**Numbers.** `42`, `3.25`, `1.5e3`, `0xFF`, `0b1010`. No leading zeros (`007`), no bare point (`.5`, `1.`), no sign in the literal (`-5` is unary minus applied to `5`).

**Strings.** `"text"` or `'text'`, equivalent. Escapes: `\n`, `\r`, `\t`, `\\`, `\"`, `\'`, `\0`, `\uXXXX` (exactly four hex digits). No other escape is valid, and there is no interpolation. A line end inside a literal is allowed and is part of the string.

**Booleans and null.** `true`, `false`, `null`, lowercase.

**Arrays and objects.** `[1, "a", null]`, `{ name: "Ada", "first-name": "Ada", if: 1 }`. Keys may be bare identifiers, reserved words, or strings. No trailing commas. A repeated key keeps the last value.

**Line ends.** Statements need no separator and may share a line. An expression may continue on the next line when that line starts with an operator, `.`, or `?`. A line that starts with `(`, `[`, `++`, or `--` begins a new statement, so an index or a call must open on the same line as the expression it applies to. The value after `return`, `exit`, or `fail` must start on the same line as the keyword.

```jyro
var a = 1 var b = 2
Output.sum = a
    + b
Output.name = { first: "Ada" }
    .first
```

```json
{ "sum": 3, "name": "Ada" }
```

## 5. Values

| Type | Literal | Notes |
| --- | --- | --- |
| null | `null` | The value of a missing property, an index out of range, an undeclared-initializer variable, and a function that returns nothing |
| boolean | `true`, `false` | |
| number | `42`, `3.5` | Exact decimal when it fits (28 decimal places, significand below 2^96), otherwise a double. Never NaN or infinite |
| string | `"text"` | A sequence of UTF-16 code units. Immutable |
| array | `[1, 2]` | Ordered, mutable, shared by reference |
| object | `{ a: 1 }` | Ordered string-keyed map, mutable, shared by reference. Properties keep insertion order |
| function | `x => x + 1` | A lambda value. Can be stored and passed, never called directly |

`TypeOf(value)` returns the type name as a string. `value is type` tests it.

### Truthiness

Falsy: `null`, `false`, `0`, `""`. Truthy: everything else, including `[]`, `{}`, `"0"`, `-1`, and every function. Conditions, `and`, `or`, `not`, and `Where` use truthiness.

### Equality and ordering

`==` and `!=` compare any two values and never fail. Different types are never equal: `0 == "0"`, `0 == false`, `null == 0`, `"" == null` are all `false`. Arrays and objects compare by content, deeply; property order does not matter. Functions compare by identity.

`<`, `<=`, `>`, `>=` compare two numbers or two strings (by code unit, so `"B" < "a"` and `"10" < "9"`). Any other pair is a runtime error.

```jyro
Output.a = [1, 2] == [1, 2.0]
Output.b = { x: 1, y: 2 } == { y: 2, x: 1 }
Output.c = "1" == 1
Output.d = null == false
Output.e = "apple" < "banana"
```

```json
{ "a": true, "b": true, "c": false, "d": false, "e": true }
```

### Numbers

- `+ - * / %` on numbers only. `/` gives a decimal: `7 / 2` is `3.5`. `%` keeps the sign of the dividend: `-7 % 3` is `-1`.
- Division or modulo by zero is a runtime error.
- Exact arithmetic: `0.1 + 0.2` is exactly `0.3`. A result that cannot be exact, such as `1 / 3`, becomes a double.
- The string form (used by `&` and `ToString`) of an exact number has no exponent and no trailing zeros: `1.50` prints as `1.5`.
- `Round(value, decimals)` needs the decimals argument. `Round(2.345, 2)` is `2.35` (half up). `Round(x, 0)` rounds to a whole number. `Floor` and `Ceiling` give integers.

### Strings

- `&` joins any non-container values: numbers and booleans become their text, `null` becomes `null`. An array or object operand is a runtime error; use `ToJson(value)` or `Join(array, ", ")`.
- `Length("abc")` is 3. `"abc"[0]` is `"a"`. An index out of range gives `null`.
- Comparison and `Contains`, `IndexOf`, `Replace`, `Split` are case-sensitive and exact. For case-insensitive work, apply `ToLower` to both sides.

### Arrays

- Read: `a[i]` for `i` from `0` to `Length(a) - 1`; any other index gives `null`; a fractional index is an error.
- Write: `a[i] = v` replaces an element, or appends when `i == Length(a)`. Any other index is a runtime error. The usual way to add is `a = Append(a, v)`.
- `delete` does not apply to arrays; use `RemoveAt`, `RemoveFirst`, `RemoveLast`.
- `foreach` visits a snapshot of the array taken when the loop starts.

### Objects

- Read: `o.name` or `o["name"]`. A missing property gives `null`; reading a property of a non-object gives `null`; a chain through nulls gives `null`.
- Write: `o.name = v` adds or replaces. The target must already be an object: `Output.order.total = 1` fails unless `Output.order` was assigned an object first.
- `delete o.name` removes a property. `Keys(o)`, `Values(o)`, `HasProperty(o, "name")`, `Merge([o1, o2])`, `Clone(o)`.
- Property order is insertion order, and `Keys` returns it.

### Reference semantics

Arrays and objects are shared by reference. Assigning, passing, and storing share the same value; a change through one reference is visible through all. `Clone(value)` makes a deep copy. Standard library functions return new containers but do not copy the elements inside them.

`Input` and everything reachable from it is frozen. A write through any reference to it is a runtime error; `Clone` first.

```jyro
# input: { "items": [ { "n": 1 } ] }
var items = Clone(Input.items)
items[0].n = 2
var alias = items
alias = Append(alias, { n: 3 })
Output.items = items
Output.alias = alias
Output.original = Input.items
```

```json
{ "items": [{ "n": 2 }], "alias": [{ "n": 2 }, { "n": 3 }], "original": [{ "n": 1 }] }
```

## 6. Variables and scope

```jyro
# fragment
var name                      # null
var name = expression
var name: number = expression # typed: every later assignment is converted to number or fails
```

- A variable must be declared before use, and once per scope. Blocks (`if`, loops, `case`, function bodies) are scopes; an inner block may shadow an outer variable.
- Assignment: `name = value`, `obj.prop = value`, `arr[i] = value`. Compound: `+= -= *= /= %= &=`. Increment: `x++`, `++x`, `x--`, `--x` (also on properties and elements).
- A typed variable converts on assignment: a string `"42"` into a `number` variable becomes `42`; `"abc"` is a runtime error. Types: `number`, `string`, `boolean`, `array`, `object`, `null`, `function`, `any`.
- `Input` and `Output` are the only predefined names. Neither can be declared or used as a parameter name.
- A `func` body is sealed: it sees its parameters, its own variables, `Input`, and other functions. It cannot see script-level variables and cannot reference `Output`.

## 7. Operators, tightest first

| Level | Operators | Associativity |
| --- | --- | --- |
| 1 | `f(args)`, `.name`, `[i]`, postfix `++` `--` | left |
| 2 | prefix `++` `--`, unary `-` | right |
| 3 | `*` `/` `%` | left |
| 4 | `+` `-` | left |
| 5 | `&` | left |
| 6 | `<` `<=` `>` `>=` | left |
| 7 | `==` `!=` | left |
| 8 | `is`, `is not` | not chainable |
| 9 | `not` | right |
| 10 | `and` | left |
| 11 | `or` | left |
| 12 | `??` | right |
| 13 | `c ? a : b` | right |
| 14 | `params => body` | body extends right |

Consequences: `"n=" & 1 + 2` is `"n=3"`; `not a == b` is `not (a == b)`; `x is number and x > 0` works without parentheses; `a ?? b or c` is `a ?? (b or c)`; `1 < 2 < 3` is an error (boolean compared with number). `and` and `or` short-circuit and return an operand: `null or "default"` is `"default"`, `"a" and "b"` is `"b"`. `??` short-circuits and only replaces `null`.

## 8. Statements

### if

```jyro
# input: { "score": 85 }
var grade
if Input.score >= 90 then
    grade = "A"
elseif Input.score >= 80 then
    grade = "B"
else
    grade = "C"
end
Output.grade = grade
```

```json
{ "grade": "B" }
```

### switch

Compares the subject with each case value by `==`, first match wins, no fall-through, `default` optional and last.

```jyro
# input: { "status": "created" }
switch Input.status do
    case "ok", "created" then
        Output.state = "success"
    case "error" then
        Output.state = "failure"
    default then
        Output.state = "unknown"
end
```

```json
{ "state": "success" }
```

### while, for, foreach

```jyro
var n = 1
var steps = 0
while n < 100 do
    n *= 2
    steps++
end
var up = []
for i in 0 to 5 do
    up = Append(up, i)
end
var down = []
for i in 10 downto 0 by 3 do
    down = Append(down, i)
end
var seen = []
foreach item in ["a", "b"] do
    seen = Append(seen, item)
end
var total = 0
foreach value in { x: 1, y: 2 } do
    total += value
end
Output.n = n
Output.steps = steps
Output.up = up
Output.down = down
Output.seen = seen
Output.total = total
```

```json
{ "n": 128, "steps": 7, "up": [0, 1, 2, 3, 4], "down": [10, 7, 4, 1], "seen": ["a", "b"], "total": 3 }
```

- `for i in start to finish [by step]`: `finish` is exclusive; `step` must be a positive integer; `downto` counts down. The loop variable is fresh each iteration and assigning to it does not change the sequence.
- `foreach x in collection`: arrays give elements, objects give values (use `Keys(obj)` for keys), strings give one-character strings. Any other value is a runtime error.
- `break` ends the innermost loop; `continue` starts its next iteration.
- Every iteration of every loop counts toward the run's loop limit (1,000 by default, in total). Use standard library functions for data of unknown size.

### return, exit, fail, delete

- `return [value]`: ends a `func` call. Only inside `func`. Bare `return` gives `null`.
- `exit [value]`: ends the whole run successfully with the current `Output`; the value, if any, becomes a message the host can read. Allowed anywhere, including inside a `func`.
- `fail [value]`: ends the run with an error whose message is the value's text. `Output` so far is returned with the error. Use it for business rule violations the host must see as failures.
- `delete obj.key` or `delete obj[key]`: removes a property. No effect when absent.

```jyro
# input: { "qty": -2 }
if Input.qty < 0 then
    fail "Quantity must not be negative: " & Input.qty
end
Output.ok = true
```

```text
[JM5004] Ln 3, Col 5: Quantity must not be negative: -2
```

## 9. Functions

```jyro
# fragment
func Name(required, typed: number, optional = "literal", typedOptional: number = -1)
    statements
    return value
end
```

Rules:

- Top level only: not inside `if`, a loop, or another `func`. Functions are visible throughout the script, including before their declaration, so order and mutual recursion are free.
- A default must be a literal (or `-` and a number literal). Required parameters come before optional ones. Passing `null` to an optional parameter selects its default.
- Typed parameters convert their argument (`"5"` to a `number` parameter becomes `5`).
- Calls use all positional or all named arguments, never mixed: `F(1, 2)` or `F(b: 2, a: 1)`.
- The body sees only its parameters, its locals, `Input`, and other functions. It cannot read script variables or touch `Output`. It can change the contents of an array or object passed to it, since those are shared by reference.
- A function name is not a value: it cannot be stored or passed. Wrap it in a lambda.
- A name cannot repeat a standard library or host function name (`Length`, `Sum`, `Log`, `Select`, ...), whether or not the library is enabled.
- Recursion is allowed; call depth is limited (64 by default).

```jyro
func Price(amount: number, taxRate: number = 0.1, currency: string = "USD")
    return currency & " " & Round(amount * (1 + taxRate), 2)
end
Output.a = Price(100)
Output.b = Price(100, 0.2)
Output.c = Price(amount: 50, currency: "EUR")
Output.d = Price(100, null, "GBP")
```

```json
{ "a": "USD 110", "b": "USD 120", "c": "EUR 55", "d": "GBP 110" }
```

```jyro
var rate = 0.2
func Tax(amount)
    return amount * rate
end
```

```text
[JM3100] Ln 3, Col 21: Undeclared variable 'rate'
```

## 10. Lambdas

Forms: `x => expr`, `(x) => expr`, `(a, b) => expr`, `() => expr`. The body is one expression, which may be a conditional, a `match` expression, an object or array literal, or a call. A lambda captures the variables in scope where it is written and reads their current values when it runs. It can read `Input`, never `Output`.

A lambda is passed to a function that calls it. The standard library functions that take one, and the arguments they pass:

| Function | Lambda parameters | Returns |
| --- | --- | --- |
| `Map(items, f)` | `(item)` | array of results |
| `Where(items, f)` | `(item)` | elements where the result is truthy |
| `Find(items, f)` | `(item)` | first element where the result is truthy, or `null` |
| `Any(items, f)`, `All(items, f)` | `(item)` | boolean |
| `SortBy(items, f)` | `(item)` | elements ordered by the key `f` returns |
| `Each(items, f)` | `(item)` | `null`; used for side effects such as `item.flag = true` through `item.count++` |
| `Reduce(items, f, initial)` | `(accumulator, item)` | the last accumulator |

The lambda must declare exactly the number of parameters the function passes. A lambda cannot be called by the script. To reuse logic, declare a `func` and call it from a lambda: `Map(items, x => Score(x))`.

```jyro
# input: { "orders": [ { "id": 1, "total": 50, "tags": ["new"] }, { "id": 2, "total": 150, "tags": [] } ] }
var threshold = 100
Output.large = Map(Where(Input.orders, o => o.total > threshold), o => o.id)
Output.sum = Reduce(Input.orders, (acc, o) => acc + o.total, 0)
Output.first = Find(Input.orders, o => Length(o.tags) > 0).id
Output.sorted = Map(SortBy(Input.orders, o => -o.total), o => o.id)
Output.labels = Map(Input.orders, o => o.total >= 100 ? "big" : "small")
```

```json
{ "large": [2], "sum": 200, "first": 1, "sorted": [2, 1], "labels": ["small", "big"] }
```

## 11. Unions and match

A union declares a closed set of variants, each with zero or more fields. A variant is constructed by calling its name; the value is an object with a `_variant` property and one property per field. `match` must cover every variant and has no `default`. `match` exists as a statement and as an expression.

```jyro
union Payment
    Card(last4: string)
    Transfer(reference: string)
    Cash
end
func Describe(p)
    return match p do
        case Card(last4) then "card ending " & last4
        case Transfer(ref) then "transfer " & ref
        case Cash then "cash"
    end
end
Output.a = Describe(Card(4242))
Output.b = Describe(Cash())
Output.value = Transfer("T-1")
match Card("0001") do
    case Card(digits) then
        Output.digits = digits
    case Transfer(ref) then
        Output.digits = null
    case Cash then
        Output.digits = null
end
```

```json
{
  "a": "card ending 4242",
  "b": "cash",
  "value": { "_variant": "Transfer", "reference": "T-1" },
  "digits": "0001"
}
```

Unions are declared at the top level only. A zero-field variant is constructed with parentheses: `Cash()`. Unions are optional; most business scripts use plain objects and `switch`.
