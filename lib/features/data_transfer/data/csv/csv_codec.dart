/// RFC 4180 compliant CSV encoder and decoder implemented in pure Dart.
class CsvCodec {
  const CsvCodec();

  /// Encodes [rows] into an RFC 4180 compliant CSV string.
  String encode(List<List<String>> rows) {
    final buffer = StringBuffer();
    for (var r = 0; r < rows.length; r++) {
      final row = rows[r];
      for (var c = 0; c < row.length; c++) {
        buffer.write(_escapeCell(row[c]));
        if (c < row.length - 1) {
          buffer.write(',');
        }
      }
      buffer.write('\r\n');
    }
    return buffer.toString();
  }

  /// Decodes a raw CSV [text] into a list of string rows.
  List<List<String>> decode(String text) {
    final rows = <List<String>>[];
    if (text.trim().isEmpty) return rows;

    final currentRow = <String>[];
    final currentCell = StringBuffer();
    var inQuotes = false;
    var i = 0;

    while (i < text.length) {
      final char = text[i];

      if (inQuotes) {
        if (char == '"') {
          // Check for escaped quote ("")
          if (i + 1 < text.length && text[i + 1] == '"') {
            currentCell.write('"');
            i += 2;
            continue;
          } else {
            // End of quoted section
            inQuotes = false;
            i++;
            continue;
          }
        } else {
          currentCell.write(char);
          i++;
          continue;
        }
      } else {
        if (char == '"') {
          inQuotes = true;
          i++;
          continue;
        } else if (char == ',') {
          currentRow.add(currentCell.toString());
          currentCell.clear();
          i++;
          continue;
        } else if (char == '\r') {
          if (i + 1 < text.length && text[i + 1] == '\n') {
            i++;
          }
          currentRow.add(currentCell.toString());
          currentCell.clear();
          rows.add(List<String>.from(currentRow));
          currentRow.clear();
          i++;
          continue;
        } else if (char == '\n') {
          currentRow.add(currentCell.toString());
          currentCell.clear();
          rows.add(List<String>.from(currentRow));
          currentRow.clear();
          i++;
          continue;
        } else {
          currentCell.write(char);
          i++;
          continue;
        }
      }
    }

    if (currentCell.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentCell.toString());
      rows.add(currentRow);
    }

    // Filter out trailing blank lines
    while (rows.isNotEmpty && rows.last.every((cell) => cell.trim().isEmpty)) {
      rows.removeLast();
    }

    return rows;
  }

  String _escapeCell(String value) {
    final containsSpecial =
        value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');

    if (!containsSpecial) {
      return value;
    }

    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}
