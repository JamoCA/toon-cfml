<!---
Focused test for quoted string preservation and "1.0" string issue
--->
<cfscript>
toon = new Toon();

writeOutput("<h1>Quoted String & Numeric String Preservation Test</h1>");

function detailedTest(label, originalValue, shouldBeQuoted) {
    writeOutput("<hr><h2>" & label & "</h2>");

    try {
        data = {test: originalValue};

        writeOutput("<table border='1' cellpadding='8' style='border-collapse: collapse;'>");
        writeOutput("<tr><th width='150'>Step</th><th>Value</th><th>Type Info</th></tr>");

        // Original
        originalJSON = serializeJSON(data);
        origType = "";
        origClass = "";
        try {
            origMeta = getMetadata(originalValue);
            origClass = isStruct(origMeta) && structKeyExists(origMeta, "name") ? origMeta.name : toString(origMeta);
        } catch (any e) {
            origClass = "unknown";
        }

        if (isBoolean(originalValue) && !isNumeric(originalValue)) {
            origType = "boolean";
        } else if (isNumeric(originalValue)) {
            origType = "number";
        } else {
            origType = "string";
        }
        writeOutput("<tr>");
        writeOutput("<td><strong>Original</strong></td>");
        writeOutput("<td><code>" & encodeforhtml(toString(originalValue)) & "</code></td>");
        writeOutput("<td>Type: " & origType & "<br>Class: <code>" & encodeforhtml(origClass) & "</code><br>JSON: " & encodeforhtml(originalJSON) & "</td>");
        writeOutput("</tr>");

        // Encode
        encoded = toon.encode(data);
        isQuoted = (find("""", encoded) > 0);
        writeOutput("<tr>");
        writeOutput("<td><strong>TOON Encoded</strong></td>");
        writeOutput("<td><pre>" & encodeforhtml(encoded) & "</pre></td>");
        writeOutput("<td>Quoted in TOON: " & (isQuoted ? "YES ✓" : "NO") & "<br>Expected: " & (shouldBeQuoted ? "YES" : "NO") & "</td>");
        writeOutput("</tr>");

        // Decode
        decoded = toon.decode(encoded);
        decodedValue = decoded.test;
        decodedType = "";
        decodedClass = "";
        try {
            decMeta = getMetadata(decodedValue);
            decodedClass = isStruct(decMeta) && structKeyExists(decMeta, "name") ? decMeta.name : toString(decMeta);
        } catch (any e) {
            decodedClass = "unknown";
        }

        if (isBoolean(decodedValue) && !isNumeric(decodedValue)) {
            decodedType = "boolean";
        } else if (isNumeric(decodedValue)) {
            decodedType = "number";
        } else {
            decodedType = "string";
        }
        decodedJSON = serializeJSON(decoded);

        writeOutput("<tr>");
        writeOutput("<td><strong>Decoded</strong></td>");
        writeOutput("<td><code>" & encodeforhtml(toString(decodedValue)) & "</code></td>");
        writeOutput("<td>Type: " & decodedType & "<br>Class: <code>" & encodeforhtml(decodedClass) & "</code><br>JSON: " & encodeforhtml(decodedJSON) & "</td>");
        writeOutput("</tr>");

        // Re-encode
        reEncoded = toon.encode(decoded);
        writeOutput("<tr>");
        writeOutput("<td><strong>Re-encoded</strong></td>");
        writeOutput("<td><pre>" & encodeforhtml(reEncoded) & "</pre></td>");
        writeOutput("<td>&nbsp;</td>");
        writeOutput("</tr>");

        writeOutput("</table>");

        // Validation
        valueMatches = (toString(originalValue) == toString(decodedValue));
        typeMatches = (origType == decodedType);
        classMatches = (origClass == decodedClass);
        toonMatches = (encoded == reEncoded);
        jsonMatches = (originalJSON == decodedJSON);

        writeOutput("<h3>Validation Results:</h3>");
        writeOutput("<ul>");
        writeOutput("<li><strong>Value Match:</strong> " & (valueMatches ? "✅ PASS" : "❌ FAIL") & " ('" & toString(originalValue) & "' == '" & toString(decodedValue) & "')</li>");
        writeOutput("<li><strong>Type Match:</strong> " & (typeMatches ? "✅ PASS" : "❌ FAIL") & " (" & origType & " == " & decodedType & ")</li>");
        writeOutput("<li><strong>Class Match:</strong> " & (classMatches ? "✅ PASS" : "❌ FAIL") & " (" & origClass & " == " & decodedClass & ")</li>");
        writeOutput("<li><strong>TOON Round-trip:</strong> " & (toonMatches ? "✅ PASS" : "❌ FAIL") & "</li>");
        writeOutput("<li><strong>JSON Round-trip:</strong> " & (jsonMatches ? "✅ PASS" : "❌ FAIL") & "</li>");
        writeOutput("</ul>");

        if (valueMatches && typeMatches && toonMatches && jsonMatches) {
            writeOutput("<p style='color: green; font-size: 20px; font-weight: bold;'>✅ ALL CHECKS PASSED</p>");
            return true;
        } else {
            writeOutput("<p style='color: red; font-size: 20px; font-weight: bold;'>❌ FAILED</p>");
            return false;
        }

    } catch (any e) {
        writeOutput("<p style='color: red;'><strong>ERROR:</strong> " & e.message & "</p>");
        writeOutput("<pre>" & e.detail & "</pre>");
        return false;
    }
}

passed = 0;
total = 0;

writeOutput("<h1>Critical Tests</h1>");

// The main issue: string "1.0" - use javacast to ensure it's a string
total++; if (detailedTest("String '1.0' (CRITICAL)", javacast("string", "1.0"), true)) passed++;

// Quoted numeric strings should stay as strings - use javacast
total++; if (detailedTest("String '1'", javacast("string", "1"), true)) passed++;
total++; if (detailedTest("String '123'", javacast("string", "123"), true)) passed++;
total++; if (detailedTest("String '0'", javacast("string", "0"), true)) passed++;

// Quoted boolean-like strings should stay as strings - use javacast
total++; if (detailedTest("String 'true'", javacast("string", "true"), true)) passed++;
total++; if (detailedTest("String 'false'", javacast("string", "false"), true)) passed++;
total++; if (detailedTest("String 'yes'", javacast("string", "yes"), true)) passed++;
total++; if (detailedTest("String 'no'", javacast("string", "no"), true)) passed++;
total++; if (detailedTest("String 'YES'", javacast("string", "YES"), true)) passed++;
total++; if (detailedTest("String 'NO'", javacast("string", "NO"), true)) passed++;

// Actual numbers should NOT be quoted - use javacast to ensure they're numbers
total++; if (detailedTest("Number 1", javacast("int", 1), false)) passed++;
total++; if (detailedTest("Number 123", javacast("int", 123), false)) passed++;
total++; if (detailedTest("Number 3.14", javacast("double", 3.14), false)) passed++;

// Actual booleans should NOT be quoted - use javacast
total++; if (detailedTest("Boolean true", javacast("boolean", true), false)) passed++;
total++; if (detailedTest("Boolean false", javacast("boolean", false), false)) passed++;

// Edge cases - use javacast to ensure they're strings
total++; if (detailedTest("String '2.0.1' (version)", javacast("string", "2.0.1"), true)) passed++;
total++; if (detailedTest("String '00123' (leading zeros)", javacast("string", "00123"), true)) passed++;

writeOutput("<hr><h1>Summary</h1>");
writeOutput("<p style='font-size: 24px;'><strong>" & passed & " of " & total & " tests passed</strong></p>");

if (passed == total) {
    writeOutput("<h1 style='color: green; font-size: 48px;'>🎉 ALL TESTS PASSED! 🎉</h1>");
} else {
    writeOutput("<h1 style='color: red; font-size: 36px;'>❌ " & (total - passed) & " TEST(S) FAILED</h1>");
    writeOutput("<p style='font-size: 18px;'>Please review the failures above.</p>");
}
</cfscript>
