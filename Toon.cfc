/**
 * TOON (Token-Oriented Object Notation) Converter for ColdFusion 2016+
 *
 * Converts between JSON/ColdFusion structs and TOON format
 * Based on TOON specification v1.4  https://github.com/toon-format/toon
 *
 * @author James Moberg MyCFML.com
 * @see https://github.com/JamoCA/toon-cfml
 */
component output="false" {

    /**
     * Encode ColdFusion data or JSON string to TOON format
     *
     * @param value Any ColdFusion value (struct, array, string, number, boolean, null) or JSON string
     * @param options Struct with optional settings: indent (default 2), delimiter (default ","), lengthMarker (default false - use "#" to enable)
     * @return String TOON-formatted output
     */
    public string function encode(required any value, struct options = {}) {
        variables.indent = structKeyExists(arguments.options, "indent") ? arguments.options.indent : 2;
        variables.delimiter = structKeyExists(arguments.options, "delimiter") ? arguments.options.delimiter : ",";
        variables.lengthMarker = structKeyExists(arguments.options, "lengthMarker") ? arguments.options.lengthMarker : false;

        var dataToEncode = arguments.value;

        // If input is a JSON string, deserialize it first
        if (isSimpleValue(arguments.value) && isJSON(arguments.value)) {
            try {
                dataToEncode = deserializeJSON(arguments.value);
            } catch (any e) {
                // If deserialization fails, treat as regular string
                dataToEncode = arguments.value;
            }
        }

        var result = encodeValue(dataToEncode, 0);

        // Clean up variables
        structDelete(variables, "indent");
        structDelete(variables, "delimiter");
        structDelete(variables, "lengthMarker");

        return trim(result);
    }

    /**
     * Decode TOON format to ColdFusion data
     *
     * @param input TOON-formatted string
     * @param options Struct with optional settings: indent (default 2), strict (default true)
     * @return Any ColdFusion value (struct, array, string, number, boolean, null)
     */
    public any function decode(required string input, struct options = {}) {
        variables.indent = structKeyExists(arguments.options, "indent") ? arguments.options.indent : 2;
        variables.strict = structKeyExists(arguments.options, "strict") ? arguments.options.strict : true;
        variables.lines = listToArray(arguments.input, chr(10));
        variables.currentLine = 0;

        var result = parseValue(0);

        // Clean up variables
        structDelete(variables, "indent");
        structDelete(variables, "strict");
        structDelete(variables, "lines");
        structDelete(variables, "currentLine");

        return result;
    }

    // ============================================================
    // ENCODING METHODS
    // ============================================================

    private string function encodeValue(required any value, required numeric depth) {
        if (isNull(arguments.value)) {
            return "null";
        }

        var type = determineType(arguments.value);

        switch (type) {
            case "struct":
                return encodeStruct(arguments.value, arguments.depth);
            case "array":
                return encodeArray(arguments.value, arguments.depth);
            case "string":
                return encodeString(arguments.value);
            case "number":
                return encodeNumber(arguments.value);
            case "boolean":
                return javacast("boolean", arguments.value) ? "true" : "false";
            default:
                return "null";
        }
    }

    private string function encodeStruct(required struct data, required numeric depth) {
        if (structIsEmpty(arguments.data)) {
            return "";
        }

        var lines = [];
        var keys = structKeyArray(arguments.data);
        arraySort(keys, "text");

        for (var key in keys) {
            var value = structkeyexists(arguments.data, key) ? arguments.data[key] : javacast("null", "");
            var encodedKey = encodeKey(key);
            var indentStr = repeatString(" ", arguments.depth * variables.indent);

            if (isNull(value)) {
                arrayAppend(lines, indentStr & encodedKey & ": null");
            } else if (determineType(value) == "struct") {
                var encodedValue = encodeStruct(value, arguments.depth + 1);
                if (len(encodedValue)) {
                    arrayAppend(lines, indentStr & encodedKey & ":");
                    arrayAppend(lines, encodedValue);
                } else {
                    arrayAppend(lines, indentStr & encodedKey & ":");
                }
            } else if (determineType(value) == "array") {
                var encodedArray = encodeArray(value, arguments.depth + 1);
                arrayAppend(lines, indentStr & encodedKey & encodedArray);
            } else {
                arrayAppend(lines, indentStr & encodedKey & ": " & encodeValue(value, arguments.depth));
            }
        }

        return arrayToList(lines, chr(10));
    }

    private string function encodeArray(required array data, required numeric depth) {
        var length = arrayLen(arguments.data);

        if (length == 0) {
            return "[0]:";
        }

        // Check if it's a tabular array (all items are structs with same primitive keys)
        if (isTabularArray(arguments.data)) {
            return encodeTabularArray(arguments.data, arguments.depth);
        }

        // Check if it's a primitive array
        if (isPrimitiveArray(arguments.data)) {
            return encodePrimitiveArray(arguments.data);
        }

        // Otherwise, encode as list format
        return encodeListArray(arguments.data, arguments.depth);
    }

    private string function encodePrimitiveArray(required array data) {
        var length = arrayLen(arguments.data);
        var lengthPrefix = (variables.lengthMarker != false && len(variables.lengthMarker) > 0) ? "##" : "";
        var delimiterSuffix = getDelimiterSuffix();

        var values = [];
        for (var item in arguments.data) {
            arrayAppend(values, encodeValue(item, 0));
        }

        return "[" & lengthPrefix & length & delimiterSuffix & "]: " & arrayToList(values, variables.delimiter);
    }

    private string function encodeTabularArray(required array data, required numeric depth) {
        var length = arrayLen(arguments.data);
        var lengthPrefix = (variables.lengthMarker != false && len(variables.lengthMarker) > 0) ? "##" : "";
        var delimiterSuffix = getDelimiterSuffix();

        // Get field names from first item
        var fields = structKeyArray(arguments.data[1]);
        arraySort(fields, "text");

        var encodedFields = [];
        for (var field in fields) {
            arrayAppend(encodedFields, encodeKey(field));
        }

        var header = "[" & lengthPrefix & length & delimiterSuffix & "]{" & arrayToList(encodedFields, variables.delimiter == chr(9) ? " " : variables.delimiter) & "}:";
        var lines = [header];
        var indentStr = repeatString(" ", arguments.depth * variables.indent);

        for (var item in arguments.data) {
            var rowValues = [];
            for (var field in fields) {
                var value = structKeyExists(item, field) ? item[field] : javacast("null", "");
                arrayAppend(rowValues, encodeValue(value, 0));
            }
            arrayAppend(lines, indentStr & arrayToList(rowValues, variables.delimiter));
        }

        return arrayToList(lines, chr(10));
    }

    private string function encodeListArray(required array data, required numeric depth) {
        var length = arrayLen(arguments.data);
        var lengthPrefix = (variables.lengthMarker != false && len(variables.lengthMarker) > 0) ? "##" : "";
        var delimiterSuffix = getDelimiterSuffix();

        var lines = ["[" & lengthPrefix & length & delimiterSuffix & "]:"];
        var indentStr = repeatString(" ", arguments.depth * variables.indent);

        for (var item in arguments.data) {
            var type = determineType(item);

            if (type == "struct") {
                var structLines = encodeStructInList(item, arguments.depth + 1);
                arrayAppend(lines, structLines, true);
            } else if (type == "array") {
                if (isPrimitiveArray(item)) {
                    arrayAppend(lines, indentStr & "- " & encodePrimitiveArray(item));
                } else {
                    arrayAppend(lines, indentStr & "- " & encodeArray(item, arguments.depth + 1));
                }
            } else {
                arrayAppend(lines, indentStr & "- " & encodeValue(item, 0));
            }
        }

        return arrayToList(lines, chr(10));
    }

    private string function encodeStructInList(required struct data, required numeric depth) {
        var lines = [];
        var keys = structKeyArray(arguments.data);
        arraySort(keys, "text");
        var indentStr = repeatString(" ", arguments.depth * variables.indent);
        var firstKey = true;

        for (var key in keys) {
            var value = arguments.data[key];
            var encodedKey = encodeKey(key);
            var prefix = firstKey ? indentStr.left(len(indentStr) - 2) & "- " : indentStr;

            if (isNull(value)) {
                arrayAppend(lines, prefix & encodedKey & ": null");
            } else if (determineType(value) == "struct") {
                arrayAppend(lines, prefix & encodedKey & ":");
                arrayAppend(lines, encodeStruct(value, arguments.depth + 1));
            } else if (determineType(value) == "array") {
                var encodedArray = encodeArray(value, arguments.depth + 1);
                var arrayLines = listToArray(encodedArray, chr(10));
                if (firstKey) {
                    arrayAppend(lines, prefix & encodedKey & arrayLines[1].trim());
                    for (var i = 2; i <= arrayLen(arrayLines); i++) {
                        arrayAppend(lines, indentStr & arrayLines[i].trim());
                    }
                } else {
                    arrayAppend(lines, prefix & encodedKey & encodedArray);
                }
            } else {
                arrayAppend(lines, prefix & encodedKey & ": " & encodeValue(value, 0));
            }

            firstKey = false;
        }

        return arrayToList(lines, chr(10));
    }

    private string function encodeKey(required string key) {
        // Keys must be quoted if they don't match identifier pattern
        if (reFind("^[a-zA-Z_][a-zA-Z0-9_.]*$", arguments.key)) {
            return arguments.key;
        }
        return quoteString(arguments.key);
    }

    private string function encodeString(required string value) {
        // Check if string needs quoting
        if (needsQuoting(arguments.value)) {
            return quoteString(arguments.value);
        }
        return arguments.value;
    }

    private boolean function needsQuoting(required string value) {
        // Empty string
        if (len(arguments.value) == 0) return true;

        // Leading or trailing spaces
        if (arguments.value != trim(arguments.value)) return true;

        // Contains delimiter, colon, quote, backslash
        if (find(variables.delimiter, arguments.value) > 0) return true;
        if (find(":", arguments.value) > 0) return true;
        if (find("""", arguments.value) > 0) return true;
        if (find("\", arguments.value) > 0) return true;
        if (find(chr(9), arguments.value) > 0) return true;
        if (find(chr(13), arguments.value) > 0) return true;
        if (find(chr(10), arguments.value) > 0) return true;

        // Looks like boolean/number/null - ALWAYS quote these if they're strings
        if (listFindNoCase("true,false,null,yes,no", arguments.value)) return true;
        if (isNumeric(arguments.value)) return true;  // Quote all numeric-looking strings

        // Starts with "- "
        if (left(arguments.value, 2) == "- ") return true;

        // Looks like structural token
        if (reFind("^\[[\d##]+\]", arguments.value)) return true;
        if (reFind("^{.*}$", arguments.value)) return true;

        return false;
    }

    private string function quoteString(required string value) {
        var escaped = arguments.value;

        // Escape backslashes first
        escaped = replace(escaped, "\", "\\", "all");

        // Escape quotes
        escaped = replace(escaped, """", "\""", "all");

        // Escape control characters
        escaped = replace(escaped, chr(9), "\t", "all");
        escaped = replace(escaped, chr(13), "\r", "all");
        escaped = replace(escaped, chr(10), "\n", "all");

        return """" & escaped & """";
    }

    private string function encodeNumber(required numeric value) {
        // Ensure finite number
        if (!isValid("numeric", arguments.value)) return "null";

        var stringValue = toString(arguments.value);

        // Check if this is a large integer (beyond int32 range: -2147483648 to 2147483647)
        // For large integers, just return the string representation without formatting
        if (reFind("^-?\d+$", stringValue)) {
            // It's a whole number (no decimal point)
            var absValue = abs(arguments.value);

            // If it exceeds int32 max (2147483647), return as-is
            if (absValue > 2147483647) {
                return stringValue;
            }

            // For regular integers, return without decimal
            return toString(int(arguments.value));
        }

        var numValue = arguments.value;

        // If it's a whole number (within int range), return as integer
        if (numValue == int(numValue) && abs(numValue) <= 2147483647) {
            return toString(int(numValue));
        }

        // Format decimal without scientific notation
        var formatted = numberFormat(numValue, "9999999999999999.9999999999");

        // Remove trailing zeros after decimal point
        if (find(".", formatted) > 0) {
            formatted = reReplace(formatted, "0+$", "");
            formatted = reReplace(formatted, "\.$", "");
        }

        return trim(formatted);
    }

    private string function getDelimiterSuffix() {
        if (variables.delimiter == chr(9)) {
            return " ";  // Tab delimiter shows as space in header
        } else if (variables.delimiter == "|") {
            return "|";
        }
        return "";  // Comma is implicit
    }

    // ============================================================
    // TYPE CHECKING METHODS
    // ============================================================

    private string function determineType(required any value) {
        if (isNull(arguments.value)) return "null";
        if (isStruct(arguments.value)) return "struct";
        if (isArray(arguments.value)) return "array";

        // Use getMetadata() to check the ACTUAL underlying Java type
        // This is the only reliable way to distinguish strings from numbers in ColdFusion
        try {
            var metadata = getMetadata(arguments.value);
            var className = "";

            // getMetadata returns different things depending on the type
            if (isStruct(metadata) && structKeyExists(metadata, "name")) {
                className = metadata.name;
            } else if (isSimpleValue(metadata)) {
                className = metadata;
            } else {
                className = toString(metadata);
            }

            // Check the actual Java class name
            if (findNoCase("String", className) || findNoCase("CharSequence", className)) {
                return "string";
            }
            if (findNoCase("Boolean", className)) {
                return "boolean";
            }
            // Support all numeric types including Long and BigInteger for large numbers
            if (findNoCase("Integer", className) || findNoCase("Long", className) ||
                findNoCase("Short", className) || findNoCase("Byte", className) ||
                findNoCase("BigInteger", className)) {
                return "number";
            }
            if (findNoCase("Double", className) || findNoCase("Float", className) ||
                findNoCase("BigDecimal", className)) {
                return "number";
            }

        } catch (any e) {
            // If getMetadata fails, fall back to heuristics
        }

        // Fallback: use heuristics with regex-based detection
        var stringValue = toString(arguments.value);

        // Check if it looks like a pure number using regex
        if (reFind("^-?\d+\.?\d*$", stringValue) || reFind("^-?\d*\.\d+$", stringValue)) {
            // It looks numeric - check for special cases that should be strings

            // Leading zeros (like "00123" or "05") = string ID/code
            if (len(stringValue) > 1 && left(stringValue, 1) == "0" && find(".", stringValue) == 0) {
                return "string";
            }

            // If converting to number would lose precision, it's a string
            if (isNumeric(stringValue)) {
                var numValue = val(stringValue);

                // For whole numbers
                if (numValue == int(numValue)) {
                    var numAsString = toString(int(numValue));
                    // If "1.0" becomes 1 and "1.0" != "1", it's a string
                    if (stringValue != numAsString) {
                        return "string";
                    }
                    return "number";
                } else {
                    // For decimals
                    var formatted = numberFormat(numValue, "9999999999999999.9999999999");
                    formatted = trim(formatted);
                    if (find(".", formatted) > 0) {
                        formatted = reReplace(formatted, "0+$", "");
                        formatted = reReplace(formatted, "\.$", "");
                    }
                    if (stringValue == formatted) {
                        return "number";
                    }
                    return "string";
                }
            }
        }

        // Check for boolean literals
        if (isBoolean(arguments.value)) {
            var upperValue = uCase(stringValue);
            if (listFind("TRUE,FALSE,YES,NO", upperValue) && !isNumeric(stringValue)) {
                return "boolean";
            }
        }

        // Default to string
        return "string";
    }

    private boolean function isTabularArray(required array data) {
        if (arrayLen(arguments.data) == 0) return false;

        var firstItem = arguments.data[1];
        if (!isStruct(firstItem)) return false;

        var keys = structKeyArray(firstItem);

        // Check all values in first item are primitive
        for (var key in keys) {
            var type = determineType(firstItem[key]);
            if (!listFind("string,number,boolean,null", type)) return false;
        }

        // Check all items have same keys and primitive values
        for (var item in arguments.data) {
            if (!isStruct(item)) return false;
            if (structCount(item) != arrayLen(keys)) return false;

            for (var key in keys) {
                if (!structKeyExists(item, key)) return false;
                var type = determineType(item[key]);
                if (!listFind("string,number,boolean,null", type)) return false;
            }
        }

        return true;
    }

    private boolean function isPrimitiveArray(required array data) {
        for (var item in arguments.data) {
            var type = determineType(item);
            if (!listFind("string,number,boolean,null", type)) return false;
        }
        return true;
    }

    // ============================================================
    // DECODING METHODS
    // ============================================================

    private any function parseValue(required numeric depth) {
        if (variables.currentLine >= arrayLen(variables.lines)) {
            return javacast("null", "");
        }

        var line = variables.lines[variables.currentLine + 1];
        var currentIndent = getIndentLevel(line);

        if (currentIndent != arguments.depth * variables.indent) {
            return javacast("null", "");
        }

        line = trim(line);

        // Check for array header
        if (left(line, 1) == "[") {
            return parseArray(arguments.depth);
        }

        // Check for list item
        if (left(line, 2) == "- ") {
            variables.currentLine++;
            return parseListItem(mid(line, 3, len(line)), arguments.depth);
        }

        // Check for key-value pair
        if (find(":", line) > 0) {
            return parseStruct(arguments.depth);
        }

        variables.currentLine++;
        return parsePrimitive(line);
    }

    private struct function parseStruct(required numeric depth) {
        var result = [:];

        while (variables.currentLine < arrayLen(variables.lines)) {
            var line = variables.lines[variables.currentLine + 1];
            var currentIndent = getIndentLevel(line);

            if (currentIndent < arguments.depth * variables.indent) {
                break;
            }

            if (currentIndent > arguments.depth * variables.indent) {
                break;
            }

            line = trim(line);
            var colonPos = find(":", line);

            if (colonPos == 0) {
                variables.currentLine++;
                continue;
            }

            var keyPart = trim(left(line, colonPos - 1));
            var valuePart = trim(mid(line, colonPos + 1, len(line)));

            // Check if keyPart contains array notation (e.g., "records[2]" or "tags[3]")
            var arrayMatch = reFind("^(.+?)\[(##)?(\d+)([^\]]*)\]$", keyPart, 1, true);

            if (arrayMatch.pos[1] > 0 && len(valuePart) == 0) {
                // Key has array notation and no value on same line
                // Extract the actual key (before the bracket)
                var actualKey = mid(keyPart, arrayMatch.pos[2], arrayMatch.len[2]);
                actualKey = unquoteString(actualKey);

                // Extract array length
                var arrayLength = val(mid(keyPart, arrayMatch.pos[4], arrayMatch.len[4]));

                // Determine delimiter from the array notation
                var arrayDelimiter = ",";
                if (arrayMatch.len[5] > 0) {
                    var delimiterPart = mid(keyPart, arrayMatch.pos[5], arrayMatch.len[5]);
                    if (find(" ", delimiterPart) > 0) {
                        arrayDelimiter = chr(9);  // Tab
                    } else if (find("|", delimiterPart) > 0) {
                        arrayDelimiter = "|";
                    }
                }

                variables.currentLine++;

                // Check if next line has field definition for tabular array
                var peekLine = variables.currentLine <= arrayLen(variables.lines) ? trim(variables.lines[variables.currentLine + 1]) : "";

                // Check if this is a tabular array (has {fields})
                var fieldsMatch = reFind("\{([^}]+)\}", keyPart, 1, true);

                if (fieldsMatch.pos[1] > 0) {
                    // Tabular array
                    result[actualKey] = parseTabularArrayContent(arrayLength, keyPart, arguments.depth + 1, arrayDelimiter);
                } else if (len(peekLine) > 0 && left(peekLine, 2) == "- ") {
                    // List array
                    result[actualKey] = parseListArrayContent(arrayLength, arguments.depth + 1);
                } else {
                    // Primitive array - value should be on same line after colon
                    // But we already checked valuePart is empty, so this is an error
                    // Unless it's an empty array
                    if (arrayLength == 0) {
                        result[actualKey] = [];
                    } else {
                        throwError("Expected array content after " & keyPart);
                    }
                }
            } else {
                // Normal key-value pair
                var key = keyPart;

                // Check if this is an inline array like "tags[3]: a,b,c"
                var inlineArrayMatch = reFind("^(.+?)\[(##)?(\d+)([^\]]*)\]$", keyPart, 1, true);

                if (inlineArrayMatch.pos[1] > 0 && len(valuePart) > 0) {
                    // This is an inline array
                    var actualKey = mid(keyPart, inlineArrayMatch.pos[2], inlineArrayMatch.len[2]);
                    actualKey = unquoteString(actualKey);
                    var arrayLength = val(mid(keyPart, inlineArrayMatch.pos[4], inlineArrayMatch.len[4]));
                    var arrayDelimiter = ",";
                    if (inlineArrayMatch.len[5] > 0) {
                        var delimiterPart = mid(keyPart, inlineArrayMatch.pos[5], inlineArrayMatch.len[5]);
                        if (find(" ", delimiterPart) > 0) {
                            arrayDelimiter = chr(9);
                        } else if (find("|", delimiterPart) > 0) {
                            arrayDelimiter = "|";
                        }
                    }

                    variables.currentLine++;
                    result[actualKey] = parsePrimitiveArray(valuePart, arrayLength, arrayDelimiter);
                } else {
                    // Normal key-value
                    key = unquoteString(keyPart);

                    variables.currentLine++;

                    if (len(valuePart) == 0) {
                        // Value is on next line(s)
                        result[key] = parseValue(arguments.depth + 1);
                    } else {
                        result[key] = parsePrimitive(valuePart);
                    }
                }
            }
        }

        return result;
    }

    private array function parseListArrayContent(required numeric length, required numeric depth) {
        var result = [];

        for (var i = 1; i <= arguments.length; i++) {
            if (variables.currentLine >= arrayLen(variables.lines)) {
                throwError("Unexpected end of input in list array");
            }

            var line = variables.lines[variables.currentLine + 1];
            var lineIndent = getIndentLevel(line);

            if (lineIndent != arguments.depth * variables.indent) {
                throwError("Invalid indentation in list array item");
            }

            line = trim(line);

            if (left(line, 2) != "- ") {
                throwError("Expected list item marker '- '");
            }

            variables.currentLine++;
            var itemValue = trim(mid(line, 3, len(line)));

            if (len(itemValue) == 0) {
                // Value is on next line
                arrayAppend(result, parseValue(arguments.depth + 1));
            } else if (find(":", itemValue) > 0) {
                // Inline struct (key: value format)
                variables.currentLine--;
                arrayAppend(result, parseStructInList(arguments.depth));
            } else {
                // Primitive value
                arrayAppend(result, parsePrimitive(itemValue));
            }
        }

        return result;
    }

    private struct function parseStructInList(required numeric depth) {
        var result = [:];
        var line = variables.lines[variables.currentLine + 1];
        line = trim(line);

        // First line has "- key: value"
        if (left(line, 2) == "- ") {
            line = trim(mid(line, 3, len(line)));
            var colonPos = find(":", line);
            if (colonPos > 0) {
                var firstKey = trim(left(line, colonPos - 1));
                var firstValue = trim(mid(line, colonPos + 1, len(line)));

                // Check if key has array notation for inline array
                var arrayMatch = reFind("^(.+?)\[(##)?(\d+)([^\]]*)\]$", firstKey, 1, true);

                if (arrayMatch.pos[1] > 0 && len(firstValue) > 0) {
                    // Inline array like "tags[3]: a,b,c"
                    var actualKey = mid(firstKey, arrayMatch.pos[2], arrayMatch.len[2]);
                    actualKey = unquoteString(actualKey);
                    var arrayLength = val(mid(firstKey, arrayMatch.pos[4], arrayMatch.len[4]));
                    var arrayDelimiter = ",";
                    if (arrayMatch.len[5] > 0) {
                        var delimiterPart = mid(firstKey, arrayMatch.pos[5], arrayMatch.len[5]);
                        if (find(" ", delimiterPart) > 0) {
                            arrayDelimiter = chr(9);
                        } else if (find("|", delimiterPart) > 0) {
                            arrayDelimiter = "|";
                        }
                    }
                    result[actualKey] = parsePrimitiveArray(firstValue, arrayLength, arrayDelimiter);
                } else {
                    // Normal key-value
                    result[unquoteString(firstKey)] = len(firstValue) > 0 ? parsePrimitive(firstValue) : javacast("null", "");
                }
            }
        }

        variables.currentLine++;

        // Read remaining fields at same indentation
        while (variables.currentLine < arrayLen(variables.lines)) {
            line = variables.lines[variables.currentLine + 1];
            var lineIndent = getIndentLevel(line);

            // Fields should be at depth * indent + 2 to align with first field after "- "
            if (lineIndent != arguments.depth * variables.indent + 2) {
                break;
            }

            line = trim(line);

            // Skip list markers
            if (left(line, 2) == "- ") {
                break;
            }

            var colonPos = find(":", line);

            if (colonPos == 0) {
                break;
            }

            var keyPart = trim(left(line, colonPos - 1));
            var valuePart = trim(mid(line, colonPos + 1, len(line)));

            // Check if key has array notation for inline array
            var arrayMatch = reFind("^(.+?)\[(##)?(\d+)([^\]]*)\]$", keyPart, 1, true);

            if (arrayMatch.pos[1] > 0 && len(valuePart) > 0) {
                // Inline array like "tags[3]: a,b,c"
                var actualKey = mid(keyPart, arrayMatch.pos[2], arrayMatch.len[2]);
                actualKey = unquoteString(actualKey);
                var arrayLength = val(mid(keyPart, arrayMatch.pos[4], arrayMatch.len[4]));
                var arrayDelimiter = ",";
                if (arrayMatch.len[5] > 0) {
                    var delimiterPart = mid(keyPart, arrayMatch.pos[5], arrayMatch.len[5]);
                    if (find(" ", delimiterPart) > 0) {
                        arrayDelimiter = chr(9);
                    } else if (find("|", delimiterPart) > 0) {
                        arrayDelimiter = "|";
                    }
                }
                result[actualKey] = parsePrimitiveArray(valuePart, arrayLength, arrayDelimiter);
                variables.currentLine++;
            } else {
                var key = unquoteString(keyPart);

                variables.currentLine++;

                if (len(valuePart) == 0) {
                    result[key] = parseValue(arguments.depth + 1);
                } else {
                    result[key] = parsePrimitive(valuePart);
                }
            }
        }

        return result;
    }

    private array function parseTabularArrayContent(required numeric length, required string header, required numeric depth, required string delimiter) {
        // Extract field names from header
        var fieldsMatch = reFind("\{([^}]+)\}", arguments.header, 1, true);
        var fieldsStr = mid(arguments.header, fieldsMatch.pos[2], fieldsMatch.len[2]);
        var fieldDelimiter = arguments.delimiter == chr(9) ? " " : arguments.delimiter;
        var fields = listToArray(fieldsStr, fieldDelimiter);

        var result = [];

        for (var i = 1; i <= arguments.length; i++) {
            if (variables.currentLine >= arrayLen(variables.lines)) {
                throwError("Unexpected end of input in tabular array");
            }

            var line = variables.lines[variables.currentLine + 1];
            var rowIndent = getIndentLevel(line);

            if (rowIndent != arguments.depth * variables.indent) {
                throwError("Invalid indentation in tabular array row");
            }

            line = trim(line);
            variables.currentLine++;

            var values = listToArray(line, arguments.delimiter);
            var row = [:];

            for (var j = 1; j <= arrayLen(fields); j++) {
                var fieldName = unquoteString(trim(fields[j]));
                var value = j <= arrayLen(values) ? trim(values[j]) : javacast("null", "");
                row[fieldName] = parsePrimitive(value);
            }

            arrayAppend(result, row);
        }

        return result;
    }

    private array function parseArray(required numeric depth) {
        var line = variables.lines[variables.currentLine + 1];
        var trimmedLine = trim(line);
        variables.currentLine++;

        // Parse array header: [length]: or [length]{fields}:
        var headerMatch = reFind("\[##?(\d+)([^\]]*)\](\{[^}]+\})?:", trimmedLine, 1, true);

        if (arrayLen(headerMatch.pos) < 2 || headerMatch.pos[1] == 0) {
            throwError("Invalid array header: " & trimmedLine);
        }

        var length = val(mid(trimmedLine, headerMatch.pos[2], headerMatch.len[2]));

        // Determine delimiter from header
        var arrayDelimiter = ",";
        if (headerMatch.len[3] > 0) {
            var delimiterPart = mid(trimmedLine, headerMatch.pos[3], headerMatch.len[3]);
            if (find(" ", delimiterPart) > 0) {
                arrayDelimiter = chr(9);  // Tab
            } else if (find("|", delimiterPart) > 0) {
                arrayDelimiter = "|";
            }
        }

        // Check if tabular (has field definition)
        if (arrayLen(headerMatch.pos) >= 4 && headerMatch.pos[4] > 0) {
            return parseTabularArray(length, trimmedLine, arguments.depth, arrayDelimiter);
        }

        // Check if primitive array (value on same line)
        if (find("]:", trimmedLine) > 0) {
            var valueStart = find("]:", trimmedLine) + 2;
            var values = trim(mid(trimmedLine, valueStart, len(trimmedLine)));

            if (len(values) > 0) {
                return parsePrimitiveArray(values, length, arrayDelimiter);
            }
        }

        // Parse list array
        return parseListArray(length, arguments.depth);
    }

    private array function parsePrimitiveArray(required string values, required numeric length, required string delimiter) {
        var result = [];
        var items = listToArray(arguments.values, arguments.delimiter);

        for (var item in items) {
            arrayAppend(result, parsePrimitive(trim(item)));
        }

        return result;
    }

    private array function parseTabularArray(required numeric length, required string header, required numeric depth, required string delimiter) {
        // Extract field names
        var fieldsMatch = reFind("\{([^}]+)\}", arguments.header, 1, true);
        var fieldsStr = mid(arguments.header, fieldsMatch.pos[2], fieldsMatch.len[2]);
        var fieldDelimiter = arguments.delimiter == chr(9) ? " " : arguments.delimiter;
        var fields = listToArray(fieldsStr, fieldDelimiter);

        var result = [];

        for (var i = 1; i <= arguments.length; i++) {
            if (variables.currentLine >= arrayLen(variables.lines)) {
                throwError("Unexpected end of input in tabular array");
            }

            var line = variables.lines[variables.currentLine + 1];
            var rowIndent = getIndentLevel(line);

            if (rowIndent != arguments.depth * variables.indent) {
                throwError("Invalid indentation in tabular array row");
            }

            line = trim(line);
            variables.currentLine++;

            var values = listToArray(line, arguments.delimiter);
            var row = [:];

            for (var j = 1; j <= arrayLen(fields); j++) {
                var fieldName = unquoteString(trim(fields[j]));
                var value = j <= arrayLen(values) ? trim(values[j]) : javacast("null", "");
                row[fieldName] = parsePrimitive(value);
            }

            arrayAppend(result, row);
        }

        return result;
    }

    private array function parseListArray(required numeric length, required numeric depth) {
        var result = [];

        for (var i = 1; i <= arguments.length; i++) {
            if (variables.currentLine >= arrayLen(variables.lines)) {
                throwError("Unexpected end of input in list array");
            }

            var line = variables.lines[variables.currentLine + 1];
            var lineIndent = getIndentLevel(line);

            if (lineIndent != arguments.depth * variables.indent) {
                throwError("Invalid indentation in list array item");
            }

            line = trim(line);

            if (left(line, 2) != "- ") {
                throwError("Expected list item marker '- '");
            }

            variables.currentLine++;
            var itemValue = trim(mid(line, 3, len(line)));

            if (len(itemValue) == 0) {
                // Value is on next line
                arrayAppend(result, parseValue(arguments.depth + 1));
            } else if (left(itemValue, 1) == "[") {
                // Inline array
                variables.currentLine--;
                arrayAppend(result, parseArray(arguments.depth));
            } else {
                arrayAppend(result, parsePrimitive(itemValue));
            }
        }

        return result;
    }

    private any function parseListItem(required string value, required numeric depth) {
        if (len(arguments.value) == 0) {
            return parseValue(arguments.depth + 1);
        }

        if (left(arguments.value, 1) == "[") {
            variables.currentLine--;
            return parseArray(arguments.depth);
        }

        if (find(":", arguments.value) > 0) {
            variables.currentLine--;
            return parseStruct(arguments.depth);
        }

        return parsePrimitive(arguments.value);
    }

    private any function parsePrimitive(required string value) {
        var trimmed = trim(arguments.value);

        if (len(trimmed) == 0 || trimmed == "null") {
            return javacast("null", "");
        }

        // Check if quoted string - must check this FIRST
        // If it was quoted in TOON, it MUST stay as a string (never convert to number/boolean)
        if (left(trimmed, 1) == """" && right(trimmed, 1) == """") {
            return unquoteString(trimmed);  // Return as string, period.
        }

        // Unquoted values: determine type based on content

        // Use regex to check if it looks like a number BEFORE checking boolean
        // Pattern: optional minus, digits, optional decimal and more digits
        if (reFind("^-?\d+\.?\d*$", trimmed) || reFind("^-?\d*\.\d+$", trimmed)) {
            // It's definitely a number (not "yes", "no", "true", "false")

            // Check if it's a whole number or decimal
            if (reFind("^-?\d+$", trimmed)) {
                // Whole number - check if it exceeds int32 range
                var numValue = val(trimmed);
                var absValue = abs(numValue);

                // ColdFusion int() max is 2147483647 (int32)
                // For larger values, use long
                if (absValue > 2147483647) {
                    // Large integer - use long (int64) which supports up to 9223372036854775807
                    try {
                        return createObject("java", "java.lang.Long").valueOf(trimmed);
                    } catch (any e) {
                        // If it exceeds long range, return as BigInteger
                        return createObject("java", "java.math.BigInteger").init(trimmed);
                    }
                } else {
                    // Regular integer
                    return javacast("int", int(numValue));
                }
            } else {
                // Decimal number
                var numValue = val(trimmed);
                return javacast("double", numValue);
            }
        }

        // Check for boolean literals - ONLY exact matches "true" or "false" (case-sensitive)
        if (trimmed == "true") return javacast("boolean", true);
        if (trimmed == "false") return javacast("boolean", false);

        // Everything else is a string (including "yes", "no", "1.0" as string, etc.)
        return trimmed;
    }

    private string function unquoteString(required string value) {
        var trimmed = trim(arguments.value);

        if (left(trimmed, 1) != """" || right(trimmed, 1) != """") {
            return trimmed;
        }

        var unquoted = mid(trimmed, 2, len(trimmed) - 2);

        // Unescape sequences
        unquoted = replace(unquoted, "\""", """", "all");
        unquoted = replace(unquoted, "\\", "\", "all");
        unquoted = replace(unquoted, "\t", chr(9), "all");
        unquoted = replace(unquoted, "\r", chr(13), "all");
        unquoted = replace(unquoted, "\n", chr(10), "all");

        return unquoted;
    }

    private numeric function getIndentLevel(required string line) {
        var count = 0;
        for (var i = 1; i <= len(arguments.line); i++) {
            if (mid(arguments.line, i, 1) == " ") {
                count++;
            } else {
                break;
            }
        }
        return count;
    }

    // ============================================================
    // UTILITY METHODS
    // ============================================================

    private string function repeatString(required string str, required numeric times) {
        var result = "";
        for (var i = 1; i <= arguments.times; i++) {
            result &= arguments.str;
        }
        return result;
    }

    private void function throwError(required string message) {
        throw(type="TOON.ParseError", message=arguments.message);
    }

}
