import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_downloader/models/video_info.dart';
import 'package:youtube_downloader/widgets/glass_card.dart';

class VideoResultCard extends StatelessWidget {
  final VideoInfo videoInfo;
  final Function(String itag, String quality) onDownload;

  const VideoResultCard({
    super.key,
    required this.videoInfo,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video preview
          if (isMobile)
            _buildMobileLayout(isDark)
          else
            _buildDesktopLayout(isDark),

          const SizedBox(height: 28),

          // Quality options header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.download_rounded,
                  color: Color(0xFF6C63FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Available Downloads',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF43E97B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '${videoInfo.formats.length} formats',
                  style: const TextStyle(
                    color: Color(0xFF43E97B),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Format list
          ...videoInfo.formats.asMap().entries.map((entry) {
            final format = entry.value;
            final index = entry.key;
            return _buildFormatTile(format, isDark, index);
          }),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildMobileLayout(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thumbnail
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              videoInfo.thumbnail,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) => Container(
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.05),
                    child: const Icon(
                      Icons.video_library_rounded,
                      size: 48,
                      color: Color(0xFF6C63FF),
                    ),
                  ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildVideoDetails(isDark),
      ],
    );
  }

  Widget _buildDesktopLayout(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thumbnail
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 320,
            height: 180,
            child: Image.network(
              videoInfo.thumbnail,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) => Container(
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.05),
                    child: const Icon(
                      Icons.video_library_rounded,
                      size: 48,
                      color: Color(0xFF6C63FF),
                    ),
                  ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(child: _buildVideoDetails(isDark)),
      ],
    );
  }

  Widget _buildVideoDetails(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          videoInfo.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildInfoChip(
              Icons.person_rounded,
              videoInfo.author,
              isDark,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildInfoChip(
              Icons.access_time_rounded,
              videoInfo.duration,
              isDark,
            ),
            const SizedBox(width: 12),
            _buildInfoChip(
              Icons.visibility_rounded,
              videoInfo.viewCount,
              isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : Colors.black.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatTile(VideoFormat format, bool isDark, int index) {
    final isAudio = !format.hasVideo && format.hasAudio;
    final tileColor =
        isAudio
            ? const Color(0xFFFF6584)
            : const Color(0xFF6C63FF);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => onDownload(format.itag, format.quality),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              children: [
                // Quality icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: tileColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isAudio
                        ? Icons.music_note_rounded
                        : Icons.high_quality_rounded,
                    color: tileColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),

                // Format info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        format.displayLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color:
                              isDark
                                  ? Colors.white
                                  : const Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        format.size,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isDark
                                  ? Colors.white.withValues(alpha: 0.4)
                                  : Colors.black.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),

                // Download button
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [tileColor, tileColor.withValues(alpha: 0.8)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: tileColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.download_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Download',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(
        delay: Duration(milliseconds: 100 * index),
        duration: 400.ms,
      ).slideX(begin: 0.05, end: 0),
    );
  }
}
