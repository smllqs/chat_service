import 'package:chat/src/services/encryption/encryption_contract.dart';
import 'package:chat/src/services/encryption/encryption_service_implementation.dart';
import 'package:encrypt/encrypt.dart';
import 'package:test/test.dart';

void main() {
  late IEncryption sut;

  setUp(() {
    final encrypter = Encrypter(AES(Key.fromLength(32)));
    sut = EncryptionService(encrypter);
  });

  test('plain text encrypted successfully', () {
    const text = 'this is a message';
    final base64 = RegExp(
        r'^(?:[A-Za-z0-9+\/]{4})*(?:[A-Za-z0-9+\/]{2}==|[A-Za-z0-9+\/]{3}=|[A-Za-z0-9+\/]{4})$');
    final encrypted = sut.encrypt(text);
    expect(base64.hasMatch(encrypted), true);
  });

  test('decrypted the encrypted text successfully', () {
    const text = 'this is a message';
    final encrypted = sut.encrypt(text);
    final decrypt = sut.decrypt(encrypted);

    expect(decrypt, text);
  });
}
