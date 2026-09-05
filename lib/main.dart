import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'features/streams/domain/models/stream_model.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/streams/presentation/onboarding_screen.dart';
import 'features/subjects/presentation/subject_list_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: EueePrepApp(),
    ),
  );
}

class EueePrepApp extends StatelessWidget {
  const EueePrepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EUEE Prep',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (_) => const _AppHome(),
            );
          case '/settings':
            return MaterialPageRoute(
              builder: (_) => const SettingsScreen(),
            );
          case '/onboarding':
            return MaterialPageRoute(
              builder: (_) => const OnboardingScreen(),
            );
          case '/subjects':
            return MaterialPageRoute(
              builder: (_) => const SubjectListScreen(),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => const SubjectListScreen(),
            );
        }
      },
    );
  }
}

/// Seeds default streams if they don't exist, then returns null.
final _seedStreamsProvider = FutureProvider<void>((ref) async {
  final streamRepo = ref.read(streamRepositoryProvider);
  final streams = await streamRepo.getAll();
  if (streams.isEmpty) {
    await streamRepo.insert(
      const StreamModel(id: 1, slug: 'natural_science'),
    );
    await streamRepo.insert(
      const StreamModel(id: 2, slug: 'social_science'),
    );
  }
});

/// Routes to OnboardingScreen on first launch (no Preferred Stream),
/// or to SubjectListScreen when a Preferred Stream has been established.
class _AppHome extends ConsumerWidget {
  const _AppHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seedAsync = ref.watch(_seedStreamsProvider);
    return seedAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (_) => const _AppHomeContent(),
    );
  }
}

/// Routes to OnboardingScreen on first launch (no Preferred Stream),
/// or to SubjectListScreen when a Preferred Stream has been established.
class _AppHomeContent extends ConsumerWidget {
  const _AppHomeContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferredStreamAsync = ref.watch(preferredStreamIdProvider);
    return preferredStreamAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (streamId) {
        if (streamId == null) {
          return const OnboardingScreen();
        }
        return const SubjectListScreen();
      },
    );
  }
}
