class VideoInfo {
  final String title;
  final String author;
  final String thumbnail;
  final String duration;
  final String viewCount;
  final List<VideoFormat> formats;

  VideoInfo({
    required this.title,
    required this.author,
    required this.thumbnail,
    required this.duration,
    required this.viewCount,
    required this.formats,
  });

  factory VideoInfo.fromJson(Map<String, dynamic> json) {
    return VideoInfo(
      title: json['title'] ?? 'Unknown',
      author: json['author'] ?? 'Unknown',
      thumbnail: json['thumbnail'] ?? '',
      duration: json['duration'] ?? '0:00',
      viewCount: json['viewCount'] ?? '0',
      formats: (json['formats'] as List<dynamic>?)
              ?.map((f) => VideoFormat.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class VideoFormat {
  final String quality;
  final String format;
  final String size;
  final String itag;
  final bool hasAudio;
  final bool hasVideo;

  VideoFormat({
    required this.quality,
    required this.format,
    required this.size,
    required this.itag,
    required this.hasAudio,
    required this.hasVideo,
  });

  factory VideoFormat.fromJson(Map<String, dynamic> json) {
    return VideoFormat(
      quality: json['quality'] ?? 'Unknown',
      format: json['format'] ?? 'mp4',
      size: json['size'] ?? 'Unknown',
      itag: json['itag']?.toString() ?? '',
      hasAudio: json['hasAudio'] ?? false,
      hasVideo: json['hasVideo'] ?? true,
    );
  }

  String get displayLabel {
    if (!hasVideo && hasAudio) return '🎵 Audio Only ($quality)';
    if (hasVideo && !hasAudio) return '📹 $quality';
    return '📹 $quality ($format)';
  }
}

class DownloadHistoryItem {
  final String title;
  final String thumbnail;
  final String quality;
  final String downloadedAt;

  DownloadHistoryItem({
    required this.title,
    required this.thumbnail,
    required this.quality,
    required this.downloadedAt,
  });
}
