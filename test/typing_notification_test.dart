import 'package:chat/src/models/typing_event.dart';
import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/typing/typing_notification_implementation.dart';
import 'package:chat/src/services/typing/typing_notification_service_contract.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  RethinkDb r = RethinkDb();
  late Connection connection;
  late ITypingNotification sut;

  setUp(() async {
    connection = await r.connect();
    await createDB(r, connection);
    sut = TypingNotification(r, connection);
  });

  tearDown(() async {
    sut.dispose();
    await cleanDB(r, connection);
  });

  final testUserOne = User.fromJson({
    'username': 'test_user_one',
    'photo_url': 'url',
    'id': '1111',
    'active': true,
    'last_seen': DateTime.now()
  });

  final testUserTwo = User.fromJson({
    'username': 'test_user_two',
    'photo_url': 'url',
    'id': '1234',
    'active': true,
    'last_seen': DateTime.now()
  });

  test('sent typing notification successfully', () async {
    TypingEvent typingEvent = TypingEvent(
        from: testUserTwo.id, to: testUserOne.id, event: Typing.start);
    final result = await sut.send(event: typingEvent, to: testUserOne);
    expect(result, true);
  });

  test('subscribe and receive typing events successfully', () async {
    sut.subscribe(testUserTwo, [testUserOne.id]).listen(expectAsync1((event) {
      expect(event.from, testUserOne.id);
    }, count: 2));

    TypingEvent typing = TypingEvent(
      from: testUserOne.id,
      to: testUserTwo.id,
      event: Typing.start,
    );

    TypingEvent stopTyping = TypingEvent(
      from: testUserOne.id,
      to: testUserTwo.id,
      event: Typing.stop,
    );

    await sut.send(event: typing, to: testUserTwo);
    await sut.send(event: stopTyping, to: testUserTwo);
  });
}
