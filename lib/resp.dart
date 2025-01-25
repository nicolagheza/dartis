// ignore_for_file: constant_identifier_names
import 'dart:async';
import 'dart:convert';
import 'dart:io';

const int CR = 13; // ASCII for Carriage Return (\r)
const int LF = 10; // ASCII for Line Feed (\n)

const int STRING = 43; // '+'
const int ERROR = 45; // '-'
const int INTEGER = 58; // ':'
const int BULK = 36; // '$'
const int ARRAY = 42; // '*'

enum RESPType { string, error, integer, bulk, array }

abstract class RESPValue {
  final RESPType typ;

  const RESPValue(this.typ);

  List<int> marshal();
}

class StringRESPValue extends RESPValue {
  final String str;

  const StringRESPValue(this.str) : super(RESPType.string);

  @override
  List<int> marshal() {
    // Format: +<string>\r\n
    return [
      STRING, // '+'
      ...utf8.encode(str), // string content
      CR, LF // \r\n
    ];
  }
}

class ErrorRESPValue extends RESPValue {
  final String str;

  const ErrorRESPValue(this.str) : super(RESPType.error);

  @override
  List<int> marshal() {
    return [ERROR, ...utf8.encode(str), CR, LF];
  }
}

class IntegerRESPValue extends RESPValue {
  final int num;

  const IntegerRESPValue(this.num) : super(RESPType.integer);

  @override
  List<int> marshal() {
    return [INTEGER, ...utf8.encode(num.toString()), CR, LF];
  }
}

class BulkRESPValue extends RESPValue {
  final String bulk;

  const BulkRESPValue(this.bulk) : super(RESPType.bulk);

  @override
  List<int> marshal() {
    // Format: $<length>\r\n<data>\r\n
    final bytes = utf8.encode(bulk);
    return [
      BULK, // '$'
      ...utf8.encode(bytes.length.toString()),
      CR, LF,
      ...bytes,
      CR, LF,
    ];
  }
}

class ArrayRESPValue extends RESPValue {
  final List<RESPValue> array;

  const ArrayRESPValue(this.array) : super(RESPType.array);

  @override
  List<int> marshal() {
    List<int> bytes = [ARRAY, ...utf8.encode(array.length.toString()), CR, LF];

    for (final value in array) {
      bytes.addAll(value.marshal());
    }
    return bytes;
  }
}

class RESPWriter {
  final Socket socket;

  const RESPWriter(this.socket);

  void write(RESPValue v) {
    socket.add(v.marshal());
  }
}

class RESPParser {
  final StreamIterator reader;

  RESPParser(this.reader);

  Future<RESPValue> read() async {
    try {
      // Read the first byte
      if (!await reader.moveNext()) {
        throw Exception('Stream ended before reading type marker');
      }
      final firstByte = reader.current;

      switch (firstByte) {
        case ARRAY:
          return await readArray();
        case BULK:
          return await readBulk();
        default:
          throw FormatException(
              'Unknown RESP type: ${firstByte.toString()} (${String.fromCharCode(firstByte)})',
              firstByte);
      }
    } catch (e) {
      throw Exception('Error reading RESP value: $e');
    }
  }

  Future<(List<int>, int)> readLine() async {
    int n = 0; // Counter for the number of bytes read
    List<int> line = []; // Accumulator for bytes as we read them

    while (true) {
      // Read next byte from our stream
      if (!await reader.moveNext()) {
        throw Exception('Stream ended before finding CRLF');
      }

      final b = reader.current;
      n++; // Increment byte counter
      line.add(b); // Add the byte to our accumulator

      // check if we've found a CRLF sequence
      if (line.length >= 2 &&
          line[line.length - 2] == CR &&
          line[line.length - 1] == LF) {
        break;
      }
    }
    return (line.sublist(0, line.length - 2), n);
  }

  Future<(int, int)> readInteger() async {
    final (bytes, count) = await readLine();

    // Convert the bytes to a string. We're reading ASCII digits, so UTF-8 is appropriate
    final numberStr = utf8.decode(bytes);

    try {
      final number = int.parse(numberStr);

      return (number, count);
    } catch (e) {
      throw Exception('Invalid integer format: $numberStr');
    }
  }

  Future<RESPValue> readArray() async {
    try {
      final (length, _) = await readInteger();
      List<RESPValue> array = [];
      for (var i = 0; i < length; i++) {
        final val = await read();
        array.add(val);
      }
      return ArrayRESPValue(array);
    } catch (e) {
      throw Exception('Error reading array: $e');
    }
  }

  Future<RESPValue> readBulk() async {
    try {
      // Read the length prefix
      final (length, _) = await readInteger();

      // Read 'length' bytes
      List<int> bulk = [];
      for (var i = 0; i < length; i++) {
        if (!await reader.moveNext()) {
          throw Exception('Stream ended before reading all bulk string bytes');
        }
        bulk.add(reader.current);
      }

      // Convert bytes to string
      final bulkStr = utf8.decode(bulk);

      // Read the trailing CRLF
      await readLine();

      return BulkRESPValue(bulkStr);
    } catch (e) {
      throw Exception('Error reading bulk string: $e');
    }
  }
}
