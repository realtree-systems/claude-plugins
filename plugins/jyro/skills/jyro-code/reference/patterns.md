<!-- generated from jyro-for-llms.md (jyro-doc dab294a 2026-10-12) by tools/jyro/build.py; do not edit -->

# Jyro examples and patterns

## 3. A complete example

```jyro
# input: { "customer": { "name": "Ada Lovelace", "tier": "gold" }, "lines": [ { "sku": "A1", "qty": 2, "unitPrice": 9.99 }, { "sku": "B2", "qty": 1, "unitPrice": 24.5 }, { "sku": "C3", "qty": 0, "unitPrice": 3 } ] }
# Price an order: drop empty lines, total it, apply a tier discount.

var discountRate = Input.customer.tier == "gold" ? 0.1 : 0

var lines = Where(Input.lines, line => line.qty > 0)
var subtotal = Sum(Map(lines, line => line.qty * line.unitPrice))
var discount = Round(subtotal * discountRate, 2)

Output.customer = Input.customer.name
Output.lineCount = Length(lines)
Output.subtotal = subtotal
Output.discount = discount
Output.total = subtotal - discount
Output.summary = Output.customer & " owes " & Output.total
```

```json
{
  "customer": "Ada Lovelace",
  "lineCount": 2,
  "subtotal": 44.48,
  "discount": 4.45,
  "total": 40.03,
  "summary": "Ada Lovelace owes 40.03"
}
```

## 14. Patterns for business problems

### Filter, transform, aggregate

Covered in section 3. The shape: `Where` to select, `Map` to transform, `Sum`/`Average`/`Length`/`Reduce` to aggregate, `Round` for money.

### Group and summarize

Intermediate results live in variables: a lambda, like a `func`, cannot read `Output`.

```jyro
# input: { "sales": [ { "region": "west", "amount": 100 }, { "region": "east", "amount": 50 }, { "region": "west", "amount": 25 } ] }
var groups = GroupBy(Input.sales, "region")
var totals = {}
foreach region in Keys(groups) do
    totals[region] = Sum(Map(groups[region], s => s.amount))
end
Output.byRegion = totals
Output.regions = Keys(groups)
Output.largest = Last(SortBy(Keys(groups), r => totals[r]))
```

```json
{ "byRegion": { "west": 125, "east": 50 }, "regions": ["west", "east"], "largest": "west" }
```

### Look up one array by another

Build an index object keyed by identifier, then read through it. A missing key gives `null`, and `??` supplies the fallback.

```jyro
# input: { "products": [ { "id": "p1", "name": "Bolt" }, { "id": "p2", "name": "Nut" } ], "orders": [ { "product": "p2", "qty": 3 }, { "product": "p9", "qty": 1 } ] }
var byId = {}
foreach p in Input.products do
    byId[p.id] = p
end
Output.lines = Map(Input.orders, o => {
    product: byId[o.product].name ?? "unknown",
    qty: o.qty
})
Output.unknown = Map(Where(Input.orders, o => not HasProperty(byId, o.product)), o => o.product)
```

```json
{ "lines": [{ "product": "Nut", "qty": 3 }, { "product": "unknown", "qty": 1 }], "unknown": ["p9"] }
```

### Validate and report problems

Collect problems into `Output` when the host expects a report; use `fail` when the host expects a failure.

```jyro
# input: { "order": { "id": 17, "email": "", "items": [] } }
var check = ValidateRequired(Input.order, ["id", "email", "customer"])
var problems = Map(check.errors, e => e.field & " is " & e.reason)
if Length(Input.order.items) == 0 then
    problems = Append(problems, "items is empty")
end
Output.valid = Length(problems) == 0
Output.problems = problems
```

```json
{ "valid": false, "problems": ["email is empty", "customer is missing", "items is empty"] }
```

### Dates and deadlines

```jyro
# input: { "invoiced": "2024-01-15", "paid": "2024-02-03T10:00:00Z", "termsDays": 14 }
var due = DateAdd(Input.invoiced, Input.termsDays, "days")
Output.due = FormatDate(due, "yyyy-MM-dd")
Output.daysLate = Floor(DateDiff(due, Input.paid, "days"))
Output.late = DateDiff(due, Input.paid, "seconds") > 0
Output.month = DatePart(Input.paid, "month")
Output.weekday = DatePart(Input.paid, "dayofweek")
```

```json
{ "due": "2024-01-29", "daysLate": 5, "late": true, "month": 2, "weekday": 6 }
```

### Money

```jyro
# input: { "prices": [19.99, 5.01, 0.1, 0.2] }
Output.total = Sum(Input.prices)
Output.withTax = Round(Output.total * 1.075, 2)
Output.average = Round(Average(Input.prices), 2)
Output.each = Map(Input.prices, p => Round(p * 1.075, 2))
Output.cents = Floor(Output.total * 100)
```

```json
{ "total": 25.3, "withTax": 27.2, "average": 6.33, "each": [21.49, 5.39, 0.11, 0.22], "cents": 2530 }
```

### Build text

```jyro
# input: { "rows": [ { "sku": "A1", "qty": 2 }, { "sku": "B22", "qty": 10 } ] }
var lines = Map(Input.rows, r => PadRight(r.sku, 5) & PadLeft("" & r.qty, 4))
Output.report = Join(lines, "\n")
Output.csv = Join(Map(Input.rows, r => r.sku & "," & r.qty), "\n")
Output.title = ToUpper(Input.rows[0].sku) & " and " & (Length(Input.rows) - 1) & " more"
Output.id = "ORD-" & PadLeft("" & 42, 6, "0")
```

```json
{ "report": "A1      2\nB22    10", "csv": "A1,2\nB22,10", "title": "A1 and 1 more", "id": "ORD-000042" }
```

### Defaults and missing data

```jyro
# input: { "user": { "profile": null, "tags": ["a"], "age": "41" } }
Output.city = Input.user.profile.address.city ?? "unknown"
Output.hasTags = Input.user.tags is array and Length(Input.user.tags) > 0
Output.first = First(Input.user.tags) ?? "none"
Output.known = HasProperty(Input.user, "profile")
Output.count = Length(Input.user.missing)
Output.age = ToNumber(Input.user.age) ?? 0
Output.name = Coalesce([Input.user.nickname, Input.user.name, "anonymous"])
```

```json
{ "city": "unknown", "hasTags": true, "first": "a", "known": true, "count": 0, "age": 41, "name": "anonymous" }
```

### Classify

```jyro
# input: { "scores": [95, 72, 48] }
Output.grades = Map(Input.scores, s => s >= 90 ? "A" : s >= 70 ? "B" : "C")
var labels = []
foreach s in Input.scores do
    switch Floor(s / 10) do
        case 9, 10 then
            labels = Append(labels, "top")
        case 7, 8 then
            labels = Append(labels, "middle")
        default then
            labels = Append(labels, "bottom")
    end
end
Output.labels = labels
```

```json
{ "grades": ["A", "B", "C"], "labels": ["top", "middle", "bottom"] }
```

### Sort, rank, deduplicate

```jyro
# input: { "employees": [ { "name": "Ann", "sales": 300 }, { "name": "Bob", "sales": 500 }, { "name": "Cy", "sales": 400 } ] }
var ranked = SortByField(Input.employees, "sales", "desc")
Output.top2 = Map(Slice(ranked, 0, 2), e => e.name)
Output.best = First(ranked).name
Output.names = Sort(Map(Input.employees, e => e.name))
Output.bands = Distinct(Map(Input.employees, e => Floor(e.sales / 200)))
Output.open = CountIf(Input.employees, "sales", ">=", 400)
Output.anyLow = AnyByField(Input.employees, "sales", "<", 350)
Output.max = Max(Select(Input.employees, "sales"))
```

```json
{ "top2": ["Bob", "Cy"], "best": "Bob", "names": ["Ann", "Bob", "Cy"], "bands": [1, 2], "open": 2, "anyLow": true, "max": 500 }
```

### Nested output

Create each intermediate object or array before writing into it.

```jyro
# input: { "id": 7 }
Output.order = { id: Input.id, status: {} }
Output.order.status.code = "new"
Output.order.history = []
Output.order.history[0] = "created"
Output.order.history = Append(Output.order.history, "queued")
Output.order.count = Length(Output.order.history)
```

```json
{ "order": { "id": 7, "status": { "code": "new" }, "history": ["created", "queued"], "count": 2 } }
```

### Return something other than an object, and stop early

```jyro
# input: { "names": ["b", "a"] }
if Length(Input.names) == 0 then
    Output = []
    exit "nothing to do"
end
Output = Sort(Input.names)
```

```json
["a", "b"]
```

### Iterate an object

```jyro
# input: { "stock": { "bolt": 12, "nut": 0, "washer": 3 } }
var empty = []
foreach name in Keys(Input.stock) do
    if Input.stock[name] == 0 then
        empty = Append(empty, name)
    end
end
Output.empty = empty
Output.totalUnits = Sum(Values(Input.stock))
Output.lines = Map(Keys(Input.stock), k => k & ": " & Input.stock[k])
```

```json
{ "empty": ["nut"], "totalUnits": 15, "lines": ["bolt: 12", "nut: 0", "washer: 3"] }
```
