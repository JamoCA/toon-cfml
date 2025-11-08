<!---
Test for Regex-Based Type Detection Fix
Verifies that numbers are properly distinguished from booleans
--->
<cfscript>
toon = new Toon();

writeOutput("<h1>Regex-Based Type Detection Test</h1>");
writeOutput("<p>Testing that ColdFusion's permissive isBoolean() doesn't cause false boolean detection.</p>");

function testValue(label, value, expectedType) {
    writeOutput("<hr><h3>" & label & "</h3>");

    try {
        // Create a struct with the value
        data = {test: value};

        writeOutput("<table border='1' cellpadding='5'>");
        writeOutput("<tr><th>Step</th><th>Value</th><th>Type</th></tr>");

        // Original
        originalJSON = serializeJSON(data);
		originalType = getMetadata(value).getName() == "java.lang.String" ? "string" : isBoolean(value) && !isNumeric(value) ? "boolean" : "number";
        writeOutput("<tr><td>Original</td><td><code>" & encodeforhtml(toString(value)) & "</code></td><td>" & originalType & "</td></tr>");

        // Encode
        encoded = toon.encode(data);
        writeOutput("<tr><td>TOON Encoded</td><td colspan='2'><pre>" & encodeforhtml(encoded) & "</pre></td></tr>");

        // Decode
        decoded = toon.decode(encoded);
        decodedValue = decoded.test;
		decodedType = getMetadata(decodedValue).getName() == "java.lang.String" ? "string" : isBoolean(decodedValue) && !isNumeric(decodedValue) ? "boolean" : "number";
        writeOutput("<tr><td>Decoded</td><td><code>" & encodeforhtml(toString(decodedValue)) & "</code></td><td>" & decodedType & "</td></tr>");

        // Re-encode
        reEncoded = toon.encode(decoded);
        writeOutput("<tr><td>Re-encoded</td><td colspan='2'><pre>" & encodeforhtml(reEncoded) & "</pre></td></tr>");

        writeOutput("</table>");

        // Check if types match
        typeMatch = (decodedType == expectedType);
        valueMatch = (toString(value) == toString(decodedValue));
        toonMatch = (encoded == reEncoded);

        writeOutput("<p><strong>Type Match:</strong> " & (typeMatch ? "✅" : "❌") & " (expected: " & expectedType & ", got: " & decodedType & ")</p>");
        writeOutput("<p><strong>Value Match:</strong> " & (valueMatch ? "✅" : "❌") & "</p>");
        writeOutput("<p><strong>TOON Round-trip:</strong> " & (toonMatch ? "✅" : "❌") & "</p>");

        if (typeMatch && valueMatch && toonMatch) {
            writeOutput("<p style='color: green; font-weight: bold;'>✅ PASSED</p>");
            return true;
        } else {
            writeOutput("<p style='color: red; font-weight: bold;'>❌ FAILED</p>");
            return false;
        }

    } catch (any e) {
        writeOutput("<p style='color: red;'>ERROR: " & e.message & "</p>");
        return false;
    }
}

// Track results
passed = 0;
total = 0;

// Test numbers that ColdFusion might confuse with booleans
writeOutput("<h2>Numbers (should NOT become booleans)</h2>");
total++; if (testValue("Integer 0", 0, "number")) passed++;
total++; if (testValue("Integer 1", 1, "number")) passed++;
total++; if (testValue("Integer 2", 2, "number")) passed++;
total++; if (testValue("Integer -1", -1, "number")) passed++;
total++; if (testValue("Integer 100", 100, "number")) passed++;

// Test actual booleans
writeOutput("<h2>Booleans (should stay as booleans)</h2>");
total++; if (testValue("Boolean true", true, "boolean")) passed++;
total++; if (testValue("Boolean false", false, "boolean")) passed++;

// Test numeric strings
writeOutput("<h2>Numeric Strings (should stay as strings)</h2>");
total++; if (testValue("String '0'", tostring("0"), "string")) passed++;
total++; if (testValue("String '1'", tostring("1"), "string")) passed++;
total++; if (testValue("String '1.0'", tostring("1.0"), "string")) passed++;
total++; if (testValue("String '2.5.1'", tostring("2.5.1"), "string")) passed++;
total++; if (testValue("String '00123'", tostring("00123"), "string")) passed++;

// Test strings that CF treats as boolean
writeOutput("<h2>Boolean-like Strings (should stay as strings)</h2>");
total++; if (testValue("String 'yes'", tostring("yes"), "string")) passed++;
total++; if (testValue("String 'no'", tostring("no"), "string")) passed++;
total++; if (testValue("String 'YES'", tostring("YES"), "string")) passed++;
total++; if (testValue("String 'NO'", tostring("NO"), "string")) passed++;
total++; if (testValue("String 'true'", tostring("true"), "string")) passed++;
total++; if (testValue("String 'false'", tostring("false"), "string")) passed++;

// Test decimals
writeOutput("<h2>Decimals (should stay as numbers)</h2>");
total++; if (testValue("Decimal 3.14", 3.14, "number")) passed++;
total++; if (testValue("Decimal 0.5", 0.5, "number")) passed++;
total++; if (testValue("Decimal -2.7", -2.7, "number")) passed++;

// Summary
writeOutput("<hr><h2>Summary</h2>");
writeOutput("<p style='font-size: 20px;'><strong>" & passed & " of " & total & " tests passed</strong></p>");

if (passed == total) {
    writeOutput("<h1 style='color: green; font-size: 48px;'>🎉 ALL TESTS PASSED! 🎉</h1>");
    writeOutput("<p>The regex-based type detection is working correctly!</p>");
} else {
    writeOutput("<h1 style='color: red;'>❌ SOME TESTS FAILED</h1>");
    writeOutput("<p>" & (total - passed) & " test(s) need attention.</p>");
}
</cfscript>
