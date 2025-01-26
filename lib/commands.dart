import 'package:dartis/protocol.dart';
import 'package:dartis/storage.dart';

typedef CommandHandler = Future<RESPValue> Function(List<RESPValue>);

class DartisCommands {
  static final DartisStorage _storage = DartisStorage();

  static final Map<String, CommandHandler> handlers = {
    'PING': ping,
    'SET': set,
    'GET': get,
    // 'DEL': del,
    // 'EXISTS': exists,
    // 'INCR': incr,
    // 'DECR': decr,
  };

  static Future<RESPValue> ping(List<RESPValue> args) async {
    return StringRESPValue('PONG');
  }

  static Future<RESPValue> set(List<RESPValue> args) async {
    if (args.length != 2) {
      return ErrorRESPValue('ERR wrong number of arguments for SET command');
    }
    final key = (args[0] as BulkRESPValue).bulk;
    final value = (args[1] as BulkRESPValue).bulk;
    await _storage.set(key, value);
    return StringRESPValue('OK');
  }

  static Future<RESPValue> get(List<RESPValue> args) async {
    if (args.isEmpty) {
      return ErrorRESPValue('ERR wrong number of arguments for GET command');
    }
    final key = (args[0] as BulkRESPValue).bulk;
    final value = await _storage.get(key);
    return value != null ? BulkRESPValue(value) : BulkRESPValue('');
  }

  // static Future<RESPValue> del(List<RESPValue> args) async {
  //   if (args.isEmpty) {
  //     return ErrorRESPValue('ERR wrong number of arguments for DEL command');
  //   }
  //   int count = 0;
  //   for (final arg in args) {
  //     final key = (arg as BulkRESPValue).bulk;
  //     if (await _storage.del(key)) count++;
  //   }
  //   return IntegerRESPValue(count);
  // }
  //
  // static Future<RESPValue> exists(List<RESPValue> args) async {
  //   if (args.isEmpty) {
  //     return ErrorRESPValue('ERR wrong number of arguments for EXISTS command');
  //   }
  //   final key = (args[0] as BulkRESPValue).bulk;
  //   final exists = await _storage.exists(key);
  //   return IntegerRESPValue(exists ? 1 : 0);
  // }
  //
  // static Future<RESPValue> incr(List<RESPValue> args) async {
  //   if (args.isEmpty) {
  //     return ErrorRESPValue('ERR wrong number of arguments for INCR command');
  //   }
  //   final key = (args[0] as BulkRESPValue).bulk;
  //   try {
  //     final newValue = await _storage.increment(key);
  //     return IntegerRESPValue(newValue);
  //   } catch (e) {
  //     return ErrorRESPValue('ERR value is not an integer');
  //   }
  // }
  //
  // static Future<RESPValue> decr(List<RESPValue> args) async {
  //   if (args.isEmpty) {
  //     return ErrorRESPValue('ERR wrong number of arguments for DECR command');
  //   }
  //   final key = (args[0] as BulkRESPValue).bulk;
  //   try {
  //     final newValue = await _storage.decrement(key);
  //     return IntegerRESPValue(newValue);
  //   } catch (e) {
  //     return ErrorRESPValue('ERR value is not an integer');
  //   }
  // }
}

