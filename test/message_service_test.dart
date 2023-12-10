import 'package:chat/src/models/message.dart';
import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/encryption/encryption_service_implementation.dart';
import 'package:chat/src/services/message/message_service_contract.dart';
import 'package:chat/src/services/message/message_service_implementation.dart';
import 'package:encrypt/encrypt.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  RethinkDb r = RethinkDb();
  late Connection connection;
  late IMessageService sut;

  setUp(() async {
    connection = await r.connect(host: '127.0.0.1', port: 28015);
    final encrypter = EncryptionService(Encrypter(AES(Key.fromLength(32))));
    await createDB(r, connection);
    sut = MessageService(r, connection, encrypter);
  });

  tearDown(() async {
    sut.dispose();
    await cleanDB(r, connection);
  });
  // ======================= TESTS =================================

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

  test('sent message successfully', () async {
    Message message = Message(
        from: testUserOne.id,
        to: '3456',
        timestamp: DateTime.now(),
        contents: 'this is a message');

    final res = await sut.send(message);
    expect(res, true);
  });

  test('successfully subscribe and receive messages', () async {
    const contents = 'this is a message';
    sut.messages(activeUser: testUserTwo).listen(expectAsync1((message) async {
          expect(message.to, testUserTwo.id);
          expect(message.id, isNotEmpty);
          expect(message.contents, contents);
        }, count: 2));

    Message message = Message(
        from: testUserOne.id,
        to: testUserTwo.id,
        timestamp: DateTime.now(),
        contents: contents);

    Message secondMessage = Message(
        from: testUserOne.id,
        to: testUserTwo.id,
        timestamp: DateTime.now(),
        contents: contents);

    await sut.send(message);
    await sut.send(secondMessage);
  });

  test('successfully subscribe and receive new messages', () async {
    Message message = Message(
        from: testUserOne.id,
        to: testUserTwo.id,
        timestamp: DateTime.now(),
        contents: 'this is a message');

    Message secondMessage = Message(
        from: testUserOne.id,
        to: testUserTwo.id,
        timestamp: DateTime.now(),
        contents: 'this is another message');

    await sut.send(message);
    await sut.send(secondMessage).whenComplete(() =>
        sut.messages(activeUser: testUserTwo).listen(expectAsync1((message) {
              expect(message.to, testUserTwo.id);
            }, count: 2)));
  });
}
