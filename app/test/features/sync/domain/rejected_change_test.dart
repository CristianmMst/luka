import 'package:finanzia/features/sync/domain/rejected_change.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('agrupa los códigos de rechazo', () {
    expect(classifyRejectedReason('not_found'), RejectedReason.gone);
    expect(classifyRejectedReason('404'), RejectedReason.gone);
    expect(classifyRejectedReason('forbidden'), RejectedReason.gone);
    expect(classifyRejectedReason('validation_error'), RejectedReason.invalid);
    expect(classifyRejectedReason('409'), RejectedReason.invalid);
    expect(
      classifyRejectedReason('dependency_rejected'),
      RejectedReason.dependency,
    );
    expect(classifyRejectedReason('rate_limited'), RejectedReason.other);
    expect(classifyRejectedReason(null), RejectedReason.other);
  });
}
