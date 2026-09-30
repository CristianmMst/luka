import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luka/features/sync/data/platform_signals.dart';
import 'package:mocktail/mocktail.dart';

class _Connectivity extends Mock implements Connectivity {}

void main() {
  group('connectivityStream', () {
    late _Connectivity connectivity;
    late StreamController<List<ConnectivityResult>> changes;

    setUp(() {
      connectivity = _Connectivity();
      changes = StreamController<List<ConnectivityResult>>.broadcast();
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);
      when(
        () => connectivity.onConnectivityChanged,
      ).thenAnswer((_) => changes.stream);
    });

    test('varios oyentes reciben el estado inicial y los cambios', () async {
      // Sync, el envío de capturas y otros escuchan el mismo stream.
      final stream = connectivityStream(connectivity);
      final first = <bool>[];
      final second = <bool>[];
      final subs = [stream.listen(first.add), stream.listen(second.add)];
      await pumpEventQueue();

      changes.add([ConnectivityResult.none]);
      await pumpEventQueue();

      expect(first, [true, false]);
      expect(second, [true, false]);
      for (final sub in subs) {
        await sub.cancel();
      }
    });
  });

  testWidgets('foregroundTicks admite varios oyentes y avisa a todos', (
    tester,
  ) async {
    final stream = foregroundTicks();
    var first = 0;
    var second = 0;
    final subs = [
      stream.listen((_) => first++),
      stream.listen((_) => second++),
    ];

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(first, 1);
    expect(second, 1);
    for (final sub in subs) {
      unawaited(sub.cancel());
    }
    await tester.pump();
  });
}
