# TOON ColdFusion - Quick Reference

## Installation
```coldfusion
toon = new Toon();
```

## Basic Usage

### Encode (CF → TOON)
```coldfusion
data = {users: [{id:1, name:"Alice"}, {id:2, name:"Bob"}]};
toonString = toon.encode(data);
```

### Decode (TOON → CF)
```coldfusion
toonString = "users[2]{id,name}:\n1,Alice\n2,Bob";
data = toon.decode(toonString);
```

## Common Options

### Tab Delimiter (Best Token Efficiency)
```coldfusion
result = toon.encode(data, {delimiter: chr(9)});
```

### Pipe Delimiter
```coldfusion
result = toon.encode(data, {delimiter: "|"});
```

### Length Marker
```coldfusion
result = toon.encode(data, {lengthMarker: "#"});
// Output: items[#5]{...}:
```

### Custom Indentation
```coldfusion
result = toon.encode(data, {indent: 4});
```

### Lenient Decoding
```coldfusion
data = toon.decode(toonString, {strict: false});
```

## Format Cheat Sheet

| Input | TOON Output |
|-------|-------------|
| `{id: 1, name: "Ada"}` | `id: 1`<br>`name: Ada` |
| `{user: {id: 1}}` | `user:`<br>&nbsp;&nbsp;`id: 1` |
| `{tags: ["a","b","c"]}` | `tags[3]: a,b,c` |
| `{items: [{id:1}, {id:2}]}` | `items[2]{id}:`<br>`1`<br>`2` |
| `{mixed: [1, "x", {a:1}]}` | `mixed[3]:`<br>`- 1`<br>`- x`<br>`- a: 1` |
| `{empty: []}` | `empty[0]:` |
| `{empty: {}}` | `empty:` |

## String Quoting

| String Value | Encoded As | Reason |
|--------------|------------|--------|
| `hello world` | `hello world` | No quotes needed |
| `hello, world` | `"hello, world"` | Contains delimiter |
| `key: value` | `"key: value"` | Contains colon |
| `  padded  ` | `"  padded  "` | Leading/trailing spaces |
| `123` | `"123"` | Looks like number |
| `true` | `"true"` | Looks like boolean |
| `Hello 👋` | `Hello 👋` | Unicode safe |

## LLM Prompt Template

```markdown
Data is in TOON format (2-space indent, arrays show length and fields):

```toon
<cfoutput>#toon.encode(yourData)#</cfoutput>
```

Task: [Your instructions here]
```

## Best Practices

### ✅ DO Use TOON For:
- Uniform arrays of objects (tabular data)
- LLM prompts with structured data
- Large datasets with consistent structure
- Token-sensitive API calls

### ❌ DON'T Use TOON For:
- Non-uniform data structures
- Deeply nested hierarchies
- Standard REST APIs (use JSON)
- File storage (use JSON/database)

## Size Comparison Example

```coldfusion
// 50 employee records
employees = [];
for (i = 1; i <= 50; i++) {
    arrayAppend(employees, {
        id: i,
        name: "Employee " & i,
        department: "Dept " & (i mod 5),
        salary: 50000 + (i * 1000)
    });
}

json = serializeJSON({employees: employees});
toon = toon.encode({employees: employees});

writeOutput("JSON: " & len(json) & " chars<br>");
writeOutput("TOON: " & len(toon) & " chars<br>");
writeOutput("Savings: " & round((1 - len(toon)/len(json)) * 100) & "%");

// Typical result: 40-60% size reduction
```

## Delimiter Comparison

Same data, different delimiters:

```coldfusion
// Comma (default)
items[3]{sku,qty,price}:
A1,2,9.99
B2,1,14.5

// Tab (often best for tokens)
items[3 ]{sku qty price}:
A1	2	9.99
B2	1	14.5

// Pipe (good readability)
items[3|]{sku|qty|price}:
A1|2|9.99
B2|1|14.5
```

## Round-Trip Test

```coldfusion
// Always test round-trip for critical data
original = {complex: "data", structure: [1,2,3]};
encoded = toon.encode(original);
decoded = toon.decode(encoded);
reEncoded = toon.encode(decoded);

if (encoded == reEncoded) {
    writeOutput("✅ Perfect round-trip");
} else {
    writeOutput("❌ Data loss detected");
}
```

## Error Handling

```coldfusion
try {
    data = toon.decode(userInput);
} catch (TOON.ParseError e) {
    // Handle parse errors
    writeOutput("Invalid TOON format: " & e.message);
} catch (any e) {
    // Handle other errors
    writeOutput("Error: " & e.message);
}
```

## Common Patterns

### Export to LLM
```coldfusion
// Query database
qUsers = queryExecute("SELECT id, name, role FROM users");

// Convert query to array of structs
users = [];
for (row in qUsers) {
    arrayAppend(users, {
        id: row.id,
        name: row.name,
        role: row.role
    });
}

// Encode for LLM
toonData = toon.encode({users: users}, {delimiter: chr(9)});

// Send to LLM API
llmPrompt = "Analyze this user data:\n\n```toon\n#toonData#\n```";
```

### Parse LLM Response
```coldfusion
// If LLM returns TOON format
llmResponse = "filtered[2]{id,name}:\n5,Alice\n12,Charlie";

// Decode back to CF
result = toon.decode(llmResponse);

// Use the data
for (user in result.filtered) {
    writeOutput("User ##" & user.id & ": " & user.name & "<br>");
}
```

### API Response Formatter
```coldfusion
function formatResponse(data, format = "json") {
    if (format == "toon") {
        return toon.encode(data);
    } else {
        return serializeJSON(data);
    }
}

// Usage
response = formatResponse(userData, url.format);
```

## Performance Tips

1. **Use tab delimiter** for maximum token efficiency
2. **Enable length markers** for LLM validation
3. **Structure data uniformly** (same fields per row)
4. **Minimize nesting** - flatten where possible
5. **Test token counts** with your specific LLM tokenizer

## Token Estimation

Rough token count estimator (GPT tokenizer):
- ~4 characters = 1 token
- TOON typically saves 30-60% vs JSON
- Best savings on uniform tabular data

```coldfusion
jsonChars = len(serializeJSON(data));
toonChars = len(toon.encode(data));

estimatedJsonTokens = round(jsonChars / 4);
estimatedToonTokens = round(toonChars / 4);
savings = estimatedJsonTokens - estimatedToonTokens;

writeOutput("Estimated token savings: ~" & savings & " tokens");
```

---

**Need more examples?** See `ToonExamples.cfm`

**Full documentation?** See `README.md`

**TOON Spec:** https://github.com/toon-format/spec
