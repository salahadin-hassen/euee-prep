import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/design/app_button.dart';
import '../../../core/design/tokens.dart';
import '../../../core/providers.dart';
import '../../streams/domain/models/stream_model.dart';
import '../../entitlements/presentation/payment_submission_flow.dart';

/// Settings screen for changing the Preferred Stream.
///
/// Displays the current Preferred Stream, other streams already unlocked
/// (can become Preferred without payment), and streams that require
/// unlocking (routes to the payment flow).
///
/// Changing Preferred Stream does NOT change Entitlement.
/// Access is always determined by the Entitlement repository.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: AppBar(
        backgroundColor: AppColors.colorBackground,
        elevation: 0,
        title: const Text('Settings', style: AppTypography.typeHeading2),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.spaceLg),
            const _PreferredStreamSection(),
            const Divider(height: 1, color: AppColors.colorBorder),
            const _OtherStreamsSection(),
            const SizedBox(height: AppSpacing.spaceXl),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.spaceMd),
              child: AppButton(
                label: 'Reset Preferred Stream',
                variant: AppButtonVariant.text,
                onPressed: () {
                  _resetPreferredStream();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resetPreferredStream() async {
    final db = ref.read(databaseProvider);
    await db.setSetting('preferred_stream_id', '');
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}

/// Shows the currently preferred stream and allows changing it.
class _PreferredStreamSection extends ConsumerWidget {
  const _PreferredStreamSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferredStreamAsync = ref.watch(preferredStreamIdProvider);
    final streamsFuture = ref.watch(streamRepositoryProvider).getAll();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preferred Stream',
            style: AppTypography.typeHeading3,
          ),
          const SizedBox(height: AppSpacing.spaceSm),
          preferredStreamAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
            data: (streamId) {
              return FutureBuilder<List<StreamModel>>(
                future: streamsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Text('Unable to load streams.');
                  }
                  final streams = snapshot.data!;
                  final preferredStream = streams
                      .where((s) => s.id == streamId)
                      .toList()
                      .firstOrNull;
                  final preferredName = preferredStream != null
                      ? streamDisplayName(preferredStream.slug)
                      : 'Not set';

                  return ListTile(
                    title: Text(preferredName, style: AppTypography.typeBody),
                    subtitle: const Text('Tap to change'),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        size: AppIconSize.iconSizeMd),
                    onTap: () {
                      _showStreamPicker(context, ref, streams, streamId);
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Shows other streams and their entitlement status.
class _OtherStreamsSection extends ConsumerWidget {
  const _OtherStreamsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferredStreamAsync = ref.watch(preferredStreamIdProvider);
    final streamsFuture = ref.watch(streamRepositoryProvider).getAll();
    final installIdFuture = ref.watch(installIdProvider.future);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Other Streams',
            style: AppTypography.typeHeading3,
          ),
          const SizedBox(height: AppSpacing.spaceSm),
          FutureBuilder<List<StreamModel>>(
            future: streamsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return const Text('Unable to load streams.');
              }
              final streams = snapshot.data!;
              final streamId = preferredStreamAsync.valueOrNull;
              final otherStreams =
                  streams.where((s) => s.id != streamId).toList();

              if (otherStreams.isEmpty) {
                return const Text('No other streams available.');
              }

              return FutureBuilder<String?>(
                future: installIdFuture,
                builder: (context, installSnapshot) {
                  final installId = installSnapshot.data;

                  return ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: otherStreams.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.colorBorder),
                    itemBuilder: (context, index) {
                      final stream = otherStreams[index];
                      final isPreferred = stream.id == streamId;
                      final isEntitled = installId != null
                          ? ref
                              .watch(
                                  activeEntitlementForStreamProvider(stream.id))
                              .when(
                                loading: () => false,
                                error: (_, __) => false,
                                data: (e) => e != null,
                              )
                          : false;

                      return ListTile(
                        title: Text(
                          streamDisplayName(stream.slug),
                          style: AppTypography.typeBody,
                        ),
                        subtitle: isPreferred
                            ? const Text('Currently preferred')
                            : isEntitled
                                ? const Text(
                                    'Unlocked — tap to set as preferred')
                                : const Text('Locked — unlock required'),
                        trailing: isPreferred
                            ? const Icon(Icons.check_circle,
                                color: AppColors.colorPrimary)
                            : isEntitled
                                ? const Icon(Icons.lock_open,
                                    color: AppColors.colorSuccess)
                                : const Icon(Icons.lock_outline,
                                    color: AppColors.colorTextSecondary),
                        onTap: isPreferred
                            ? null
                            : isEntitled
                                ? () {
                                    _setPreferredStream(context, ref, stream);
                                  }
                                : () {
                                    _navigateToUnlock(context, ref, stream);
                                  },
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

void _showStreamPicker(
  BuildContext context,
  WidgetRef ref,
  List<StreamModel> streams,
  int? currentStreamId,
) {
  final otherStreams = streams.where((s) => s.id != currentStreamId).toList();
  if (otherStreams.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No other streams available.')),
    );
    return;
  }
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.colorBackground,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.spaceMd),
              child: Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Change Preferred Stream',
                  style: AppTypography.typeHeading3,
                ),
              ),
            ),
            ...otherStreams.map((stream) {
              final isEntitled =
                  ref.watch(activeEntitlementForStreamProvider(stream.id)).when(
                        loading: () => false,
                        error: (_, __) => false,
                        data: (e) => e != null,
                      );
              return ListTile(
                title: Text(streamDisplayName(stream.slug)),
                subtitle: isEntitled
                    ? const Text('Unlocked')
                    : const Text('Requires unlock'),
                trailing: isEntitled
                    ? const Icon(Icons.radio_button_checked,
                        color: AppColors.colorPrimary)
                    : const Icon(Icons.radio_button_off,
                        color: AppColors.colorDisabled),
                onTap: () {
                  Navigator.of(context).pop();
                  if (isEntitled) {
                    _setPreferredStream(context, ref, stream);
                  } else {
                    _navigateToUnlock(context, ref, stream);
                  }
                },
              );
            }),
          ],
        ),
      );
    },
  );
}

Future<void> _setPreferredStream(
  BuildContext context,
  WidgetRef ref,
  StreamModel stream,
) async {
  final db = ref.read(databaseProvider);
  await db.setSetting('preferred_stream_id', stream.id.toString());
  if (context.mounted) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Preferred Stream updated to ${streamDisplayName(stream.slug)}',
        ),
      ),
    );
  }
}

void _navigateToUnlock(
  BuildContext context,
  WidgetRef ref,
  StreamModel stream,
) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => PaymentSubmissionFlow(
        streamName: streamDisplayName(stream.slug),
        onFlowComplete: () {
          if (context.mounted) {
            Navigator.of(context).pop();
            ref.invalidate(preferredStreamIdProvider);
          }
        },
      ),
    ),
  );
}
