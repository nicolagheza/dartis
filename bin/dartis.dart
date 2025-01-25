// import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartis/resp.dart';

void main(List<String> arguments) {
  print('listening on port :6379');

  ServerSocket.bind(InternetAddress.anyIPv4, 6379).then((serverSocket) {
    serverSocket.listen((socket) {
      print("Client connected");
      socket.listen((Uint8List data) async {
        // final stream = Stream.fromIterable(data);
        // final iterator = StreamIterator(stream);

        // final resp = RESPParser(iterator);
        final writer = RESPWriter(socket);
        // Ignore request and send back a PONG
        final response = StringRESPValue("PONG");

        writer.write(response);
      }, onError: (e) {
        print('Error $e');
      }, onDone: () {
        print('Client disconnected');
        socket.close();
      });
    });
  });
}
