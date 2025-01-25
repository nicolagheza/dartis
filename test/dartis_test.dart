import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';

void main() {
  test('RESP Bulk String Parsing', () async {
    final input = utf8.encode("\$6\r\nDartis\r\n");
    final stream = Stream.fromIterable(input);
    final iterator = StreamIterator(stream);

    // Read the first byte
    await iterator.moveNext(); // Move to the first chunk of bytes
    final firstByte = iterator.current; // Get the first byte

    // Check if the first byte matches the expected value ('$')
    if (firstByte != utf8.encode('\$')[0]) {
      fail('Invalid type, expecting bulk strings only');
    }

    // Test passed
    expect(firstByte, utf8.encode('\$')[0]); // Validate it matches '$'

    await iterator.moveNext();
    final strSize = utf8.decode([iterator.current]);
    final size = int.parse(strSize);

    expect(size, 6); // Validate size matches 6

    // consume /r/n
    await iterator.moveNext();
    await iterator.moveNext();

    // Read 'size' bytes for the bulk string
    Uint8List nameBuffer = Uint8List(size);
    for (int i = 0; i < size; i++) {
      await iterator.moveNext();
      nameBuffer[i] = iterator.current;
    }

    // consume /r/n
    await iterator.moveNext();
    await iterator.moveNext();

    // Decode the accumulated bytes into a string
    final name = utf8.decode(nameBuffer);
    expect(name, 'Dartis');
  });
}
