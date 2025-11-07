<!---
Detailed Debug Test for Round-Trip Issues
--->
<cfscript>
toon = new Toon();

writeOutput("<h1>Detailed Debug Test</h1>");

// Test each problematic field individually
writeOutput("<h2>Test 1: Simple Numbers</h2>");
test1 = [retries: 3, timeout: 30];
enc1 = toon.encode(test1);
dec1 = toon.decode(enc1);
writeOutput("<pre>Original: " & serializeJSON(test1) & "</pre>");
writeOutput("<pre>Encoded: " & htmlEditFormat(enc1) & "</pre>");
writeOutput("<pre>Decoded: " & serializeJSON(dec1) & "</pre>");
writeOutput("<p>Match: " & (serializeJSON(test1) == serializeJSON(dec1) ? "✅" : "❌") & "</p>");

writeOutput("<hr><h2>Test 2: String Version Number</h2>");
test2 = {version: "1.0"};
enc2 = toon.encode(test2);
dec2 = toon.decode(enc2);
writeOutput("<pre>Original: " & serializeJSON(test2) & "</pre>");
writeOutput("<pre>Encoded: " & htmlEditFormat(enc2) & "</pre>");
writeOutput("<pre>Decoded: " & serializeJSON(dec2) & "</pre>");
writeOutput("<p>Match: " & (serializeJSON(test2) == serializeJSON(dec2) ? "✅" : "❌") & "</p>");

writeOutput("<hr><h2>Test 3: Inline Primitive Array</h2>");
test3 = {endpoints: ["api1.com", "api2.com"]};
enc3 = toon.encode(test3);
dec3 = toon.decode(enc3);
writeOutput("<pre>Original: " & serializeJSON(test3) & "</pre>");
writeOutput("<pre>Encoded: " & htmlEditFormat(enc3) & "</pre>");
writeOutput("<pre>Decoded: " & serializeJSON(dec3) & "</pre>");
writeOutput("<p>Match: " & (serializeJSON(test3) == serializeJSON(dec3) ? "✅" : "❌") & "</p>");
writeOutput("<p>Decoded type: " & (isArray(dec3.endpoints) ? "Array ✅" : "NOT Array ❌") & "</p>");

writeOutput("<hr><h2>Test 4: Date String</h2>");
test4 = {created: "2025-01-15T10:30:00Z"};
enc4 = toon.encode(test4);
dec4 = toon.decode(enc4);
writeOutput("<pre>Original: " & serializeJSON(test4) & "</pre>");
writeOutput("<pre>Encoded: " & htmlEditFormat(enc4) & "</pre>");
writeOutput("<pre>Decoded: " & serializeJSON(dec4) & "</pre>");
writeOutput("<p>Match: " & (serializeJSON(test4) == serializeJSON(dec4) ? "✅" : "❌") & "</p>");

writeOutput("<hr><h2>Test 5: Array of Structs with Inline Arrays</h2>");
test5 = [
    records: [
        [id: 1, tags: ["a", "b"], value: 100],
        [id: 2, tags: ["x", "y"], value: 200]
    ]
];
enc5 = toon.encode(test5);
dec5 = toon.decode(enc5);
writeOutput("<pre>Original: " & serializeJSON(test5) & "</pre>");
writeOutput("<pre>Encoded:</pre><pre>" & htmlEditFormat(enc5) & "</pre>");
writeOutput("<pre>Decoded: " & serializeJSON(dec5) & "</pre>");
writeOutput("<p>Match: " & (serializeJSON(test5) == serializeJSON(dec5) ? "✅" : "❌") & "</p>");

// Check specific fields
if (structKeyExists(dec5, "records") && isArray(dec5.records) && arrayLen(dec5.records) > 0) {
    writeOutput("<h3>Field Type Checks:</h3>");
    writeOutput("<ul>");
    writeOutput("<li>records[1].id type: " & (isNumeric(dec5.records[1].id) && dec5.records[1].id == 1 ? "Number ✅" : "NOT Number ❌ (value: " & dec5.records[1].id & ")") & "</li>");
    writeOutput("<li>records[1].value type: " & (isNumeric(dec5.records[1].value) && dec5.records[1].value == 100 ? "Number ✅" : "NOT Number ❌ (value: " & dec5.records[1].value & ")") & "</li>");
    writeOutput("<li>records[1].tags type: " & (isArray(dec5.records[1].tags) ? "Array ✅" : "NOT Array ❌") & "</li>");
    writeOutput("</ul>");
}

writeOutput("<hr><h2>Test 6: Full Complex Structure</h2>");
complexData = [
    metadata: [
        created: "2025-01-15T10:30:00Z",
        version: "1.0"
	],
    records: [
        {active: true, id: 1, tags: ["a", "b", "c"], value: 100},
        {active: false, id: 2, tags: ["x", "y"], value: 200}
    ],
    config: [
        endpoints: ["api1.com", "api2.com"],
        retries: 3,
        timeout: 30
	]
];

try {
    encoded = toon.encode(complexData);
    writeOutput("<h3>Encoded:</h3>");
    writeOutput("<pre>" & htmlEditFormat(encoded) & "</pre>");

    decoded = toon.decode(encoded);
    writeOutput("<h3>Decoded:</h3>");
    writeOutput("<pre>" & serializeJSON(decoded) & "</pre>");

    reEncoded = toon.encode(decoded);
    writeOutput("<h3>Re-encoded:</h3>");
    writeOutput("<pre>" & htmlEditFormat(reEncoded) & "</pre>");

    if (encoded == reEncoded) {
        writeOutput("<h2 style='color: green;'>✅ PASS: Round-trip successful!</h2>");
    } else {
        writeOutput("<h2 style='color: red;'>❌ FAIL: Encodings don't match</h2>");
        writeOutput("<h3>Line-by-line comparison:</h3>");
        writeOutput("<table border='1' cellpadding='5' style='border-collapse: collapse; font-family: monospace;'>");
        writeOutput("<tr><th>Line</th><th>First Encoding</th><th>Re-encoding</th></tr>");

        lines1 = listToArray(encoded, chr(10));
        lines2 = listToArray(reEncoded, chr(10));
        maxLines = max(arrayLen(lines1), arrayLen(lines2));

        for (i = 1; i <= maxLines; i++) {
            line1 = i <= arrayLen(lines1) ? lines1[i] : "";
            line2 = i <= arrayLen(lines2) ? lines2[i] : "";
            style = line1 != line2 ? " style='background-color: ##ffeeee;'" : "";
            writeOutput("<tr" & style & ">");
            writeOutput("<td>" & i & "</td>");
            writeOutput("<td>" & htmlEditFormat(line1) & "</td>");
            writeOutput("<td>" & htmlEditFormat(line2) & "</td>");
            writeOutput("</tr>");
        }
        writeOutput("</table>");
    }

} catch (any e) {
    writeOutput("<h2 style='color: red;'>❌ Error: " & e.message & "</h2>");
    writeOutput("<p>" & e.detail & "</p>");
    if (structKeyExists(e, "tagContext") && arrayLen(e.tagContext) > 0) {
        writeOutput("<h3>Stack Trace:</h3><pre>");
        for (ctx in e.tagContext) {
            writeOutput(ctx.template & " (line " & ctx.line & ")" & chr(10));
        }
        writeOutput("</pre>");
    }
}
</cfscript>
