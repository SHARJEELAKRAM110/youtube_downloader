import 'package:flutter/material.dart';
import 'package:youtube_downloader/widgets/glass_card.dart';

class UrlInputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const UrlInputBar({
    super.key,
    required this.controller,
    required this.onSubmit,
  });

  @override
  State<UrlInputBar> createState() => _UrlInputBarState();
}

class _UrlInputBarState extends State<UrlInputBar> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow:
            _isFocused
                ? [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ]
                : [],
      ),
      child: GlassCard(
        borderRadius: 20,
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFFFF6584)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.link_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Input field
            Expanded(
              child: Focus(
                onFocusChange: (focused) {
                  setState(() => _isFocused = focused);
                },
                child: TextField(
                  controller: widget.controller,
                  onSubmitted: (_) => widget.onSubmit(),
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Paste YouTube URL here...',
                    hintStyle: TextStyle(
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.3),
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Clear button
            if (widget.controller.text.isNotEmpty)
              IconButton(
                onPressed: () {
                  widget.controller.clear();
                  setState(() {});
                },
                icon: Icon(
                  Icons.close_rounded,
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.4)
                          : Colors.black.withValues(alpha: 0.4),
                  size: 20,
                ),
              ),

            // Download button
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: widget.onSubmit,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 28,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFFFF6584)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.download_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      if (!isMobile) ...[
                        const SizedBox(width: 8),
                        const Text(
                          'Get Video',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
