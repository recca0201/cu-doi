import 'package:ban_bua_tuong/domain/economy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('economy prices and reminder thresholds have one source', () {
    expect(kHintCost, 50);
    expect(kSkipCost, 150);
    expect(kSkipOfferAfterLosses, 3);
    expect(kHintReminderAfterLosses, 2);
  });
}
