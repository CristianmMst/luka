import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:luka/features/review/domain/review_item.dart';
import 'package:luka/features/review/domain/review_repository.dart';

/// Puerto de lectura de la revisión; se sobrescribe en
/// `lib/app/composition.dart`.
final reviewRepositoryProvider = Provider<ReviewRepository>(
  (ref) => throw UnimplementedError(
    'reviewRepositoryProvider se sobrescribe en la composición',
  ),
);

/// Un mensaje en revisión en vivo, para su formulario; `null` si ya no
/// está abierto.
final StreamProviderFamily<ReviewItem?, String> reviewItemProvider =
    StreamProvider.autoDispose.family<ReviewItem?, String>(
      (ref, rawMessageId) =>
          ref.watch(reviewRepositoryProvider).watchOne(rawMessageId),
    );
