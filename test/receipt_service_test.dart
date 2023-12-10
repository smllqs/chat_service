import 'package:chat/src/models/receipt.dart';
import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/receipt/receipt_service_contract.dart';
import 'package:chat/src/services/receipt/receipt_service_implementation.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  RethinkDb r = RethinkDb();
  late Connection connection;
  late IReceiptService sut;

  setUp(() async {
    connection = await r.connect();
    await createDB(r, connection);
    sut = ReceiptService(r, connection);
  });

  tearDown(() async {
    sut.dispose();
    await cleanDB(r, connection);
  });

  final testUserOne = User.fromJson({
    'username': 'test_user_one',
    'photo_url': 'url',
    'id': '1234',
    'active': true,
    'last_seen': DateTime.now()
  });

  test('receipt sent successfully', () async {
    Receipt receipt = Receipt(
        recipient: '444',
        messageId: '1234',
        status: ReceiptStatus.delivered,
        timestamp: DateTime.now());
    final result = await sut.send(receipt);
    expect(result, true);
  });

  test('successfully subscribe and receive receipts', () async {
    sut.receipts(testUserOne).listen(expectAsync1((receipt) {
          expect(receipt.recipient, testUserOne.id);
        }, count: 2));

    Receipt receiptOne = Receipt(
        recipient: testUserOne.id,
        messageId: '1234',
        status: ReceiptStatus.delivered,
        timestamp: DateTime.now());
    Receipt receiptTwo = Receipt(
        recipient: testUserOne.id,
        messageId: '1234',
        status: ReceiptStatus.read,
        timestamp: DateTime.now());

    await sut.send(receiptOne);
    await sut.send(receiptTwo);
  });
}
