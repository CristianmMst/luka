import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/routing/routes.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/features/review/application/review_actions.dart';
import 'package:luka/features/review/application/review_list_controller.dart';
import 'package:luka/features/review/domain/review_item.dart';
import 'package:luka/features/review/presentation/widgets/review_card.dart';
import 'package:luka/features/review/presentation/widgets/review_format.dart';
import 'package:luka/features/sync/application/sync_coordinator.dart';
import 'package:luka/features/sync/presentation/sync_refresh.dart';
import 'package:luka/features/transactions/presentation/widgets/list_states.dart';
import 'package:luka/features/transactions/presentation/widgets/offline_banner.dart';

/// "Revisión" (spec 008 §3.5, AC-8.1; diseño AA "Bandeja"): los mensajes que
/// no se pudieron convertir en movimiento, los más recientes primero. Cada
/// tarjeta trae sus acciones: usar el monto (abre el detalle con él puesto)
/// o descartar.
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
      backgroundColor: scheme.surfaceContainerLowest,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.md, 18, Space.md, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 6,
                children: [
                  Row(
                    spacing: Space.sm,
                    children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            l10n.navReviewLabel,
                            style: textTheme.headlineLarge?.copyWith(
                              fontSize: 34,
                              letterSpacing: -1.2,
                            ),
                          ),
                        ),
                      ),
                      if (count != null)
                        _CountPill(text: l10n.reviewSubtitle(count)),
                    ],
                  ),
                  if (count != null && count > 0)
                    Text(
                      l10n.reviewIntro,
                      style: textTheme.bodyMedium?.copyWith(
                        height: 1.5,
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

/// Conteo en una píldora amarilla, con el punto de "pendiente".
class _CountPill extends StatelessWidget {
  const _CountPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final brand = context.lukaColors;
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: Space.sm),
      decoration: BoxDecoration(
        color: brand.goldContainer,
        borderRadius: Radii.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: brand.gold,
              shape: BoxShape.circle,
            ),
          ),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: brand.onWarningContainer,
            ),
          ),
        ],
      ),
    );
  }
}

/// La lista de mensajes. El que se resuelve (sale de [items]) no
/// desaparece de golpe: se encoge y se desvanece en 220 ms, con su
/// separación, y los de abajo suben. Con "reducir movimiento" sale al
/// instante.
class _ReviewList extends ConsumerStatefulWidget {
  const _ReviewList({required this.items});

  final List<ReviewItem> items;

  @override
  ConsumerState<_ReviewList> createState() => _ReviewListState();
}

class _ReviewListState extends ConsumerState<_ReviewList> {
  /// Lo que se dibuja: los mensajes vigentes y, en su lugar, los que salen.
  late List<ReviewItem> _shown = widget.items;
  final _leaving = <String>{};

  @override
  void didUpdateWidget(_ReviewList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final current = {for (final item in widget.items) item.rawMessageId};
    final instant = MediaQuery.disableAnimationsOf(context);
    final next = [...widget.items];
    if (!instant) {
      for (final (index, item) in _shown.indexed) {
        if (current.contains(item.rawMessageId)) continue;
        _leaving.add(item.rawMessageId);
        next.insert(index.clamp(0, next.length), item);
      }
    }
    _shown = next;
  }

  void _gone(String id) => setState(() {
    _leaving.remove(id);
    _shown = [
      for (final item in _shown)
        if (item.rawMessageId != id) item,
    ];
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      // La barra translúcida va encima: su alto entra en el margen.
      padding: const EdgeInsets.all(Space.md).copyWith(
        top: Space.sm,
        bottom: Space.md + MediaQuery.paddingOf(context).bottom,
      ),
      itemCount: _shown.length,
      itemBuilder: (context, index) {
        final item = _shown[index];
        final id = item.rawMessageId;
        final card = Padding(
          padding: const EdgeInsets.only(bottom: Space.sm),
          child: ReviewCard(
            item: item,
            onOpen: (amount) => context.go(
              Uri(
                path: '${Routes.review}/$id',
                queryParameters: {
                  if (amount != null) 'monto': '${amount.cents}',
                },
              ).toString(),
            ),
            onDiscard: () => unawaited(
              confirmAndDiscard(
                context,
                () => ref.read(reviewActionsProvider).discard(item),
              ),
            ),
          ),
        );
        if (!_leaving.contains(id)) {
          return KeyedSubtree(key: ValueKey(id), child: card);
        }
        return _Leaving(
          key: ValueKey('leaving-$id'),
          onDone: () => _gone(id),
          child: IgnorePointer(child: card),
        );
      },
    );
  }
}

/// Encoge y desvanece [child] una vez y avisa con [onDone].
class _Leaving extends StatefulWidget {
  const _Leaving({required this.onDone, required this.child, super.key});

  final VoidCallback onDone;
  final Widget child;

  @override
  State<_Leaving> createState() => _LeavingState();
}

class _LeavingState extends State<_Leaving>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 220),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) widget.onDone();
        });
    unawaited(_controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final out = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    return SizeTransition(
      sizeFactor: ReverseAnimation(out),
      axisAlignment: -1,
      child: FadeTransition(
        opacity: ReverseAnimation(out),
        child: widget.child,
      ),
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
                  color: context.lukaColors.neutralChip,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.task_alt_rounded,
                  size: 32,
                  color: scheme.primary,
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
