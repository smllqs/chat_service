import 'package:rethink_db_ns/rethink_db_ns.dart';

Future<void> createDB(RethinkDb r, Connection connection) async {
  await r.dbCreate('test').run(connection).catchError((e) {});
  await r.tableCreate('users').run(connection).catchError((e) {});
  await r.tableCreate('messages').run(connection).catchError((e) {});
  await r.tableCreate('receipts').run(connection).catchError((e) {});
  await r.tableCreate('typing_events').run(connection).catchError((e) {});
}

Future<void> cleanDB(RethinkDb r, Connection connection) async {
  await r.table('users').delete().run(connection);
  await r.table('messages').delete().run(connection);
  await r.table('receipts').delete().run(connection);
  await r.table('typing_events').delete().run(connection);
}
