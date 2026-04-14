import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Professional button widget with hover effects, shadows, and individual loading states
class ProfessionalButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool enabled;
  final ButtonStyle? style;
  final double width;
  final double height;
  final IconData? icon;
  final bool showHoverEffect;
  final Color? loadingIndicatorColor;

  const ProfessionalButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.style,
    this.width = double.infinity,
    this.height = 48,
    this.icon,
    this.showHoverEffect = true,
    this.loadingIndicatorColor = Colors.white,
  });

  @override
  State<ProfessionalButton> createState() => _ProfessionalButtonState();
}

class _ProfessionalButtonState extends State<ProfessionalButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (widget.enabled && !widget.isLoading) {
          setState(() => _isHovered = true);
        }
      },
      onExit: (_) {
        setState(() => _isHovered = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: widget.showHoverEffect && _isHovered && widget.enabled
              ? [
                  BoxShadow(
                    color: AppTheme.royalBlue.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                    spreadRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: ElevatedButton(
            style:
                widget.style ??
                ElevatedButton.styleFrom(
                  backgroundColor: widget.enabled
                      ? (_isHovered
                            ? AppTheme.royalBlue.withValues(alpha: 0.95)
                            : AppTheme.royalBlue)
                      : Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.zero,
                ),
            onPressed: (widget.enabled && !widget.isLoading)
                ? widget.onPressed
                : null,
            child: widget.isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.loadingIndicatorColor ?? Colors.white,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Secondary professional button with outline style
class ProfessionalOutlineButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool enabled;
  final double width;
  final double height;
  final IconData? icon;
  final Color? primaryColor;
  final Widget? loadingChild;

  const ProfessionalOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.width = double.infinity,
    this.height = 48,
    this.icon,
    this.primaryColor = AppTheme.royalBlue,
    this.loadingChild,
  });

  @override
  State<ProfessionalOutlineButton> createState() =>
      _ProfessionalOutlineButtonState();
}

class _ProfessionalOutlineButtonState extends State<ProfessionalOutlineButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (widget.enabled && !widget.isLoading) {
          setState(() => _isHovered = true);
        }
      },
      onExit: (_) {
        setState(() => _isHovered = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: _isHovered && widget.enabled
              ? [
                  BoxShadow(
                    color: (widget.primaryColor ?? AppTheme.royalBlue)
                        .withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: widget.primaryColor ?? AppTheme.royalBlue,
              side: BorderSide(
                color: widget.primaryColor ?? AppTheme.royalBlue,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.zero,
              backgroundColor: _isHovered && widget.enabled
                  ? (widget.primaryColor ?? AppTheme.royalBlue).withValues(alpha: 
                      0.05,
                    )
                  : Colors.transparent,
            ),
            onPressed: (widget.enabled && !widget.isLoading)
                ? widget.onPressed
                : null,
            child: widget.isLoading
                ? widget.loadingChild ??
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.primaryColor ?? AppTheme.royalBlue,
                          ),
                        ),
                      )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Icon button with professional styling and hover effects
class ProfessionalIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool enabled;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final String? tooltip;

  const ProfessionalIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.backgroundColor = AppTheme.royalBlue,
    this.iconColor = Colors.white,
    this.size = 48,
    this.tooltip,
  });

  @override
  State<ProfessionalIconButton> createState() => _ProfessionalIconButtonState();
}

class _ProfessionalIconButtonState extends State<ProfessionalIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final child = MouseRegion(
      onEnter: (_) {
        if (widget.enabled && !widget.isLoading) {
          setState(() => _isHovered = true);
        }
      },
      onExit: (_) {
        setState(() => _isHovered = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.enabled ? widget.backgroundColor : Colors.grey.shade300,
          boxShadow: widget.enabled && _isHovered
              ? [
                  BoxShadow(
                    color: (widget.backgroundColor ?? AppTheme.royalBlue)
                        .withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: (widget.enabled && !widget.isLoading)
                ? widget.onPressed
                : null,
            customBorder: const CircleBorder(),
            child: widget.isLoading
                ? Center(
                    child: SizedBox(
                      width: widget.size * 0.5,
                      height: widget.size * 0.5,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.iconColor ?? Colors.white,
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Icon(
                      widget.icon,
                      color: widget.iconColor,
                      size: widget.size * 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip, child: child);
    }

    return child;
  }
}
