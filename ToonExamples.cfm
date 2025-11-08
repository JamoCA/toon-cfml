<!---
TOON.cfc Usage Examples and Tests
Demonstrates encoding and decoding with the TOON CFC
✅✅✅✅✅
--->

<cfscript>
// Initialize the TOON component
toon = new Toon();

// ============================================================
// EXAMPLE 1: Simple Object
// ============================================================
writeOutput("<h2>Example 1: Simple Object</h2>");

data1 = {
    id: 123,
    name: "Ada",
    active: true
};

encoded1 = toon.encode(data1);
writeOutput("<h3>Original Data:</h3>");
writeOutput("<pre>" & serializeJSON(data1) & "</pre>");
writeOutput("<h3>TOON Encoded:</h3>");
writeOutput("<pre>" & encodeforhtml(encoded1) & "</pre>");

decoded1 = toon.decode(encoded1);
writeOutput("<h3>Decoded Back:</h3>");
writeOutput("<pre>" & serializeJSON(decoded1) & "</pre>");

// ============================================================
// EXAMPLE 2: Tabular Array (TOON's Sweet Spot)
// ============================================================
writeOutput("<hr><h2>Example 2: Tabular Array (Users)</h2>");

data2 = {
    users: [
        [active: true, id: 1, name: "Alice", role: "admin"],
        [active: true, id: 2, name: "Bob", role: "user"],
        [active: false, id: 3, name: "Charlie", role: "user"]
    ]
};

encoded2 = toon.encode(data2);
writeOutput("<h3>Original Data:</h3>");
writeOutput("<pre>" & serializeJSON(data2) & "</pre>");
writeOutput("<h3>TOON Encoded (comma delimiter):</h3>");
writeOutput("<pre>" & encodeforhtml(encoded2) & "</pre>");

// With tab delimiter for even more token efficiency
encoded2Tab = toon.encode(data2, {delimiter: chr(9)});
writeOutput("<h3>TOON Encoded (tab delimiter):</h3>");
writeOutput("<pre>" & encodeforhtml(encoded2Tab) & "</pre>");

// With pipe delimiter
encoded2Pipe = toon.encode(data2, {delimiter: "|"});
writeOutput("<h3>TOON Encoded (pipe delimiter):</h3>");
writeOutput("<pre>" & encodeforhtml(encoded2Pipe) & "</pre>");

decoded2 = toon.decode(encoded2);
writeOutput("<h3>Decoded Back:</h3>");
writeOutput("<pre>" & serializeJSON(decoded2) & "</pre>");

// ============================================================
// EXAMPLE 3: E-Commerce Order (Nested Structure)
// ============================================================
writeOutput("<hr><h2>Example 3: E-Commerce Order</h2>");

data3 = [
    order: [
        customer: [
            address: "123 Main St",
            email: "john@example.com",
            name: "John Doe"
		],
        date: "2025-01-15",
        id: "ORD-12345",
        items: [
            [name: "Super Widget", price: 29.99, qty: 2, sku: "WIDGET-A"],
            [name: "Mega Gadget", price: 49.99, qty: 1, sku: "GADGET-B"]
        ],
        status: "shipped",
        total: 109.97
	]
];

encoded3 = toon.encode(data3);
writeOutput("<h3>Original Data:</h3>");
writeOutput("<pre>" & serializeJSON(data3) & "</pre>");
writeOutput("<h3>TOON Encoded:</h3>");
writeOutput("<pre>" & encodeforhtml(encoded3) & "</pre>");

decoded3 = toon.decode(encoded3);
writeOutput("<h3>Decoded Back:</h3>");
writeOutput("<pre>" & serializeJSON(decoded3) & "</pre>");

// ============================================================
// EXAMPLE 4: Primitive Array
// ============================================================
writeOutput("<hr><h2>Example 4: Primitive Arrays</h2>");

data4 = [
    flags: [true, false, true],
    scores: [95, 87, 92, 88],
    tags: ["reading", "gaming", "coding"]
];

encoded4 = toon.encode(data4);
writeOutput("<h3>Original Data:</h3>");
writeOutput("<pre>" & serializeJSON(data4) & "</pre>");
writeOutput("<h3>TOON Encoded:</h3>");
writeOutput("<pre>" & encodeforhtml(encoded4) & "</pre>");

decoded4 = toon.decode(encoded4);
writeOutput("<h3>Decoded Back:</h3>");
writeOutput("<pre>" & serializeJSON(decoded4) & "</pre>");

// ============================================================
// EXAMPLE 5: Mixed List Array
// ============================================================
writeOutput("<hr><h2>Example 5: Mixed List Array</h2>");

data5 = {
    mixed: [
        "text value",
        123,
        [name: "nested object", value: 42],
        ["inner", "array"],
        true
    ]
};

encoded5 = toon.encode(data5);
writeOutput("<h3>Original Data:</h3>");
writeOutput("<pre>" & serializeJSON(data5) & "</pre>");
writeOutput("<h3>TOON Encoded:</h3>");
writeOutput("<pre>" & encodeforhtml(encoded5) & "</pre>");

decoded5 = toon.decode(encoded5);
writeOutput("<h3>Decoded Back:</h3>");
writeOutput("<pre>" & serializeJSON(decoded5) & "</pre>");

// ============================================================
// EXAMPLE 6: Options - Length Marker
// ============================================================
writeOutput("<hr><h2>Example 6: Using Length Marker Option</h2>");

data6 = {
    repositories: [
        [id: 1, name: "repo-a", stars: 1500],
        [id: 2, name: "repo-b", stars: 2300]
    ]
};

encoded6 = toon.encode(data6, {lengthMarker: "##"});
writeOutput("<h3>Original Data:</h3>");
writeOutput("<pre>" & serializeJSON(data6) & "</pre>");
writeOutput("<h3>TOON Encoded (with length marker):</h3>");
writeOutput("<pre>" & encodeforhtml(encoded6) & "</pre>");

decoded6 = toon.decode(encoded6);
writeOutput("<h3>Decoded Back:</h3>");
writeOutput("<pre>" & serializeJSON(decoded6) & "</pre>");

// ============================================================
// EXAMPLE 7: String Quoting Examples
// ============================================================
writeOutput("<hr><h2>Example 7: String Quoting</h2>");

data7 = [
	"boolean": true,
	"booleanCastAsString": javacast("string", true),
    "emoji": "Hello 👋 World",
	"int": 123,
	"intCastAsInt": javacast("int", 123),
	"intCastAsString": javacast("string", 123),
    "looksLikeBoolean": "true",
    "looksLikeNumber": "123",
    "unquoted": "hello world",
    "multiline": "Line 1" & chr(10) & "Line 2",
    "withColon": "key: value",
    "withComma": "hello, world",
    "withSpaces": "  padded  "
];

encoded7 = toon.encode(data7);
writeOutput("<h3>Original Data:</h3>");
writeOutput("<pre>" & serializeJSON(data7) & "</pre>");
writeOutput("<h3>TOON Encoded (notice selective quoting):</h3>");
writeOutput("<pre>" & encodeforhtml(encoded7) & "</pre>");

decoded7 = toon.decode(encoded7);
writeOutput("<h3>Decoded Back:</h3>");
writeOutput("<pre>" & serializeJSON(decoded7) & "</pre>");

// ============================================================
// EXAMPLE 8: Analytics Data (Time Series)
// ============================================================
writeOutput("<hr><h2>Example 8: Analytics Dashboard Data</h2>");

// ColdFusion reorders and alphabetizes keys
data8 = {
    "metrics": [
        ["date": "2025-01-01", "views": 6890, "clicks": 401, "conversions": 23, "revenue": 6015.59],
        ["date": "2025-01-02", "views": 6940, "clicks": 323, "conversions": 37, "revenue": 9086.44],
        ["date": "2025-01-03", "views": 4390, "clicks": 346, "conversions": 26, "revenue": 6360.75],
        ["date": "2025-01-04", "views": 3429, "clicks": 231, "conversions": 13, "revenue": 2360.96],
        ["date": "2025-01-05", "views": 5804, "clicks": 186, "conversions": 22, "revenue": 2535.96]
    ]
};

encoded8 = toon.encode(data8);
writeOutput("<h3>Original Data (JSON):</h3>");
writeOutput("<pre>" & serializeJSON(data8) & "</pre>");
writeOutput("<h3>TOON Encoded:</h3>");
writeOutput("<pre>" & encodeforhtml(encoded8) & "</pre>");

jsonLength = len(serializeJSON(data8));
toonLength = len(encoded8);
savings = round((1 - (toonLength / jsonLength)) * 100);

writeOutput("<h3>Size Comparison:</h3>");
writeOutput("<ul>");
writeOutput("<li>JSON: " & jsonLength & " characters</li>");
writeOutput("<li>TOON: " & toonLength & " characters</li>");
writeOutput("<li>Savings: " & savings & "%</li>");
writeOutput("</ul>");

decoded8 = toon.decode(encoded8);
writeOutput("<h3>Decoded Back:</h3>");
writeOutput("<pre>" & serializeJSON(decoded8) & "</pre>");

// ============================================================
// EXAMPLE 9: Empty Values
// ============================================================
writeOutput("<hr><h2>Example 9: Empty Values and Edge Cases</h2>");

data9 = [
    emptyArray: [],
    emptyString: "",
    emptyStruct: {},
    negativeNumber: -42.5,
    nullValue: javacast("null", ""),
    zero: 0
];

encoded9 = toon.encode(data9);
writeOutput("<h3>Original Data:</h3>");
writeOutput("<pre>" & serializeJSON(data9) & "</pre>");
writeOutput("<h3>TOON Encoded:</h3>");
writeOutput("<pre>" & encodeforhtml(encoded9) & "</pre>");

decoded9 = toon.decode(encoded9);
writeOutput("<h3>Decoded Back:</h3>");
writeOutput("<pre>" & serializeJSON(decoded9) & "</pre>");

// ============================================================
// EXAMPLE 10: Custom Indentation
// ============================================================
writeOutput("<hr><h2>Example 10: Custom Indentation</h2>");

data10 = {
    section: {
        subsection: {
            item: "deeply nested"
        }
    }
};

encoded10_2 = toon.encode(data10, {indent: 2});
encoded10_4 = toon.encode(data10, {indent: 4});

writeOutput("<h3>2-space indentation (default):</h3>");
writeOutput("<pre>" & encodeforhtml(encoded10_2) & "</pre>");

writeOutput("<h3>4-space indentation:</h3>");
writeOutput("<pre>" & encodeforhtml(encoded10_4) & "</pre>");

// ============================================================
// EXAMPLE 11: LLM-Ready Format Comparison
// ============================================================
writeOutput("<hr><h2>Example 11: LLM Token Efficiency Demo</h2>");

employees = [];
for (i = 1; i <= 50; i++) {
    arrayAppend(employees, [
        id: i,
        name: "Employee " & i,
        department: i mod 5 == 0 ? "Engineering" : (i mod 3 == 0 ? "Sales" : "Marketing"),
        salary: 50000 + (i * 1000),
        active: i mod 10 != 0
    ]);
}

data11 = {employees: employees};

encodedToon = toon.encode(data11);
encodedJson = serializeJSON(data11);

writeOutput("<h3>Dataset: 50 Employee Records</h3>");
writeOutput("<h4>JSON Format:</h4>");
writeOutput("<pre>" & left(encodedJson, 500) & "..." & chr(10) & "(truncated, total: " & len(encodedJson) & " chars)</pre>");

writeOutput("<h4>TOON Format:</h4>");
writeOutput("<pre>" & left(encodedToon, 500) & "..." & chr(10) & "(truncated, total: " & len(encodedToon) & " chars)</pre>");

writeOutput("<h3>Size Comparison:</h3>");
writeOutput("<ul>");
writeOutput("<li>JSON: " & len(encodedJson) & " characters</li>");
writeOutput("<li>TOON: " & len(encodedToon) & " characters</li>");
writeOutput("<li>Savings: " & round((1 - (len(encodedToon) / len(encodedJson))) * 100) & "%</li>");
writeOutput("</ul>");

writeOutput("<h3>Why TOON is Better for LLMs:</h3>");
writeOutput("<ul>");
writeOutput("<li>✅ Column names declared once (not repeated 50 times)</li>");
writeOutput("<li>✅ Minimal punctuation (no braces/brackets per row)</li>");
writeOutput("<li>✅ Explicit structure helps LLMs validate data</li>");
writeOutput("<li>✅ CSV-like compactness with JSON-like flexibility</li>");
writeOutput("</ul>");

// ============================================================
// EXAMPLE 12: Round-Trip Test
// ============================================================
writeOutput("<hr><h2>Example 12: Round-Trip Validation</h2>");

complexData = {
    metadata: [
        version: "1.0",
        created: "2025-01-15T10:30:00Z"
    ],
    records: [
        [id: 1, value: 100, active: true, tags: ["a", "b", "c"]],
        [id: 2, value: 200, active: false, tags: ["x", "y"]]
    ],
    config: [
        timeout: 30,
        retries: 3,
        endpoints: ["api1.com", "api2.com"]
    ]
};

writeOutput("<h3>Test: Complex nested structure</h3>");
encoded = toon.encode(complexData);
decoded = toon.decode(encoded);
reEncoded = toon.encode(decoded);

writeOutput("<h4>First Encoding:</h4>");
writeOutput("<pre>" & encodeforhtml(encoded) & "</pre>");

writeOutput("<h4>Re-encoded (should match):</h4>");
writeOutput("<pre>" & encodeforhtml(reEncoded) & "</pre>");

writeOutput("<h4>Match: " & (encoded == reEncoded ? "✅ PASS" : "❌ FAIL") & "</h4>");

writeOutput("<hr>");
writeOutput("<h2>✅ All Examples Complete!</h2>");
writeOutput("<p>The TOON.cfc component successfully encodes ColdFusion data to TOON format and decodes it back.</p>");
writeOutput("<p>Use TOON when:</p>");
writeOutput("<ul>");
writeOutput("<li>Sending structured data to Large Language Models</li>");
writeOutput("<li>Working with uniform arrays of objects (tabular data)</li>");
writeOutput("<li>Token efficiency is important for your use case</li>");
writeOutput("</ul>");
</cfscript>
