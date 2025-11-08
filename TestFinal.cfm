<!---
Final Comprehensive Validation Test
Tests all fixes including type handling, arrays, nesting, etc.
--->
<cfscript>
toon = new Toon();

writeOutput("<h1>Final Comprehensive Validation Test</h1>");
writeOutput("<p>This test validates ALL fixes for perfect round-trip encoding/decoding.</p>");

// The full complex test case from Example 12
complexData = [
	config: [
        endpoints: ["api1.com", "api2.com"],
        retries: 3,
        timeout: 30
	],
    metadata: [
        created: "2025-01-15T10:30:00Z",
        version: "1.0"
	],
    records: [
        [active: true, id: 1, tags: ["a", "b", "c"], value: 100],
        [active: false, id: 2, tags: ["x", "y"], value: 200]
    ]
];

//cf_dump(var=complexData);

try {
    writeOutput("<h2>Original Data</h2>");
    originalJSON = serializeJSON(complexData);
    writeOutput("<pre>" & encodeforhtml(originalJSON) & "</pre>");

    writeOutput("<h2>Step 1: Encode</h2>");
    encoded = toon.encode(complexData);
    writeOutput("<pre>" & encodeforhtml(encoded) & "</pre>");

    writeOutput("<h2>Step 2: Decode</h2>");
    decoded = toon.decode(encoded);
    decodedJSON = serializeJSON(decoded);
    writeOutput("<pre>" & encodeforhtml(decodedJSON) & "</pre>");

    writeOutput("<h2>Step 3: Re-encode</h2>");
    reEncoded = toon.encode(decoded);
    writeOutput("<pre>" & encodeforhtml(reEncoded) & "</pre>");

    writeOutput("<hr>");

    // Validation checks
    toonMatch = (encoded == reEncoded);
    jsonMatch = (originalJSON == decodedJSON);

    writeOutput("<h2>Results</h2>");
    writeOutput("<table border='1' cellpadding='10' style='border-collapse: collapse;'>");
    writeOutput("<tr><th>Check</th><th>Status</th></tr>");
    writeOutput("<tr><td>TOON Round-trip (encode → decode → encode)</td><td style='font-size: 24px;'>" & (toonMatch ? "✅" : "❌") & "</td></tr>");
    writeOutput("<tr><td>JSON Round-trip (original → decoded)</td><td style='font-size: 24px;'>" & (jsonMatch ? "✅" : "❌") & "</td></tr>");
    writeOutput("</table>");

    if (!toonMatch) {
        writeOutput("<h3 style='color: red;'>TOON Mismatch Details:</h3>");
        writeOutput("<table border='1' cellpadding='5' style='border-collapse: collapse; font-family: monospace;'>");
        writeOutput("<tr><th>Line</th><th>First</th><th>Re-encoded</th></tr>");

        lines1 = listToArray(encoded, chr(10));
        lines2 = listToArray(reEncoded, chr(10));
        maxLines = max(arrayLen(lines1), arrayLen(lines2));

        for (i = 1; i <= maxLines; i++) {
            line1 = i <= arrayLen(lines1) ? lines1[i] : "";
            line2 = i <= arrayLen(lines2) ? lines2[i] : "";
            style = line1 != line2 ? " style='background-color: ##ffcccc;'" : "";
            writeOutput("<tr" & style & ">");
            writeOutput("<td>" & i & "</td>");
            writeOutput("<td>" & encodeforhtml(line1) & "</td>");
            writeOutput("<td>" & encodeforhtml(line2) & "</td>");
            writeOutput("</tr>");
        }
        writeOutput("</table>");
    }

    if (!jsonMatch) {
        writeOutput("<h3 style='color: red;'>JSON Mismatch Details:</h3>");
        writeOutput("<p><strong>Original:</strong> " & encodeforhtml(originalJSON) & "</p>");
        writeOutput("<p><strong>Decoded:</strong> " & encodeforhtml(decodedJSON) & "</p>");
    }

    // Detailed field type checks
    writeOutput("<h2>Detailed Field Type Validation</h2>");
    writeOutput("<table border='1' cellpadding='5' style='border-collapse: collapse;'>");
    writeOutput("<tr><th>Field</th><th>Expected</th><th>Actual</th><th>Match</th></tr>");

    function checkField(path, expected, actual) {
        match = (expected === actual);
        expectedType = isBoolean(expected) && !isNumeric(expected) ? "boolean" : (isNumeric(expected) ? "number" : "string");
        actualType = isBoolean(actual) && !isNumeric(actual) ? "boolean" : (isNumeric(actual) ? "number" : "string");

        writeOutput("<tr" & (match ? "" : " style='background-color: ##ffeeee;'") & ">");
        writeOutput("<td>" & path & "</td>");
        writeOutput("<td>" & expectedType & ": " & expected & "</td>");
        writeOutput("<td>" & actualType & ": " & actual & "</td>");
        writeOutput("<td>" & (match ? "✅" : "❌") & "</td>");
        writeOutput("</tr>");

        return match;
    }

    allMatch = true;

    // Check metadata
    allMatch = checkField("metadata.version", complexData.metadata.version, decoded.metadata.version) && allMatch;
    allMatch = checkField("metadata.created", complexData.metadata.created, decoded.metadata.created) && allMatch;

    // Check config
    allMatch = checkField("config.timeout", complexData.config.timeout, decoded.config.timeout) && allMatch;
    allMatch = checkField("config.retries", complexData.config.retries, decoded.config.retries) && allMatch;

    // Check first record
    allMatch = checkField("records[1].id", complexData.records[1].id, decoded.records[1].id) && allMatch;
    allMatch = checkField("records[1].value", complexData.records[1].value, decoded.records[1].value) && allMatch;
    allMatch = checkField("records[1].active", complexData.records[1].active, decoded.records[1].active) && allMatch;

    // Check second record
    allMatch = checkField("records[2].id", complexData.records[2].id, decoded.records[2].id) && allMatch;
    allMatch = checkField("records[2].value", complexData.records[2].value, decoded.records[2].value) && allMatch;
    allMatch = checkField("records[2].active", complexData.records[2].active, decoded.records[2].active) && allMatch;

    writeOutput("</table>");

    // Final result
    writeOutput("<hr>");
    if (toonMatch && jsonMatch && allMatch) {
        writeOutput("<h1 style='color: green; font-size: 48px;'>🎉 ALL TESTS PASSED! 🎉</h1>");
        writeOutput("<p style='font-size: 20px;'>Perfect round-trip encoding/decoding with complete type fidelity!</p>");
    } else {
        writeOutput("<h1 style='color: red;'>❌ TESTS FAILED</h1>");
        writeOutput("<p>See details above for specific issues.</p>");
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
