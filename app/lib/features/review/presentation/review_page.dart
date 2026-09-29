import 'package:finanzia/core/l10n/gen/app_localizations.dart';
import 'package:finanzia/core/routing/routes.dart';
import 'package:finanzia/core/theme/tokens/spacing.dart';
import 'package:finanzia/features/review/application/review_list_controller.dart';
import 'package:finanzia/features/review/domain/review_item.dart';
import 'package:finanzia/features/review/presentation/widgets/review_card.dart';
import 'package:finanzia/features/sync/application/sync_coordinator.dart';
import 'package:finanzia/features/sync/presentation/sync_refresh.dart';
import 'package:finanzia/features/transactions/presentation/widgets/list_states.dart';
import 'package:finanzia/features/transactions/presentation/widgets/offline_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// "Revisión" (spec 008 §3.5, AC-8.1): los mensajes que no se pudieron
/// convertir en movimiento, los más recientes primero. Cada tarjeta abre
/// el detalle para convertirlo o descartarlo.
class ReviewPage extends ConsumerWidget {
  const ReviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final items = ref.watch(reviewListControllerProvider);
    final offline = ref.watch(syncCoordinatorProvider.select((s) => s.offline));
    final count = items.value?.length;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, Space.md, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        l10n.navReviewLabel,
                        style: textTheme.headlineLarge?.copyWith(fontSize: 30),
                      ),
                    ),
                  ),
                  if (count != null)
                    Text(
                      l10n.reviewSubtitle(count),
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w400,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (offline)
              const Padding(
                padding: EdgeInsets.fromLTRB(Space.md, Space.sm, Space.md, 0),
                child: OfflineBanner(),
              ),
            Expanded(
              child: switch (items) {
                AsyncData(value: final list) when list.isEmpty =>
                  const SyncRefresh.fill(child: _EmptyReview()),
                AsyncData(value: final list) => SyncRefresh(
                  child: _ReviewList(items: list),
                ),
                AsyncError() => SyncRefresh.fill(
                  child: _LoadError(
                    onRetry: () => ref.invalidate(reviewListControllerProvider),
                  ),
                ),
                _ => const TransactionsSkeleton(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewList extends StatelessWidget {
  const _ReviewList({required this.items});

  final List<ReviewItem> items;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(Space.md).copyWith(top: Space.sm),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
      itemBuilder: (context, index) {
        final item = items[index];
        return ReviewCard(
          key: ValueKey(item.rawMessageId),
          item: item,
          onOpen: () => context.go('${Routes.review}/${item.rawMessageId}'),
        );
      },
    );
  }
}

/// "Nada por revisar".
class _EmptyReview extends StatelessWidget {
  const _EmptyReview();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: Space.sm,
          children: [
            ExcludeSemantics(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primaryContainer,
                ),
                child: Icon(
                  Icons.task_alt_rounded,
                  size: 32,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
            Semantics(
              header: true,
              child: Text(
                l10n.reviewEmptyTitle,
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(fontSize: 22),
              ),
            ),
            Text(
              l10n.reviewEmptyBody,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                height: 1.45,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: Space.sm,
          children: [
            Text(
              l10n.reviewLoadError,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontSize: 20),
            ),
            OutlinedButton(onPressed: onRetry, child: Text(l10n.reviewRetry)),
          ],
        ),
      ),
    );
  }
}
