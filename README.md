# TOON for ColdFusion

A ColdFusion 2016+ implementation of **TOON (Token-Oriented Object Notation)** - a compact, human-readable serialization format designed for passing structured data to Large Language Models with significantly reduced token usage.

## What is TOON?

TOON is a data format that achieves **30-60% fewer tokens** than JSON by:
- Declaring array field names once instead of repeating them
- Using indentation (like YAML) instead of braces
- Minimizing punctuation and quotes
- Providing explicit structure that helps LLMs parse and validate data

**Perfect for:** Uniform arrays of objects (tabular data), LLM prompts, API payloads where token efficiency matters.

## Installation

Simply copy `Toon.cfc` to your ColdFusion application and instantiate it:

```coldfusion
toon = new Toon();
```

## Quick Start

### Encoding

```coldfusion
// Create some data
data = {
    users: [
        {id: 1, name: "Alice", role: "admin"},
        {id: 2, name: "Bob", role: "user"}
    ]
};

// Encode to TOON
toonString = toon.encode(data);

writeOutput(toonString);
```

**Output:**
```
users[2]{id,name,role}:
1,Alice,admin
2,Bob,user
```

Compare to JSON (102 characters vs 56 characters = **45% savings**):
```json
{
  "users": [
    {"id": 1, "name": "Alice", "role": "admin"},
    {"id": 2, "name": "Bob", "role": "user"}
  ]
}
```

### Decoding

```coldfusion
toonString = "users[2]{id,name,role}:
1,Alice,admin
2,Bob,user";

data = toon.decode(toonString);

// data is now: {users: [{id:1, name:"Alice", role:"admin"}, {id:2, name:"Bob", role:"user"}]}
```

## API Reference

### encode(value, options)

Converts ColdFusion data (structs, arrays, primitives) to TOON format.

**Parameters:**
- `value` (required) - Any ColdFusion value to encode
- `options` (optional) - Struct with encoding options:
  - `indent` (number) - Spaces per indentation level (default: 2)
  - `delimiter` (string) - Array delimiter: `,` (comma), `\t` (tab), or `|` (pipe) (default: `,`)
  - `lengthMarker` (string or boolean) - Prefix for array lengths: `"#"` to enable, `false` to disable (default: false)

**Returns:** String containing TOON-formatted data

**Example:**
```coldfusion
// Standard encoding
result = toon.encode(data);

// Tab-delimited (often more token-efficient)
result = toon.encode(data, {delimiter: chr(9)});

// With length marker (#)
result = toon.encode(data, {lengthMarker: "##"});

// 4-space indentation
result = toon.encode(data, {indent: 4});
```

### decode(input, options)

Converts TOON-formatted string back to ColdFusion data.

**Parameters:**
- `input` (required) - TOON-formatted string
- `options` (optional) - Struct with decoding options:
  - `indent` (number) - Expected indentation level (default: 2)
  - `strict` (boolean) - Enable strict validation (default: true)

**Returns:** ColdFusion value (struct, array, or primitive)

**Example:**
```coldfusion
// Standard decoding
data = toon.decode(toonString);

// Lenient decoding (skip validation)
data = toon.decode(toonString, {strict: false});
```

## Format Examples

### Simple Objects

```coldfusion
{id: 123, name: "Ada", active: true}
```
→
```
id: 123
name: Ada
active: true
```

### Nested Objects

```coldfusion
{
    user: {
        id: 123,
        name: "Ada"
    }
}
```
→
```
user:
  id: 123
  name: Ada
```

### Primitive Arrays

```coldfusion
{tags: ["reading", "gaming", "coding"]}
```
→
```
tags[3]: reading,gaming,coding
```

### Tabular Arrays (TOON's Sweet Spot)

```coldfusion
{
    items: [
        {sku: "A1", qty: 2, price: 9.99},
        {sku: "B2", qty: 1, price: 14.5}
    ]
}
```
→
```
items[2]{sku,qty,price}:
A1,2,9.99
B2,1,14.5
```

### Mixed List Arrays

```coldfusion
{
    mixed: [
        "text",
        123,
        {name: "object", value: 42},
        ["inner", "array"]
    ]
}
```
→
```
mixed[4]:
- text
- 123
- name: object
  value: 42
- [2]: inner,array
```

### Empty Values

```coldfusion
{
    emptyArray: [],
    emptyStruct: {},
    nullValue: javacast("null", "")
}
```
→
```
emptyArray[0]:
emptyStruct:
nullValue: null
```

## Delimiter Options

TOON supports three delimiter types for array values:

### Comma (Default)
```coldfusion
result = toon.encode(data, {delimiter: ","});
```
```
items[2]{sku,qty,price}:
A1,2,9.99
B2,1,14.5
```

### Tab (Often Most Efficient)
```coldfusion
result = toon.encode(data, {delimiter: chr(9)});
```
```
items[2 ]{sku qty price}:
A1	2	9.99
B2	1	14.5
```
- Single-character delimiter
- Rarely needs escaping
- Can save additional tokens

### Pipe
```coldfusion
result = toon.encode(data, {delimiter: "|"});
```
```
items[2|]{sku|qty|price}:
A1|2|9.99
B2|1|14.5
```
- Good visual separator
- Rarely appears in data

## String Quoting Rules

TOON only quotes strings when necessary to maximize token efficiency:

```coldfusion
[  // using an ordered struct
    unquoted: "hello world",           // hello world (no quotes needed)
    withComma: "hello, world",         // "hello, world" (contains delimiter)
    withColon: "key: value",           // "key: value" (contains colon)
    withSpaces: "  padded  ",          // "  padded  " (leading/trailing spaces)
    numericString: toString("123"),    // "123" (looks like number, must quote or use toString/javascast("string"))
    versionString: toString("1.0"),    // "1.0" (looks like number, must quote or use toString/javascast("string"))
    boolString: toString("true"),      // "true" (looks like boolean, must quote or use toString/javascast("string"))
    yesString: toString("yes"),        // "yes" (CF treats as boolean, must quote or use toString/javascast("string"))
    noString: toString("NO"),          // "NO" (CF treats as boolean, must quote or use toString/javascast("string"))
    emoji: "Hello 👋 World",           // Hello 👋 World (Unicode safe)
]
```

**Quoted when:**
- Empty string
- Leading or trailing spaces
- Contains delimiter, colon, quote, backslash, or control chars
- **Looks like a number** (e.g., `"123"`, `"1.0"`, `"3.14"`) - always quoted or use toString/javascast("string") to preserve string type
- Looks like boolean/null (e.g., `"true"`, `"false"`, `"yes"`, `"no"`, `"YES"`, `"NO"`, `"null"`)
- Starts with `"- "` (list-like)
- Looks like structural token (`[5]`, `{key}`)

**Unquoted:**
- Regular text with inner spaces (e.g., `hello world`)
- Unicode and emoji safe
- Most natural text that doesn't match above rules

## Length Marker Option

Add `#` prefix to array lengths to emphasize count vs. index:

```coldfusion
result = toon.encode(data, {lengthMarker: "##"});
```

```
tags[#3]: reading,gaming,coding
items[#2]{sku,qty,price}:
A1,2,9.99
B2,1,14.5
```

This can help LLMs better understand that `[N]` represents a count, not an array index.

## Using TOON with LLMs

TOON works best when you show the format rather than describe it:

```markdown
Data is in TOON format (2-space indent, arrays show length and fields).

```toon
employees[3]{id,name,department,salary}:
1,Alice,Engineering,95000
2,Bob,Sales,75000
3,Charlie,Marketing,70000
```

Task: Calculate the total salary for all employees in Engineering.
```

**For LLM output:**
```markdown
Return employees with salary > 80000 as TOON.
Use this header: employees[N]{id,name,department,salary}:
Set [N] to match the row count.
```

## Features

✅ **Full TOON Specification Support**
- Primitive types (string, number, boolean, null)
- Objects and nested objects
- Arrays (primitive, tabular, list, and nested)
- Indentation-based structure
- Selective string quoting
- Multiple delimiter options
- Length markers

✅ **ColdFusion Integration**
- Native struct/array handling
- Date serialization (ISO 8601)
- Null value support
- Round-trip encoding/decoding

✅ **Encoding Options**
- Custom indentation (2-space, 4-space, etc.)
- Delimiter selection (comma, tab, pipe)
- Length marker prefix
- Automatic type detection

✅ **Decoding Options**
- Strict validation mode
- Auto-delimiter detection
- Format error reporting
- Lenient parsing mode

## When to Use TOON

**TOON excels at:**
- ✅ Uniform arrays of objects (same fields, primitive values)
- ✅ Large datasets with consistent structure
- ✅ LLM prompts where token efficiency matters
- ✅ Tabular data (like CSV but with structure)

**JSON is better for:**
- ❌ Non-uniform data (varying field sets)
- ❌ Deeply nested structures
- ❌ Mixed-type arrays
- ❌ APIs requiring JSON

## Benchmarks

Based on TOON project benchmarks (using GPT tokenizer):

| Dataset | JSON Tokens | TOON Tokens | Savings |
|---------|-------------|-------------|---------|
| GitHub Repos (100) | 15,145 | 8,745 | 42.3% |
| Daily Analytics (180 days) | 10,977 | 4,507 | 58.9% |
| E-Commerce Order | 257 | 166 | 35.4% |

**Your mileage may vary** based on:
- Data structure (uniform vs. mixed)
- Tokenizer used (GPT, Claude, etc.)
- Delimiter choice (tab often best)

## Implementation Notes

### Type Handling

TOON preserves data types with high fidelity using Java class metadata:

**Type Detection:** The component uses `getMetadata()` to check the actual underlying Java class of values, ensuring reliable type detection despite ColdFusion's permissive type system.

- **Integers:** Encoded without decimal point (e.g., `3`, `100`). Decoded as integer type using `javacast("int", ...)`.
- **Decimals:** Encoded with decimal point (e.g., `3.14`, `99.99`). Decoded as double type using `javacast("double", ...)`.
- **Booleans:** Encoded as literal `true` or `false`. Decoded as boolean type using `javacast("boolean", ...)`.
- **Null:** Encoded as `null`. Decoded as `javacast("null", "")`.
- **Numeric Strings:** Automatically quoted to preserve string type (e.g., `"1.0"`, `"123"`, `"00123"`). This ensures version numbers and numeric IDs remain strings.
- **Boolean Strings:** Quoted to distinguish from boolean literals (e.g., `"true"` vs `true`, `"yes"` vs yes/no variations).
- **Date Strings:** Treated as strings with no automatic formatting or timezone conversion. Use ISO 8601 format for dates (e.g., `"2025-01-15T10:30:00Z"`).
- **Empty containers:** `[]` → `[0]:`, `{}` → empty output

**Important:**
- ColdFusion's type system is extremely permissive (`isBoolean("1")` returns true, `isNumeric("true")` can return true in some contexts)
- The component uses Java class introspection via `getMetadata()` for reliable type detection
- When creating test data or working with the component, use `javacast()` to ensure values have the intended type
- Quoted values in TOON format always decode as strings, preserving the encoder's intent

### Validation

Strict mode (default) validates:
- Array length matches declared count
- Proper indentation levels
- Valid escape sequences
- Correct delimiter usage

Lenient mode skips these checks for more forgiving parsing.

### Edge Cases

```coldfusion
// Empty root array
toon.encode([]);  // [0]:

// Empty root object
toon.encode({});  // (empty string)

// Root primitive
toon.encode("hello");  // hello

// Root array of primitives
toon.encode(["a", "b", "c"]);  // [3]: a,b,c
```

## Examples

See `ToonExamples.cfm` for comprehensive examples including:
1. Simple objects
2. Tabular arrays (users, products)
3. E-commerce orders
4. Primitive arrays
5. Mixed list arrays
6. Length markers
7. String quoting rules
8. Analytics data
9. Empty values and edge cases
10. Custom indentation
11. LLM token efficiency demo
12. Round-trip validation

## Requirements

- ColdFusion 2016 or higher
- Support for cfscript syntax
- Java cast for null values

## Testing

Run `ToonExamples.cfm` to see encoding/decoding in action with various data structures.

## Error Handling

The decoder throws `TOON.ParseError` exceptions with descriptive messages:

```coldfusion
try {
    data = toon.decode(invalidToon);
} catch (any e) {
    if (e.type == "TOON.ParseError") {
        writeOutput("Parse error: " & e.message);
    }
}
```

## Specification

This implementation follows the [TOON Specification v1.4](https://github.com/toon-format/spec/blob/main/SPEC.md).

## License

MIT License - Free to use, modify, and distribute.

## Related Resources

- [TOON Specification](https://github.com/toon-format/spec)
- [TOON JavaScript Implementation](https://github.com/toon-format/toon)
- [Format Tokenization Playground](https://www.curiouslychase.com/playground/format-tokenization-exploration)

## Contributing

Issues and improvements welcome! This is an independent ColdFusion implementation of the TOON format.

---

**Note:** TOON is designed for LLM input where human readability and token efficiency matter. It's not a drop-in replacement for JSON in APIs or storage, but rather a specialized format for contexts where token count impacts cost or performance.
