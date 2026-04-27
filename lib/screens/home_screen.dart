import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_downloader/providers/download_provider.dart';
import 'package:youtube_downloader/providers/theme_provider.dart';
import 'package:youtube_downloader/widgets/animated_background.dart';
import 'package:youtube_downloader/widgets/feature_card.dart';
import 'package:youtube_downloader/widgets/glass_card.dart';
import 'package:youtube_downloader/widgets/url_input_bar.dart';
import 'package:youtube_downloader/widgets/video_result_card.dart';
import 'package:youtube_downloader/widgets/history_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _urlController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final downloadProvider = Provider.of<DownloadProvider>(context);
    final isDark = themeProvider.isDark;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;

    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          const AnimatedBackground(),

          // Main content
          SafeArea(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // App Bar
                SliverToBoxAdapter(
                  child: _buildAppBar(isDark, themeProvider),
                ),

                // Hero Section
                SliverToBoxAdapter(
                  child: _buildHeroSection(isDark, isMobile),
                ),

                // URL Input
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 20 : size.width * 0.15,
                    ),
                    child: UrlInputBar(
                      controller: _urlController,
                      onSubmit: () {
                        downloadProvider.fetchVideoInfo(
                          _urlController.text,
                        );
                      },
                    ),
                  )
                      .animate()
                      .fadeIn(
                        delay: 400.ms,
                        duration: 600.ms,
                      )
                      .slideY(begin: 0.2, end: 0),
                ),

                // Error Message
                if (downloadProvider.status == DownloadStatus.error)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 20 : size.width * 0.15,
                        vertical: 16,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                downloadProvider.errorMessage,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().shake(),
                    ),
                  ),

                // Loading Shimmer
                if (downloadProvider.status == DownloadStatus.loading)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 20 : size.width * 0.15,
                        vertical: 32,
                      ),
                      child: _buildLoadingShimmer(isDark),
                    ),
                  ),

                // Video Result
                if (downloadProvider.status == DownloadStatus.loaded &&
                    downloadProvider.videoInfo != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 20 : size.width * 0.15,
                        vertical: 32,
                      ),
                      child: VideoResultCard(
                        videoInfo: downloadProvider.videoInfo!,
                        onDownload: (itag, quality) {
                          final url = downloadProvider.getDownloadUrl(itag);
                          launchUrl(Uri.parse(url));
                          downloadProvider.addToHistory(
                            downloadProvider.videoInfo!.title,
                            downloadProvider.videoInfo!.thumbnail,
                            quality,
                          );
                        },
                      ),
                    ),
                  ),

                // Features Section
                if (downloadProvider.status == DownloadStatus.idle)
                  SliverToBoxAdapter(
                    child: _buildFeaturesSection(isDark, isMobile, size),
                  ),

                // History Section
                if (downloadProvider.history.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 20 : size.width * 0.15,
                        vertical: 32,
                      ),
                      child: const HistorySection(),
                    ),
                  ),

                // Footer
                SliverToBoxAdapter(
                  child: _buildFooter(isDark),
                ),

                // Bottom spacing
                const SliverToBoxAdapter(
                  child: SizedBox(height: 40),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isDark, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.all(10),
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
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'VidGrab',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          const Spacer(),

          // Theme toggle
          GlassCard(
            borderRadius: 12,
            padding: EdgeInsets.zero,
            child: IconButton(
              onPressed: themeProvider.toggleTheme,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return RotationTransition(
                    turns: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  key: ValueKey(isDark),
                  color: isDark ? Colors.amber : const Color(0xFF6C63FF),
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3, end: 0);
  }

  Widget _buildHeroSection(bool isDark, bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: isMobile ? 40 : 60,
      ),
      child: Column(
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6C63FF).withValues(alpha: 0.15),
                  const Color(0xFFFF6584).withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF43E97B),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '✨ Free & Unlimited Downloads',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF6C63FF)
                        : const Color(0xFF6C63FF),
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: 200.ms)
              .scale(begin: const Offset(0.8, 0.8)),

          const SizedBox(height: 24),

          // Title
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Color(0xFF6C63FF),
                Color(0xFFFF6584),
                Color(0xFF43E97B),
              ],
            ).createShader(bounds),
            child: Text(
              'Download YouTube Videos',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: isMobile ? 36 : 56,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.1,
              ),
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 600.ms).slideY(
                begin: 0.2,
                end: 0,
              ),

          const SizedBox(height: 8),

          Text(
            'In Any Quality',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: isMobile ? 36 : 56,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              height: 1.1,
            ),
          ).animate().fadeIn(delay: 350.ms, duration: 600.ms).slideY(
                begin: 0.2,
                end: 0,
              ),

          const SizedBox(height: 20),

          // Subtitle
          Text(
            'Paste a YouTube link and download videos in 1080p, 720p, 480p\nor extract audio as MP3. Fast, free, no registration.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 15 : 17,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.black.withValues(alpha: 0.5),
              height: 1.6,
            ),
          ).animate().fadeIn(delay: 450.ms, duration: 600.ms),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer(bool isDark) {
    return GlassCard(
      child: Column(
        children: [
          // Thumbnail shimmer
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
          ).animate(onPlay: (c) => c.repeat()).shimmer(
                duration: 1500.ms,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
              ),
          const SizedBox(height: 20),
          // Title shimmer
          Container(
            height: 24,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
          ).animate(onPlay: (c) => c.repeat()).shimmer(
                duration: 1500.ms,
                delay: 200.ms,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
              ),
          const SizedBox(height: 12),
          Container(
            height: 16,
            width: 200,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
          ).animate(onPlay: (c) => c.repeat()).shimmer(
                duration: 1500.ms,
                delay: 400.ms,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
              ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildFeaturesSection(bool isDark, bool isMobile, Size size) {
    final features = [
      {
        'icon': Icons.high_quality_rounded,
        'title': 'Multiple Qualities',
        'desc': 'Download in 1080p, 720p, 480p, or 360p',
        'gradient': [const Color(0xFF6C63FF), const Color(0xFF4834D4)],
      },
      {
        'icon': Icons.music_note_rounded,
        'title': 'Audio Extract',
        'desc': 'Extract audio as high-quality MP3',
        'gradient': [const Color(0xFFFF6584), const Color(0xFFFF4757)],
      },
      {
        'icon': Icons.bolt_rounded,
        'title': 'Lightning Fast',
        'desc': 'Powered by high-speed servers',
        'gradient': [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
      },
      {
        'icon': Icons.lock_rounded,
        'title': 'No Registration',
        'desc': 'Start downloading without sign-up',
        'gradient': [const Color(0xFFFFA726), const Color(0xFFFF7043)],
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : size.width * 0.15,
        vertical: 40,
      ),
      child: Column(
        children: [
          Text(
            'Why VidGrab?',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ).animate().fadeIn(delay: 500.ms),
          const SizedBox(height: 32),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: features.asMap().entries.map((entry) {
              return SizedBox(
                width: isMobile ? double.infinity : 260,
                child: FeatureCard(
                  icon: entry.value['icon'] as IconData,
                  title: entry.value['title'] as String,
                  description: entry.value['desc'] as String,
                  gradient: entry.value['gradient'] as List<Color>,
                )
                    .animate()
                    .fadeIn(
                      delay: Duration(milliseconds: 600 + entry.key * 150),
                      duration: 500.ms,
                    )
                    .slideY(begin: 0.3, end: 0),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

//sharjeel
  Widget _buildFooter(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          Divider(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 20),
          Text(
            'Built with 💜 by SHARJEEL',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '© ${DateTime.now().year} VidGrab. For personal use only.',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}
