<cfscript>
    toon = new Toon();

    writeOutput("<h1>TOON JSON Input Tests</h1>");

    passed = 0;
    failed = 0;
    total = 0;

    // ============================================================
    // Test 1: Simple Object from JSON string
    // ============================================================
    writeOutput("<hr><h2>Test 1: Simple Object from JSON String</h2>");
    total++;
    try {
        jsonInput = '{"name": "Alice", "age": 30}';

        writeOutput("<h3>Input JSON:</h3>");
        writeOutput("<pre>" & encodeforhtml(jsonInput) & "</pre>");

        encoded = toon.encode(jsonInput);

        writeOutput("<h3>TOON Output:</h3>");
        writeOutput("<pre>" & encodeforhtml(encoded) & "</pre>");

        decoded = toon.decode(encoded);

        writeOutput("<h3>Decoded Back:</h3>");
        writeOutput("<pre>" & serializeJSON(decoded) & "</pre>");

        // Verify round-trip by re-encoding and comparing decoded values
        reEncoded = toon.encode(decoded);
        reDecoded = toon.decode(reEncoded);

        // Compare data, not encoded strings (to handle key ordering differences)
        if (serializeJSON(decoded) == serializeJSON(reDecoded)) {
            writeOutput("<p style='color:green'>✓ PASS - Round-trip successful</p>");
            passed++;
        } else {
            writeOutput("<p style='color:red'>✗ FAIL - Round-trip data mismatch</p>");
            writeOutput("<h4>First decode:</h4><pre>" & serializeJSON(decoded) & "</pre>");
            writeOutput("<h4>Re-decoded:</h4><pre>" & serializeJSON(reDecoded) & "</pre>");
            failed++;
        }
    } catch (any e) {
        writeOutput("<p style='color:red'>✗ FAIL - Exception: " & e.message & "</p>");
        if (structKeyExists(e, "detail")) {
            writeOutput("<pre>" & encodeforhtml(e.detail) & "</pre>");
        }
        failed++;
    }

    // ============================================================
    // Test 2: Array from JSON string
    // ============================================================
    writeOutput("<hr><h2>Test 2: Array from JSON String</h2>");
    total++;
    try {
        jsonInput = '[{"id": 1, "name": "Alice"}, {"id": 2, "name": "Bob"}]';

        writeOutput("<h3>Input JSON:</h3>");
        writeOutput("<pre>" & encodeforhtml(jsonInput) & "</pre>");

        encoded = toon.encode(jsonInput);

        writeOutput("<h3>TOON Output:</h3>");
        writeOutput("<pre>" & encodeforhtml(encoded) & "</pre>");

        decoded = toon.decode(encoded);

        writeOutput("<h3>Decoded Back:</h3>");
        writeOutput("<pre>" & serializeJSON(decoded) & "</pre>");

        // Verify round-trip by re-encoding and comparing decoded values
        reEncoded = toon.encode(decoded);
        reDecoded = toon.decode(reEncoded);

        // Compare data, not encoded strings
        if (serializeJSON(decoded) == serializeJSON(reDecoded)) {
            writeOutput("<p style='color:green'>✓ PASS - Round-trip successful</p>");
            passed++;
        } else {
            writeOutput("<p style='color:red'>✗ FAIL - Round-trip data mismatch</p>");
            writeOutput("<h4>First decode:</h4><pre>" & serializeJSON(decoded) & "</pre>");
            writeOutput("<h4>Re-decoded:</h4><pre>" & serializeJSON(reDecoded) & "</pre>");
            failed++;
        }
    } catch (any e) {
        writeOutput("<p style='color:red'>✗ FAIL - Exception: " & e.message & "</p>");
        if (structKeyExists(e, "detail")) {
            writeOutput("<pre>" & encodeforhtml(e.detail) & "</pre>");
        }
        failed++;
    }

    // ============================================================
    // Test 3: Nested Structure from JSON
    // ============================================================
    writeOutput("<hr><h2>Test 3: Nested Structure from JSON</h2>");
    total++;
    try {
        jsonInput = '{"user": {"id": 123, "name": "Ada", "tags": ["reading", "gaming"]}}';

        writeOutput("<h3>Input JSON:</h3>");
        writeOutput("<pre>" & encodeforhtml(jsonInput) & "</pre>");

        encoded = toon.encode(jsonInput);

        writeOutput("<h3>TOON Output:</h3>");
        writeOutput("<pre>" & encodeforhtml(encoded) & "</pre>");

        decoded = toon.decode(encoded);

        writeOutput("<h3>Decoded Back:</h3>");
        writeOutput("<pre>" & serializeJSON(decoded) & "</pre>");

        // Verify round-trip by re-encoding and comparing decoded values
        reEncoded = toon.encode(decoded);
        writeOutput("<h3>Re-encoded:</h3>");
        writeOutput("<pre>" & encodeforhtml(reEncoded) & "</pre>");

        reDecoded = toon.decode(reEncoded);

        // Compare data, not encoded strings
        if (serializeJSON(decoded) == serializeJSON(reDecoded)) {
            writeOutput("<p style='color:green'>✓ PASS - Round-trip successful</p>");
            passed++;
        } else {
            writeOutput("<p style='color:red'>✗ FAIL - Round-trip data mismatch</p>");
            writeOutput("<h4>First decode:</h4><pre>" & serializeJSON(decoded) & "</pre>");
            writeOutput("<h4>Re-decoded:</h4><pre>" & serializeJSON(reDecoded) & "</pre>");
            failed++;
        }
    } catch (any e) {
        writeOutput("<p style='color:red'>✗ FAIL - Exception: " & e.message & "</p>");
        if (structKeyExists(e, "detail")) {
            writeOutput("<pre>" & encodeforhtml(e.detail) & "</pre>");
        }
        failed++;
    }

    // ============================================================
    // Summary
    // ============================================================
    writeOutput("<hr><h2>Test Summary</h2>");
    writeOutput("<p><strong>Total:</strong> " & total & "</p>");
    writeOutput("<p style='color:green'><strong>Passed:</strong> " & passed & "</p>");
    writeOutput("<p style='color:red'><strong>Failed:</strong> " & failed & "</p>");
</cfscript>
