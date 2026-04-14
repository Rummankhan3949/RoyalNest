import 'package:flutter/material.dart';

/// Professional Google Sign-In button with authentic Google branding
/// Reusable button component for Google authentication flows
/// Supports loading states and custom labels with hover effects
class GoogleSignInButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final bool enabled;
  final String label;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.label = 'Continue with Google',
  });

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
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
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isHovered && widget.enabled
                ? Colors.grey.shade400
                : const Color(0xFFDADCE0),
            width: 1,
          ),
          color: widget.isLoading
              ? Colors.grey.shade100
              : (_isHovered && widget.enabled
                    ? Colors.grey.shade50
                    : Colors.white),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: (widget.enabled && !widget.isLoading)
                  ? widget.onPressed
                  : null,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.isLoading)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.grey.shade700,
                          ),
                        ),
                      )
                    else
                      _buildGoogleLogoImage(),
                    const SizedBox(width: 12),
                    Text(
                      widget.isLoading ? 'Signing in...' : widget.label,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build Google logo image with fallback
  /// Tries custom PNG first, then bundled logo, then vector fallback
  Widget _buildGoogleLogoImage() {
    return Image.asset(
      'assets/google_logo.png',
      width: 28,
      height: 28,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _buildGoogleLogo(),
    );
  }

  /// Build authentic Google logo using colored circles
  /// Matches Google's official branding colors
  /// Used as fallback when image assets are unavailable
  Widget _buildGoogleLogo() {
    return SizedBox(
      width: 20,
      height: 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Blue dot (top-left)
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF4285F4), // Google Blue
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Red dot (top-right)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFEA4335), // Google Red
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Yellow dot (bottom-left)
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFFBBC04), // Google Yellow
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Blue dot (bottom-right)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF34A853), // Google Green
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
