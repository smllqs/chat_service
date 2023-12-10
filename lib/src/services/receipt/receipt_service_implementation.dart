import 'dart:async';

import 'package:chat/src/models/receipt.dart';
import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/receipt/receipt_service_contract.dart';
import 'package:logger/logger.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';

class ReceiptService implements IReceiptService {
  final RethinkDb r;
  final Connection _connection;

  Logger logger = Logger(printer: PrettyPrinter());

  final _controller = StreamController<Receipt>.broadcast();
  late StreamSubscription _changefeed;

  ReceiptService(this.r, this._connection);

  @override
  dispose() {
    _changefeed.cancel();
    _controller.close();
  }

  @override
  Stream<Receipt> receipts(User activeUser) {
    _startReceivingReceipts(activeUser);
    return _controller.stream;
  }

  @override
  Future<bool> send(Receipt receipt) async {
    var data = receipt.toJson();
    Map record = await r.table('receipts').insert(data).run(_connection);
    return record['inserted'] == 1;
  }

  _startReceivingReceipts(User activeUser) async {
    _changefeed = r
        .table('receipts')
        .filter({'recipient': activeUser.id})
        .changes({'include_initial': true})
        .run(_connection)
        .asStream()
        .cast<Feed>()
        .listen((event) async {
          event
              .forEach((feedData) {
                if (feedData['new_val'] == null) return;
                final receipt =
                    _receiptFromFeed(feedData); // problem is probably here
                _controller.sink.add(receipt);
              })
              .catchError((err) => logger.e(err))
              .onError((error, stackTrace) => logger.e(error));
        });
  }

  Receipt _receiptFromFeed(feedData) {
    var data = feedData['new_val'];
    return Receipt.fromJson(data);
  }
}
