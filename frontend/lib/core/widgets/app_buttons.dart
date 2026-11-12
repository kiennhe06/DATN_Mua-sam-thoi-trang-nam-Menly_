import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Base rounded button with ripple and a subtle press scale — the single
/// source of truth for the app's button language.
///
/// Flat by design: the system has no shadows on cards or buttons, so depth
/// comes from the ink fill alone.
class _SoftButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;
  final BorderSide? side;
  final bool expanded;
  final double height;

  const _SoftButton({
    required this.child,
    required this.onPressed,
    required this.background,
    required this.foreground,
    this.side,
    this.expanded = true,
    this.height = 54,
  });

  @override
  State<_SoftButton> createState() => _SoftButtonState();
}

class _SoftButtonState extends State<_SoftButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final radius = BorderRadius.circular(AppTheme.radiusXl);

    Widget content = AnimatedScale(
      scale: _down ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.5,
        duration: const Duration(milliseconds: 150),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
          ),
          child: Material(
            color: widget.background,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onPressed,
              onHighlightChanged: (v) => setState(() => _down = v),
              splashColor: widget.foreground.withValues(alpha: 0.12),
              highlightColor: widget.foreground.withValues(alpha: 0.06),
              child: Container(
                height: widget.height,
                alignment: Alignment.center,
                // Dem ngang de nut khong gian het hang (expanded: false) khong
                // bi chu dinh sat mep. Nut gian het hang thi khong doi gi.
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: widget.side != null
                      ? Border.fromBorderSide(widget.side!)
                      : null,
                ),
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: widget.foreground,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  child: IconTheme.merge(
                    data: IconThemeData(color: widget.foreground, size: 20),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final sized = widget.expanded
        ? SizedBox(width: double.infinity, child: content)
        : content;
    return Semantics(button: true, enabled: enabled, container: true, child: sized);
  }
}

/// Filled primary action button (soft rounded rectangle).
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expanded;
  final double height;
  final Color? background;
  final Color? foreground;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expanded = true,
    this.height = 54,
    this.background,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final bg = background ?? c.primary;
    final fg = foreground ?? c.onPrimary;
    return _SoftButton(
      onPressed: loading ? null : onPressed,
      background: bg,
      foreground: fg,
      expanded: expanded,
      height: height,
      child: loading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation(fg),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Flexible(
                  child: Text(label,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
    );
  }
}

/// Outlined / tonal secondary action button.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final double height;
  final Color? foreground; // e.g. c.danger for destructive secondary actions

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = true,
    this.height = 54,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final fg = foreground ?? c.textPrimary;
    return _SoftButton(
      onPressed: onPressed,
      // Luon de nen the trang, ke ca nut canh bao. To nen hong nhat 8% lam
      // nut trong nhu mot khung canh bao bi mo chu khong ra nut bam; mau chu
      // va vien da du de biet day la hanh dong can can nhac.
      background: c.surface,
      foreground: fg,
      side: BorderSide(
        color: foreground != null
            ? foreground!.withValues(alpha: 0.45)
            : c.border,
        width: 1.2,
      ),
      expanded: expanded,
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

/// Circular icon button used in app bars and over images, with press feedback.
class CircleIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? background;
  final Color? foreground;
  final double size;
  final bool bordered;

  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.background,
    this.foreground,
    this.size = 44,
    this.bordered = true,
  });

  @override
  State<CircleIconButton> createState() => _CircleIconButtonState();
}

class _CircleIconButtonState extends State<CircleIconButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AnimatedScale(
      scale: _down ? 0.92 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: Material(
        color: widget.background ?? c.surface,
        shape: CircleBorder(
          side: widget.bordered
              ? BorderSide(color: c.border, width: 1.2)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (v) => setState(() => _down = v),
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Icon(widget.icon,
                size: widget.size * 0.46,
                color: widget.foreground ?? c.textPrimary),
          ),
        ),
      ),
    );
  }
}

/// Red destructive button for actions like delete/cancel.
class DestructiveButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool expanded;
  final double height;

  const DestructiveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expanded = true,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return _SoftButton(
      background: c.danger,
      // onInk sang o ca hai che do nen luon doc duoc tren nen do canh bao
      foreground: c.onInk,
      expanded: expanded,
      height: height,
      onPressed: onPressed,
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
