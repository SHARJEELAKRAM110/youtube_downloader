import 'package:flutter/material.dart';
import 'package:youtube_downloader/models/video_info.dart';
import 'package:youtube_downloader/services/api_service.dart';

enum DownloadStatus { idle, loading, loaded, downloading, error }

class DownloadProvider extends ChangeNotifier {
  DownloadStatus _status = DownloadStatus.idle;
  VideoInfo? _videoInfo;
  String _errorMessage = '';
  String _currentUrl = '';
  final List<DownloadHistoryItem> _history = [];

  DownloadStatus get status => _status;
  VideoInfo? get videoInfo => _videoInfo;
  String get errorMessage => _errorMessage;
  String get currentUrl => _currentUrl;
  List<DownloadHistoryItem> get history => _history;

  Future<void> fetchVideoInfo(String url) async {
    if (url.trim().isEmpty) {
      _errorMessage = 'Please enter a YouTube URL';
      _status = DownloadStatus.error;
      notifyListeners();
      return;
    }

    if (!_isValidYouTubeUrl(url)) {
      _errorMessage = 'Please enter a valid YouTube URL';
      _status = DownloadStatus.error;
      notifyListeners();
      return;
    }

    _status = DownloadStatus.loading;
    _currentUrl = url.trim();
    _errorMessage = '';
    notifyListeners();

    try {
      _videoInfo = await ApiService.fetchVideoInfo(_currentUrl);
      _status = DownloadStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status = DownloadStatus.error;
    }
    notifyListeners();
  }

  String getDownloadUrl(String itag) {
    return ApiService.getDownloadUrl(_currentUrl, itag);
  }

  void addToHistory(String title, String thumbnail, String quality) {
    _history.insert(
      0,
      DownloadHistoryItem(
        title: title,
        thumbnail: thumbnail,
        quality: quality,
        downloadedAt: DateTime.now().toString().substring(0, 16),
      ),
    );
    notifyListeners();
  }

  void reset() {
    _status = DownloadStatus.idle;
    _videoInfo = null;
    _errorMessage = '';
    _currentUrl = '';
    notifyListeners();
  }

  bool _isValidYouTubeUrl(String url) {
    final patterns = [
      RegExp(r'(youtube\.com/watch\?v=)'),
      RegExp(r'(youtu\.be/)'),
      RegExp(r'(youtube\.com/shorts/)'),
      RegExp(r'(youtube\.com/embed/)'),
    ];
    return patterns.any((pattern) => pattern.hasMatch(url));
  }
}
