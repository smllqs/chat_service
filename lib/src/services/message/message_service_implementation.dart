import 'dart:async';

import 'package:chat/src/models/message.dart';
import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/encryption/encryption_contract.dart';
import 'package:chat/src/services/message/message_service_contract.dart';
import 'package:logger/logger.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';

class MessageService implements IMessageService {
  final RethinkDb r;
  final Connection _connection;
  final IEncryption _encryption;

  Logger logger = Logger(printer: PrettyPrinter());

  final _controller = StreamController<Message>.broadcast();
  late StreamSubscription _changefeed;

  MessageService(this.r, this._connection, this._encryption);

  @override
  dispose() {
    _changefeed.cancel();
    _controller.close();
  }

  @override
  Stream<Message> messages({required User activeUser}) {
    _startReceivingMessages(activeUser);
    return _controller.stream;
  }

  @override
  Future<bool> send(Message message) async {
    var data = message.toJson();
    data['contents'] = _encryption.encrypt(message.contents);
    Map record = await r.table('messages').insert(data).run(_connection);
    return record['inserted'] == 1;
  }

  _startReceivingMessages(User activeUser) async {
    _changefeed = r
        .table('messages')
        .filter({'to': activeUser.id})
        .changes({'include_initial': true})
        .run(_connection)
        .asStream()
        .cast<Feed>()
        .listen((event) async {
          event
              .forEach((feedData) {
                if (feedData['new_val'] == null) return;
                final message =
                    _messageFromFeed(feedData); // problem is probably here
                _controller.sink.add(message);
                _removeDeliveredMessage(message);
              })
              .catchError((err) => logger.e(err))
              .onError((error, stackTrace) => logger.e(error));
        });
  }

  Message _messageFromFeed(feedData) {
    var data = feedData['new_val'];
    data['contents'] = _encryption.decrypt(data['contents']);
    return Message.fromJson(data);
  }

  _removeDeliveredMessage(Message message) {
    r
        .table('messages')
        .get(message.id)
        .delete({'return_changes': false}).run(_connection);
  }
}
