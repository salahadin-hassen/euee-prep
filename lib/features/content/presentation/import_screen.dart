import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_button.dart';
import '../../../core/design/tokens.dart';
import '../../../core/providers.dart';

/// Screen for importing a published content pack (ZIP containing
/// content-pack.json).
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  bool _isImporting = false;
  String? _importingLabel;
  String? _error;
  _ImportSuccess? _success;

  Future<void> _pickAndImport() async {
    setState(() {
      _isImporting = true;
      _error = null;
      _success = null;
      _importingLabel = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip', 'json'],
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isImporting = false);
        return;
      }

      final file = result.files.single;
      String jsonContent;

      if (file.extension == 'zip') {
        final bytes = await File(file.path!).readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);
        final packFile = archive.files.firstWhere(
          (f) => f.name == 'content-pack.json',
          orElse: () => throw Exception(
            'ZIP does not contain content-pack.json',
          ),
        );
        jsonContent = String.fromCharCodes(packFile.content as List<int>);
      } else {
        jsonContent = await File(file.path!).readAsString();
      }

      // Extract a preview label before full import.
      final importService = ref.read(contentImportServiceProvider);
      setState(() {
        _importingLabel = 'Importing...';
      });

      final result2 = await importService.import(jsonContent);

      if (!mounted) return;

      if (result2.isSuccess) {
        final pack = result2.pack!;
        // Count questions from the pack metadata if available.
        final questionCount = result2.issues.isEmpty ? null : null;
        setState(() {
          _success = _ImportSuccess(
            subjectTitle: pack.id.split('-').first,
            packId: pack.packKey,
            questionCount: questionCount,
          );
          _isImporting = false;
          _importingLabel = null;
        });
        ref.invalidate(preferredStreamIdProvider);
      } else {
        final msg = result2.issues.map((i) => i.message).join('\n');
        setState(() {
          _error = msg.isEmpty ? 'Import failed. Please try again.' : msg;
          _isImporting = false;
          _importingLabel = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      // Strip "Exception: " prefix for cleaner display.
      final cleanMsg = msg.startsWith('Exception: ')
          ? msg.substring('Exception: '.length)
          : msg;
      setState(() {
        _error = cleanMsg;
        _isImporting = false;
        _importingLabel = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: AppBar(
        backgroundColor: AppColors.colorBackground,
        elevation: 0,
        title: const Text('Import Content', style: AppTypography.typeHeading3),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.spaceLg),
              if (_isImporting) ...[
                const SizedBox(height: AppSpacing.spaceXl),
                const Icon(
                  Icons.hourglass_top_outlined,
                  size: AppIconSize.iconSizeXl,
                  color: AppColors.colorPrimary,
                ),
                const SizedBox(height: AppSpacing.spaceMd),
                Text(
                  _importingLabel ?? 'Importing...',
                  style: AppTypography.typeHeading3,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.spaceMd),
                const LinearProgressIndicator(),
              ] else ...[
                const Icon(
                  Icons.file_download_outlined,
                  size: AppIconSize.iconSizeXl,
                  color: AppColors.colorTextSecondary,
                ),
                const SizedBox(height: AppSpacing.spaceMd),
                const Text(
                  'Import a content pack',
                  style: AppTypography.typeHeading3,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.spaceSm),
                const Text(
                  'Select a .zip or .json file exported from Content Studio.',
                  style: AppTypography.typeBody,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.spaceLg),
                AppButton(
                  label: 'Choose File',
                  isFullWidth: true,
                  onPressed: _pickAndImport,
                ),
              ],
              const SizedBox(height: AppSpacing.spaceLg),
              if (_success != null) _buildSuccess(),
              if (_error != null) _buildError(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.colorSuccess.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
        border: Border.all(color: AppColors.colorSuccess.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: AppColors.colorSuccess, size: 32),
          const SizedBox(height: AppSpacing.spaceSm),
          Text(
            '${_success!.subjectTitle} imported',
            style: AppTypography.typeHeading3
                .copyWith(color: AppColors.colorSuccess),
          ),
          const SizedBox(height: AppSpacing.spaceXs),
          Text(
            _success!.packId,
            style: AppTypography.typeCaption,
          ),
          const SizedBox(height: AppSpacing.spaceSm),
          const Text(
            'Available offline.',
            style: AppTypography.typeBody,
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.colorError.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
        border: Border.all(color: AppColors.colorError.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.colorError, size: 32),
          const SizedBox(height: AppSpacing.spaceSm),
          const Text('Import failed', style: AppTypography.typeHeading3),
          const SizedBox(height: AppSpacing.spaceXs),
          Text(
            _error!,
            style: AppTypography.typeCaption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.spaceMd),
          AppButton(
            label: 'Try Again',
            isFullWidth: true,
            onPressed: _pickAndImport,
          ),
        ],
      ),
    );
  }
}

class _ImportSuccess {
  const _ImportSuccess({
    required this.subjectTitle,
    required this.packId,
    this.questionCount,
  });
  final String subjectTitle;
  final String packId;
  final int? questionCount;
}
