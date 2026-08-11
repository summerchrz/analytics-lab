# Python/Databricks concepts, from building a real ingestion pipeline

Notes from building a Python function to read a messy spreadsheet export and
write it into a Delta table — a SQL-first person's field notes on the Python
concepts that came up, generalized so no specific project context is needed
to follow them. Written down while fresh, since these are exactly the kind
of small syntax/idiom things that are easy to look up once and then forget
under pressure the next time they matter.

## 1. Indentation is not style — it's the actual block structure

Coming from SQL, there's nothing equivalent to this: in Python, whether a
line is "inside" an `if`, a `for`, or a function isn't a formatting
preference, it's the only thing that tells Python which lines belong
together. Two lines at the same indentation level are in the same block,
full stop — there's no `BEGIN`/`END` or `{ }` to fall back on.

This bit me twice in the same function, in two different ways:

```python
# WRONG — everything after `raise` is unreachable, because it's
# nested one level too deep, INSIDE the if-block:
if not items:
    raise ValueError("nothing found")
    result = compute_something(items)   # never runs when items IS empty
                                          # (raise already stopped it)
                                          # and never runs when items is NOT
                                          # empty either (whole if-block skipped)
return result   # NameError: result was never assigned, either way
```

```python
# RIGHT — only `raise` is inside the if-block. Everything meant to
# run in the normal case is dedented back out, so it always runs
# once the guard-clause check has passed:
if not items:
    raise ValueError("nothing found")
result = compute_something(items)
return result
```

**Mental model for a "guard clause"** (an `if` whose only job is to stop
early on a bad input): it should contain exactly one line — the `raise` —
and nothing else. Anything meant to run in the normal case belongs *after*
it, at the outer indentation level, not nested inside.

## 2. List comprehensions — filtering a list in one line

A list comprehension is a compact way to write "loop over a list, keep only
some items, build a new list." The shape:

```python
[item for item in some_list if condition]
```

Read right to left: "for each `item` in `some_list`, if `condition` is
true, keep it." Example — filtering a list of file objects down to only the
ones with a specific extension:

```python
xlsx_files = [f for f in files if f.name.lower().endswith('.xlsx')]
```

(`.lower()` first, so it still matches regardless of how the filename was
capitalized.)

## 3. `lambda` + `max(..., key=...)` — "biggest according to a rule"

`max()` normally finds the largest value in a list of numbers. `key=`
lets you tell it "largest *according to what*" for a list of things that
aren't directly comparable on their own (you can't just ask "which of
these two file objects is bigger" — Python has no idea what that means
without help).

A `lambda` is a tiny, throwaway, unnamed function — good for exactly this
kind of "give me a quick rule, I don't need to name it" situation:

```python
lambda f: f.modified_at   # "given one item f, return its modified_at value"

newest = max(file_list, key=lambda f: f.modified_at)
```

This says: compute `.modified_at` for every item in `file_list`, and give
back the *whole original item* that had the largest one — not just the
largest timestamp by itself.

## 4. A function should do one job — and "find the file" isn't "read the file"

Early version of a real function mixed two unrelated responsibilities:
finding which file to open, and parsing its contents once opened. Splitting
them into two separate functions — one that takes a folder and returns a
file path, one that takes a file path and returns parsed data — made each
piece independently testable and reusable, and made a structural bug (see
#1) much easier to spot once "finding the file" wasn't tangled up with
"reading the file."

A useful smell test: if a function's name has "and" in it, or if you can't
describe what it returns in one short sentence, it's probably doing two
jobs that should be split.

## 5. Nullable integer types — plain `int` can't represent "no value"

Python's built-in `int`, and a plain integer column in most typed systems,
have no way to represent "missing" — only a real number. If a column has
even one genuinely missing value mixed in with real numbers, a straight
`.astype(int)` (or the equivalent typed-column write) always fails,
regardless of the tool — because it's being asked to represent something
that type fundamentally cannot hold.

pandas' answer is a **nullable** integer dtype, written with a capital `I`
— `'Int64'` — a genuinely different dtype from lowercase `'int64'`, built
specifically to hold real integers *and* true missing values in the same
column:

```python
df['count'] = df['count'].astype('Int64')   # works even with real nulls present
df['count'] = df['count'].astype('int64')   # errors the instant it hits a null
```

Same underlying lesson as the more famous `str()` vs. pandas' `'string'`
dtype trap: Python's *built-in* type coercion functions generally don't
know about "missing" as a first-class concept — pandas' own dtypes,
written with pandas' own specific capitalization, usually do.

## 5b. Don't fix a null/type problem before knowing what it represents

The temptation with any "this column has some missing values, some real
values" situation is to immediately pick a technical fix (drop the rows,
fill with 0, cast and hope). Better first step: find out what's actually
in the missing rows before deciding how to handle them.

```python
missing = df[df['some_column'].isna()]
missing['category_column'].value_counts()   # what do these rows have in common?
missing['other_important_column'].isna().mean()   # is something else also missing?
```

In practice this distinguished two very different situations that looked
identical from the outside ("this column has nulls"): one was a genuine
placeholder/junk pattern worth dropping, the other was a real, fully-valued
category of data that just doesn't have a value along *this specific*
dimension — dropping it would have silently thrown away real data. Same
"missing" symptom, opposite correct fix — only distinguishable by actually
looking at the rows, not by pattern-matching on the column name.

## 6. A DataFrame library's inferred type isn't the same as a database's declared type

When converting a pandas DataFrame into a typed destination (a database
table, a columnar file format), the conversion library infers a type for
each column based on the data it sees — and that inferred type doesn't
have to match whatever type you separately declared for the destination
column. "Both are integers" isn't good enough if one is a 32-bit integer
and the other a 64-bit integer — a strict destination can reject the
mismatch outright rather than silently widening or narrowing to fit.

Fix: explicitly cast the column to the exact destination type right before
writing, rather than relying on either side's automatic inference to agree:

```python
from pyspark.sql.functions import col
from pyspark.sql.types import IntegerType

spark_df = spark.createDataFrame(pandas_df).withColumn(
    "year", col("year").cast(IntegerType())
)
```

## 7. Multi-line method chains need an explicit continuation

A chain like `df.write.format(...).mode(...).saveAsTable(...)` is one
single Python statement. Splitting it across multiple lines is fine
*only* if Python has an explicit way to know the statement continues —
either wrap it in parentheses, or end every line except the last with a
backslash `\`:

```python
# WRONG — line 1 is already a complete, finished statement.
# Line 2 starts a new, incomplete one. SyntaxError.
df.write.format('delta').mode('overwrite')
.saveAsTable("some_table")

# RIGHT — explicit continuation on every line but the last
df.write.format('delta') \
    .mode('overwrite') \
    .saveAsTable("some_table")

# ALSO RIGHT — everything on one line, no continuation needed at all
df.write.format('delta').mode('overwrite').saveAsTable("some_table")
```

## 8. Platform-specific path prefixes vs. what the actual library call expects

Some platforms have their own internal notation for referring to files
(a scheme prefix like `dbfs:` in Databricks) that's meaningful to that
platform's own file-listing APIs, but not understood by general-purpose
libraries (like pandas) that just expect a normal filesystem path. Getting
a path *from* one API doesn't guarantee it's in the shape a *different*
API expects it in — worth checking (and stripping/adjusting the prefix)
rather than assuming a path is portable across every tool that touches it.

## Why this list exists

None of these are hard concepts once seen once — but "once seen once" is
the whole point of writing them down. Every one of these caused a real,
confusing error message that took a few minutes to diagnose the first
time; the goal of this note is that the *second* time one of these shows
up, it's a five-second "oh, that's the `Int64` thing" instead of a fresh
debugging session.
