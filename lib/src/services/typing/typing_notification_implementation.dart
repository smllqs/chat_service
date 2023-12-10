import 'dart:async';

import 'package:chat/src/models/typing_event.dart';
import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/typing/typing_notification_service_contract.dart';
import 'package:logger/logger.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';

class TypingNotification implements ITypingNotification {
  final RethinkDb _r;
  final Connection _connection;

  final _controller = StreamController<TypingEvent>.broadcast();
  late StreamSubscription _changeFeed;

  Logger logger = Logger(printer: PrettyPrinter());

  TypingNotification(this._r, this._connection);

  @override
  Future<bool> send({required TypingEvent event, required User to}) async {
    if (!to.active) return false;
    Map record = await _r
        .table('typing_events')
        .insert(event.toJson(), {'conflict': 'update'}).run(_connection);
    return record['inserted'] == 1;
  }

  @override
  Stream<TypingEvent> subscribe(User user, List<String> userIds) {
    _startReceivingTypingEvents(user, userIds);
    return _controller.stream;
  }

  @override
  void dispose() {
    _changeFeed.cancel();
    _controller.close();
  }

  _startReceivingTypingEvents(User user, List<String> userIds) {
    _changeFeed = _r
        .table('typing_events')
        .filter((event) {
          return event('to')
              .eq(user.id)
              .and(_r.expr(userIds).contains(event('from')));
        })
        .changes({'include_initial': true})
        .run(_connection)
        .asStream()
        .cast<Feed>()
        .listen((event) {
          event.forEach((feedData) {
            if (feedData['new_val'] == null) return;

            final typing = _eventFromFeed(feedData);
            _controller.sink.add(typing);
            _removeEvent(typing);
          }).catchError((error) => logger.e(error));
        });
  }

  _eventFromFeed(Map<String, dynamic> feedData) {
    return TypingEvent.fromJson(feedData['new_val']);
  }

  _removeEvent(TypingEvent typing) {
    _r
        .table('messages')
        .get(typing.id)
        .delete({'return_changes': false}).run(_connection);
  }
}
