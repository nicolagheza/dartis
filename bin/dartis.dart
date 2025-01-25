// import 'dart:async';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartis/resp.dart';

void main(List<String> arguments) {
  print('listening on port :6379');

  ServerSocket.bind(InternetAddress.anyIPv4, 6379).then((serverSocket) {
    serverSocket.listen((socket) {
      print("Client connected");

      final buffer = StreamController<int>();

      socket.listen((Uint8List data) {
        buffer.addStream(Stream.fromIterable(data));
      }, onError: (e) {
        print('Error $e');
        buffer.close();
      }, onDone: () {
        print('Client disconnected');
        buffer.close();
        socket.close();
      });

      Future(() async {
        final parser = RESPParser(StreamIterator(buffer.stream));
        final writer = RESPWriter(socket);
        try {
          while (true) {
            final request = await parser.read();

            print('Type: ${request.typ}');
            // Ignore request and send back a PONG
            final response = StringRESPValue("PONG");
            writer.write(response);
          }
        } catch (e) {
          print('Parsing error: $e');
        }
      });
    });
  });
}
