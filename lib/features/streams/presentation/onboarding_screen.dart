import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/design/app_button.dart';
import '../../../core/design/tokens.dart';
import '../../../core/providers.dart';
import '../domain/models/stream_model.dart';
import '../../entitlements/presentation/payment_submission_flow.dart';
import '../../subjects/presentation/subject_list_screen.dart';

/// Onboarding screen for first-launch Preferred Stream selection.
///
/// Shows Natural Science / Social Science options. The user selects a
/// stream, and the app checks whether that stream is entitled. If
/// entitled the selection is persisted as Preferred Stream and the
/// user proceeds to the Subject List; if not entitled the onboarding
/// routes to the unlock/payment flow instead of saving the preference.
///
/// Presentation → Riverpod → Repository → Local Data Source → Drift.
/// The onboarding screen never queries Drift directly.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late Future<List<StreamModel>> _streamsFuture;
  StreamModel? _selectedStream;

  @override
  void initState() {
    super.initState();
    _streamsFuture = ref.read(streamRepositoryProvider).getAll();
  }

  Future<void> _continue() async {
    if (_selectedStream == null) return;

    final streamId = _selectedStream!.id;
    final navigator = Navigator.of(context);

    // Check whether the selected stream is entitled.
    bool isEntitled = false;
    try {
      final installId = await ref.read(installIdProvider.future);
      final repo = ref.read(entitlementRepositoryProvider);
      final entitlement = await repo.getActiveByInstallIdAndStreamId(
        installId,
        streamId,
      );
      isEntitled = entitlement != null;
    } catch (_) {
      // Fail closed: entitlement lookup failure must not allow
      // protected content to appear accessible.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to verify entitlement. Please try again.'),
          backgroundColor: AppColors.colorError,
        ),
      );
      return;
    }

    if (!mounted) return;

    if (isEntitled) {
      // Persist Preferred Stream.
      final db = ref.read(databaseProvider);
      await db.setSetting('preferred_stream_id', streamId.toString());

      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const SubjectListScreen()),
      );
    } else {
      // Do NOT save as Preferred Stream. Route to the unlock/payment
      // flow instead.
      if (!mounted) return;
      navigator.push(
        MaterialPageRoute(
          builder: (_) => PaymentSubmissionFlow(
            streamName: streamDisplayName(_selectedStream!.slug),
            onFlowComplete: () {
              if (context.mounted) {
                navigator.pop();
                ref.invalidate(preferredStreamIdProvider);
              }
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: AppBar(
        backgroundColor: AppColors.colorBackground,
        elevation: 0,
        title: const Text('EUEE Prep', style: AppTypography.typeHeading2),
      ),
      body: SafeArea(
        child: FutureBuilder<List<StreamModel>>(
          future: _streamsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _OnboardingLoading();
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.spaceLg),
                  child: Text('Error: ${snapshot.error}'),
                ),
              );
            }
            final streams = snapshot.data ?? const [];
            return _OnboardingContent(
              streams: streams,
              selectedStream: _selectedStream,
              onSelect: (stream) {
                setState(() => _selectedStream = stream);
              },
              onContinue: _continue,
            );
          },
        ),
      ),
    );
  }
}

/// Loading state while streams load.
class _OnboardingLoading extends StatelessWidget {
  const _OnboardingLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

/// Stream selection content.
class _OnboardingContent extends StatelessWidget {
  const _OnboardingContent({
    required this.streams,
    required this.selectedStream,
    required this.onSelect,
    required this.onContinue,
  });

  final List<StreamModel> streams;
  final StreamModel? selectedStream;
  final ValueChanged<StreamModel> onSelect;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.spaceMd,
            AppSpacing.spaceLg,
            AppSpacing.spaceMd,
            AppSpacing.spaceSm,
          ),
          child: Text(
            'Choose your stream',
            style: AppTypography.typeDisplay,
          ),
        ),
        const SizedBox(height: AppSpacing.spaceSm),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.spaceMd),
          child: Text(
            'Select the stream that matches your academic track. '
            'You can change this later in Settings.',
            style: AppTypography.typeBody,
            textAlign: TextAlign.start,
          ),
        ),
        const SizedBox(height: AppSpacing.spaceMd),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.spaceMd),
            itemCount: streams.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.spaceMd),
            itemBuilder: (context, index) {
              final stream = streams[index];
              final isSelected = selectedStream?.id == stream.id;
              return _StreamOption(
                stream: stream,
                isSelected: isSelected,
                onTap: () => onSelect(stream),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.spaceMd),
          child: AppButton(
            label: 'Continue',
            variant: AppButtonVariant.primary,
            isFullWidth: true,
            onPressed: selectedStream != null ? onContinue : null,
          ),
        ),
      ],
    );
  }
}

/// One stream option card with selected/unselected states.
class _StreamOption extends StatelessWidget {
  const _StreamOption({
    required this.stream,
    required this.isSelected,
    required this.onTap,
  });

  final StreamModel stream;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.radiusLg),
      child: Semantics(
        label:
            '${streamDisplayName(stream.slug)}, ${isSelected ? "selected" : "not selected"}',
        button: true,
        selected: isSelected,
        excludeSemantics: true,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.colorPrimary.withValues(alpha: 0.1)
                : AppColors.colorSurface,
            borderRadius: BorderRadius.circular(AppRadius.radiusLg),
            border: Border.all(
              color:
                  isSelected ? AppColors.colorPrimary : AppColors.colorBorder,
              width: isSelected ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.spaceMd),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.colorPrimary
                      : AppColors.colorDisabled.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _iconForSlug(stream.slug),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      streamDisplayName(stream.slug),
                      style: AppTypography.typeHeading3,
                    ),
                    const SizedBox(height: AppSpacing.spaceXs),
                    Text(
                      _descriptionForSlug(stream.slug),
                      style: AppTypography.typeCaption,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppColors.colorPrimary,
                  size: AppIconSize.iconSizeLg,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _iconForSlug(String slug) {
  switch (slug) {
    case 'natural_science':
      return '\u{1F52C}';
    case 'social_science':
      return '\u{1F3DB}\u{FE0F}';
    default:
      return '\u{1F4DA}';
  }
}

String _descriptionForSlug(String slug) {
  switch (slug) {
    case 'natural_science':
      return 'Physics, Chemistry, Biology, Mathematics, English, SAT';
    case 'social_science':
      return 'Geography, History, Economics, Mathematics, English, SAT';
    default:
      return '';
  }
}
