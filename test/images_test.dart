import 'dart:io';

import 'package:blacklist_plus_flutter/assets/resources.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('images assets test', () {
    expect(File(Images.appIcon).existsSync(), isTrue);
    expect(File(Images.backgroundLogo).existsSync(), isTrue);
    expect(File(Images.error).existsSync(), isTrue);
    expect(File(Images.waypayLogo).existsSync(), isTrue);
    expect(File(Images.whatsappLogo).existsSync(), isTrue);
  });
}
