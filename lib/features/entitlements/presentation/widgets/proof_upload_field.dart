import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';

/// Screenshot attach field for the Submit Proof step.
///
/// TODO(integration): This currently MOCKS the attach interaction —
/// tapping the empty state just flips [isAttached] via [onTap] rather
/// than opening a real OS image picker. No image_picker (or similar)
/// package exists in this project yet, and adding packages requires
/// approval per the AI Development Rules. When approved, replace the
/// onTap mock with a real picker call and pass the actual selected
/// image into a thumbnail preview here — the empty/filled visual states
/// below are already built to support that swap without restructuring.
class ProofUploadField extends StatelessWidget {
  const ProofUploadField({
    super.key,
    required this.isAttached,
    required this.onTap,
    required this.onRemove,
  });

  final bool isAttached;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    if (isAttached) {
      return Semantics(
        label: 'Payment screenshot attached',
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.colorSurface,
            borderRadius: BorderRadius.circular(AppRadius.radiusMd),
            border: Border.all(color: AppColors.colorBorder),
          ),
          height: 160,
          child: Stack(
            children: [
              const Center(
                child: Icon(
                  Icons.image_outlined,
                  size: AppIconSize.iconSizeXl,
                  color: AppColors.colorTextSecondary,
                ),
              ),
              Positioned(
                top: AppSpacing.spaceXs,
                right: AppSpacing.spaceXs,
                child: Semantics(
                  button: true,
                  label: 'Remove screenshot',
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onRemove,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.colorSurface,
                      minimumSize: const Size(48, 48),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      label: 'No screenshot attached. Double tap to add screenshot.',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.radiusMd),
            border: Border.all(
              color: AppColors.colorBorder,
              style: BorderStyle.solid,
              width: AppStroke.strokeThin,
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: AppIconSize.iconSizeLg,
                  color: AppColors.colorTextSecondary,
                ),
                SizedBox(height: AppSpacing.spaceXs),
                Text('Add Screenshot', style: AppTypography.typeBody),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
