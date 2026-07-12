import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens.dart';

/// Generic tap-to-copy field: shows a [label] (e.g. "Request ID",
/// "Telebirr Number") and a [value], with a copy icon that swaps to a
/// checkmark briefly after copying.
///
/// This consolidates copy-button behavior previously duplicated between
/// Payment History's RequestIdRow and the Payment Submission flow's
/// payment-instructions number field — per the design review note to
/// never maintain two copy-button implementations.
class CopyableField extends StatefulWidget {
  const CopyableField({
    super.key,
    required this.value,
    this.label,
    this.valueStyle,
    this.semanticLabel,
  });

  final String value;
  final String? label;
  final TextStyle? valueStyle;

  /// Overrides the default "$label $value. Double tap to copy."
  /// semantic announcement, for callers with a more natural phrasing.
  final String? semanticLabel;

  @override
  State<CopyableField> createState() => _CopyableFieldState();
}

class _CopyableFieldState extends State<CopyableField> {
  bool _justCopied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.value));
    if (!mounted) return;
    setState(() => _justCopied = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.label ?? 'Value'} copied')),
    );

    await Future<void>.delayed(AppDuration.durationSlow);
    if (mounted) setState(() => _justCopied = false);
  }

  @override
  Widget build(BuildContext context) {
    final defaultSemantics =
        '${widget.label ?? ''} ${widget.value}. Double tap to copy.'.trim();

    return Semantics(
      button: true,
      label: widget.semanticLabel ?? defaultSemantics,
      excludeSemantics: true,
      child: InkWell(
        onTap: _copy,
        borderRadius: BorderRadius.circular(AppRadius.radiusSm),
        child: Padding(
          // Ensures a >=48dp tap target regardless of visible text size.
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.spaceSm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.label != null) ...[
                Text(widget.label!, style: AppTypography.typeCaption),
                const SizedBox(width: AppSpacing.spaceXs),
              ],
              Text(
                widget.value,
                style: widget.valueStyle ?? AppTypography.typeBody,
              ),
              const SizedBox(width: AppSpacing.spaceXs),
              Icon(
                _justCopied ? Icons.check : Icons.copy_outlined,
                size: AppIconSize.iconSizeSm,
                color: AppColors.colorTextSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
