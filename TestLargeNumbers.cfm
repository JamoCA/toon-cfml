<cfscript>
    toon = new Toon();

    writeOutput("<h1>TOON Large Number Tests</h1>");

    passed = 0;
    failed = 0;
    total = 0;

    // ============================================================
    // Test 1: Large Integer (beyond int32)
    // ============================================================
    writeOutput("<hr><h2>Test 1: Large Integer (beyond int32)</h2>");
    total++;
    try {
        writeOutput("<h3>Test: Integer larger than 2^31</h3>");

        // Create a number that exceeds int32 max (2147483647)
        largeNumber = javacast("long", "9876543210123");
        testData = [:];
        testData["id"] = largeNumber;
        testData["name"] = "Test";

        writeOutput("<h4>Original Data:</h4>");
        writeOutput("<pre>ID: " & largeNumber & " (type: " & largeNumber.getClass().getName() & ")</pre>");
        writeOutput("<pre>" & serializeJSON(testData) & "</pre>");

        encoded = toon.encode(testData);
        writeOutput("<h4>TOON Encoded:</h4>");
        writeOutput("<pre>" & encodeforhtml(encoded) & "</pre>");

        decoded = toon.decode(encoded);
        writeOutput("<h4>Decoded:</h4>");
        writeOutput("<pre>" & serializeJSON(decoded) & "</pre>");
        writeOutput("<pre>Decoded ID type: " & decoded.id.getClass().getName() & "</pre>");

        reEncoded = toon.encode(decoded);
        writeOutput("<h4>Re-encoded:</h4>");
        writeOutput("<pre>" & encodeforhtml(reEncoded) & "</pre>");

        // Compare decoded data, not encoded strings
        reDecoded = toon.decode(reEncoded);
        if (serializeJSON(decoded) == serializeJSON(reDecoded)) {
            writeOutput("<p style='color:green'>✓ PASS</p>");
            passed++;
        } else {
            writeOutput("<p style='color:red'>✗ FAIL - Round-trip data mismatch</p>");
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
    // Test 2: Array of Large Numbers
    // ============================================================
    writeOutput("<hr><h2>Test 2: Array of Large Numbers</h2>");
    total++;
    try {
        writeOutput("<h3>Test: Primitive array with large numbers</h3>");

        testData = [:];
        testData["ids"] = [
            javacast("long", "9876543210123"),
            javacast("long", "9876543210124"),
            javacast("long", "9876543210125")
        ];

        writeOutput("<h4>Original Data:</h4>");
        writeOutput("<pre>" & serializeJSON(testData) & "</pre>");

        encoded = toon.encode(testData);
        writeOutput("<h4>TOON Encoded:</h4>");
        writeOutput("<pre>" & encodeforhtml(encoded) & "</pre>");

        decoded = toon.decode(encoded);
        writeOutput("<h4>Decoded:</h4>");
        writeOutput("<pre>" & serializeJSON(decoded) & "</pre>");

        reEncoded = toon.encode(decoded);
        writeOutput("<h4>Re-encoded:</h4>");
        writeOutput("<pre>" & encodeforhtml(reEncoded) & "</pre>");

        // Compare decoded data
        reDecoded = toon.decode(reEncoded);
        if (serializeJSON(decoded) == serializeJSON(reDecoded)) {
            writeOutput("<p style='color:green'>✓ PASS</p>");
            passed++;
        } else {
            writeOutput("<p style='color:red'>✗ FAIL - Round-trip data mismatch</p>");
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
    // Test 3: Complex Structure with Large Numbers
    // ============================================================
    writeOutput("<hr><h2>Test 3: Complex Structure with Large Numbers</h2>");
    total++;
    try {
        writeOutput("<h3>Test: Nested structures and arrays with large numbers</h3>");

        // Use ordered structs and explicit type casting
        complexData = [:];
        complexData["metadata"] = [:];
        complexData["metadata"]["timestamp"] = javacast("long", "1704067200000");
        complexData["metadata"]["version"] = javacast("int", 2);

        complexData["users"] = [];

        user1 = [:];
        user1["balance"] = javacast("long", "5000000000");
        user1["id"] = javacast("long", "9876543210123");
        user1["name"] = "Alice";
        arrayAppend(complexData["users"], user1);

        user2 = [:];
        user2["balance"] = javacast("int", 1000);
        user2["id"] = javacast("long", "9876543210124");
        user2["name"] = "Bob";
        arrayAppend(complexData["users"], user2);

        writeOutput("<h4>Original Data:</h4>");
        writeOutput("<pre>" & serializeJSON(complexData) & "</pre>");

        encoded = toon.encode(complexData);
        writeOutput("<h4>TOON Encoded:</h4>");
        writeOutput("<pre>" & encodeforhtml(encoded) & "</pre>");

        writeOutput("<h4>Encoded Length: " & len(encoded) & " characters</h4>");
        writeOutput("<h4>Line count: " & listLen(encoded, chr(10)) & " lines</h4>");

        decoded = toon.decode(encoded);
        writeOutput("<h4>Decoded:</h4>");
        writeOutput("<pre>" & serializeJSON(decoded) & "</pre>");

        reEncoded = toon.encode(decoded);
        writeOutput("<h4>Re-encoded:</h4>");
        writeOutput("<pre>" & encodeforhtml(reEncoded) & "</pre>");

        // Compare decoded data
        reDecoded = toon.decode(reEncoded);
        if (serializeJSON(decoded) == serializeJSON(reDecoded)) {
            writeOutput("<p style='color:green'>✓ PASS - Round-trip successful</p>");
            passed++;
        } else {
            writeOutput("<p style='color:red'>✗ FAIL - Round-trip data mismatch</p>");
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
    // Test 4: Mixed Number Types
    // ============================================================
    writeOutput("<hr><h2>Test 4: Mixed Number Types</h2>");
    total++;
    try {
        writeOutput("<h3>Test: int32, int64 (long), and double values</h3>");

        testData = [:];
        testData["decimal"] = javacast("double", 3.14159);
        testData["largeInt"] = javacast("long", "9876543210123");
        testData["negativeInt"] = javacast("int", -100);
        testData["negativeLarge"] = javacast("long", "-9876543210123");
        testData["regularInt"] = javacast("int", 42);

        writeOutput("<h4>Original Data:</h4>");
        writeOutput("<pre>" & serializeJSON(testData) & "</pre>");

        encoded = toon.encode(testData);
        writeOutput("<h4>TOON Encoded:</h4>");
        writeOutput("<pre>" & encodeforhtml(encoded) & "</pre>");

        decoded = toon.decode(encoded);
        writeOutput("<h4>Decoded:</h4>");
        writeOutput("<pre>" & serializeJSON(decoded) & "</pre>");

        reEncoded = toon.encode(decoded);
        writeOutput("<h4>Re-encoded:</h4>");
        writeOutput("<pre>" & encodeforhtml(reEncoded) & "</pre>");

        // Compare decoded data
        reDecoded = toon.decode(reEncoded);
        if (serializeJSON(decoded) == serializeJSON(reDecoded)) {
            writeOutput("<p style='color:green'>✓ PASS</p>");
            passed++;
        } else {
            writeOutput("<p style='color:red'>✗ FAIL - Round-trip data mismatch</p>");
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
