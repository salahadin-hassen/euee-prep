import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';
import '../models/study_resource_ui_model.dart';

class _ResourceTypeConfig {
  const _ResourceTypeConfig({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

const _resourceTypeConfigs = {
  StudyResourceType.notes: _ResourceTypeConfig(
    icon: Icons.description_outlined,
    title: 'Notes',
    description: 'Short explanations',
  ),
  StudyResourceType.flashcards: _ResourceTypeConfig(
    icon: Icons.style_outlined,
    title: 'Flashcards',
    description: 'Quick recall practice',
  ),
  StudyResourceType.mindMap: _ResourceTypeConfig(
    icon: Icons.account_tree_outlined,
    title: 'Mind Map',
    description: 'Visual concept overview',
  ),
};

/// One of the three neutral resource-type cards (Notes, Flashcards,
/// Mind Map). Same card language as SubjectCard/PaymentRequestCard for
/// visual consistency across the app.
///
/// When [resource.isAvailable] is false, the card renders muted and
/// non-interactive — a missing resource type is an expected content
/// state (Decision 015/021: content only changes via pack updates),
/// not an error, so the card stays visible rather than disappearing.
class StudyResourceCard extends StatelessWidget {
  const StudyResourceCard({
    super.key,
    required this.resource,
    required this.onTap,
  });

  final StudyResourceUiModel resource;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final config = _resourceTypeConfigs[resource.type]!;
    final isAvailable = resource.isAvailable;

    final content = Container(
      decoration: BoxDecoration(
        color: AppColors.colorSurface,
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
        border: Border.all(color: AppColors.colorBorder),
      ),
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Row(
        children: [
          Icon(
            config.icon,
            size: AppIconSize.iconSizeLg,
            color:
                isAvailable ? AppColors.colorPrimary : AppColors.colorDisabled,
          ),
          const SizedBox(width: AppSpacing.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.title,
                  style: AppTypography.typeHeading3.copyWith(
                    color: isAvailable
                        ? AppColors.colorTextPrimary
                        : AppColors.colorTextSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.spaceXs),
                Text(
                  isAvailable ? config.description : 'Not available yet',
                  style: AppTypography.typeCaption,
                ),
              ],
            ),
          ),
          if (isAvailable && resource.count != null)
            Text('${resource.count}', style: AppTypography.typeCaption),
        ],
      ),
    );

    final semanticLabel = isAvailable
        ? '${config.title}${resource.count != null ? ', ${resource.count} items' : ''}. Double tap to open.'
        : '${config.title}, not available yet.';

    return Semantics(
      label: semanticLabel,
      button: isAvailable,
      excludeSemantics: true,
      child: isAvailable
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.radiusMd),
              child: content,
            )
          : content,
    );
  }
}
