import 'package:dartis/protocol.dart';

typedef CommandHandler = RESPValue Function(List<RESPValue>);

class DartisCommands {
  static final Map<String, CommandHandler> handlers = {
    'PING': ping,
  };

  static RESPValue ping(List<RESPValue> args) {
    return StringRESPValue('PONG');
  }
}
