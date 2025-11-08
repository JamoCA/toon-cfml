<!---
Diagnostic test to see what getMetadata returns for different value types
This will help us understand how to properly detect types in ColdFusion
--->
<cfscript>
writeOutput("<h1>ColdFusion Type Metadata Diagnostic</h1>");
writeOutput("<p>This test shows what getMetadata() returns for different value types.</p>");

function testMetadata(label, value) {
    writeOutput("<hr><h3>" & label & "</h3>");

    writeOutput("<table border='1' cellpadding='8' style='border-collapse: collapse;'>");
    writeOutput("<tr><th>Property</th><th>Value</th></tr>");

    // toString
    writeOutput("<tr><td>toString(value)</td><td><code>" & encodeforhtml(toString(value)) & "</code></td></tr>");

    // isBoolean
    writeOutput("<tr><td>isBoolean(value)</td><td>" & (isBoolean(value) ? "true" : "false") & "</td></tr>");

    // isNumeric
    writeOutput("<tr><td>isNumeric(value)</td><td>" & (isNumeric(value) ? "true" : "false") & "</td></tr>");

    // isSimpleValue
    writeOutput("<tr><td>isSimpleValue(value)</td><td>" & (isSimpleValue(value) ? "true" : "false") & "</td></tr>");

    // getMetadata
    try {
        meta = getMetadata(value);
        if (isStruct(meta)) {
            writeOutput("<tr><td>getMetadata(value)</td><td><strong>Struct:</strong><br>");
            for (key in meta) {
                writeOutput(key & ": " & encodeforhtml(toString(meta[key])) & "<br>");
            }
            writeOutput("</td></tr>");

            if (structKeyExists(meta, "name")) {
                writeOutput("<tr><td><strong>meta.name</strong></td><td><code>" & encodeforhtml(meta.name) & "</code></td></tr>");
            }
        } else {
            writeOutput("<tr><td>getMetadata(value)</td><td><code>" & encodeforhtml(toString(meta)) & "</code></td></tr>");
        }
    } catch (any e) {
        writeOutput("<tr><td>getMetadata(value)</td><td style='color: red;'>ERROR: " & e.message & "</td></tr>");
    }

    // Java class via getClass()
    try {
        javaClass = value.getClass().getName();
        writeOutput("<tr><td><strong>value.getClass().getName()</strong></td><td><code>" & encodeforhtml(javaClass) & "</code></td></tr>");
    } catch (any e) {
        writeOutput("<tr><td>value.getClass().getName()</td><td style='color: red;'>ERROR: " & e.message & "</td></tr>");
    }

    writeOutput("</table>");
}

writeOutput("<h2>String Values (using javacast)</h2>");
testMetadata("String '1' - javacast('string', '1')", javacast("string", "1"));
testMetadata("String '0' - javacast('string', '0')", javacast("string", "0"));
testMetadata("String '1.0' - javacast('string', '1.0')", javacast("string", "1.0"));
testMetadata("String 'true' - javacast('string', 'true')", javacast("string", "true"));
testMetadata("String 'yes' - javacast('string', 'yes')", javacast("string", "yes"));
testMetadata("String '00123' - javacast('string', '00123')", javacast("string", "00123"));
testMetadata("String 'hello' - javacast('string', 'hello')", javacast("string", "hello"));

writeOutput("<h2>Number Values (using javacast)</h2>");
testMetadata("Integer 1 - javacast('int', 1)", javacast("int", 1));
testMetadata("Integer 0 - javacast('int', 0)", javacast("int", 0));
testMetadata("Integer 123 - javacast('int', 123)", javacast("int", 123));
testMetadata("Double 3.14 - javacast('double', 3.14)", javacast("double", 3.14));
testMetadata("Double 1.0 - javacast('double', 1.0)", javacast("double", 1.0));

writeOutput("<h2>Boolean Values (using javacast)</h2>");
testMetadata("Boolean true - javacast('boolean', true)", javacast("boolean", true));
testMetadata("Boolean false - javacast('boolean', false)", javacast("boolean", false));

writeOutput("<h2>Ambiguous Values (no javacast)</h2>");
testMetadata("Literal '1' (no cast)", "1");
testMetadata("Literal '1.0' (no cast)", "1.0");
testMetadata("Literal '0' (no cast)", "0");
testMetadata("Literal 1 (no cast)", 1);
testMetadata("Literal 0 (no cast)", 0);
testMetadata("Literal true (no cast)", true);
testMetadata("Literal false (no cast)", false);

writeOutput("<hr><h2>Conclusion</h2>");
writeOutput("<p>Use the <code>value.getClass().getName()</code> or <code>getMetadata()</code> information above to determine reliable type detection patterns.</p>");
</cfscript>
