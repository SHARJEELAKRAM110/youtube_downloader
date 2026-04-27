const express = require('express');
const router = express.Router();
const { execFile, spawn } = require('child_process');
const contentDisposition = require('content-disposition');
const fs = require('fs');
const path = require('path');
const os = require('os');

// Use 'yt-dlp' directly since it is installed in our Docker PATH
const YT_DLP_CMD = 'yt-dlp';
const YT_DLP_ARGS = [
  // Try to bypass the bot check by using the Android client API
  '--extractor-args', 'youtube:player_client=android,web',
];

// If you add a "Secret File" in Render named "cookies.txt", it mounts it here:
const COOKIES_PATH = '/etc/secrets/cookies.txt';
if (fs.existsSync(COOKIES_PATH)) {
  console.log('Found cookies file, using it for authentication.');
  YT_DLP_ARGS.push('--cookies', COOKIES_PATH);
}

/**
 * Helper: run yt-dlp with given args and return stdout as string
 */
function runYtDlp(args, timeoutMs = 30000) {
  return new Promise((resolve, reject) => {
    const allArgs = [...YT_DLP_ARGS, ...args];
    execFile(YT_DLP_CMD, allArgs, {
      maxBuffer: 10 * 1024 * 1024,
      timeout: timeoutMs,
    }, (error, stdout, stderr) => {
      if (error) {
        console.error('yt-dlp stderr:', stderr);
        reject(new Error(stderr || error.message));
        return;
      }
      resolve(stdout.trim());
    });
  });
}

// GET /api/video/info?url=<youtube_url>
router.get('/info', async (req, res) => {
  try {
    const { url } = req.query;

    if (!url) {
      return res.status(400).json({ error: 'Missing url parameter' });
    }

    // Basic YouTube URL validation
    const ytRegex = /(youtube\.com\/(watch|shorts|embed)|youtu\.be\/)/;
    if (!ytRegex.test(url)) {
      return res.status(400).json({ error: 'Invalid YouTube URL' });
    }

    // Fetch video info as JSON using yt-dlp
    const rawJson = await runYtDlp([
      '--dump-json',
      '--no-playlist',
      '--no-warnings',
      url,
    ]);

    const info = JSON.parse(rawJson);

    // Format duration
    const totalSeconds = info.duration || 0;
    const hours = Math.floor(totalSeconds / 3600);
    const minutes = Math.floor((totalSeconds % 3600) / 60);
    const seconds = totalSeconds % 60;
    const duration = hours > 0
      ? `${hours}:${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`
      : `${minutes}:${String(seconds).padStart(2, '0')}`;

    // Format view count
    const views = info.view_count || 0;
    let viewCount;
    if (views >= 1_000_000_000) viewCount = `${(views / 1_000_000_000).toFixed(1)}B views`;
    else if (views >= 1_000_000) viewCount = `${(views / 1_000_000).toFixed(1)}M views`;
    else if (views >= 1_000) viewCount = `${(views / 1_000).toFixed(1)}K views`;
    else viewCount = `${views} views`;

    // Get best thumbnail
    const thumbnail = info.thumbnail || (info.thumbnails && info.thumbnails.length > 0
      ? info.thumbnails[info.thumbnails.length - 1].url
      : '');

    // Build format list
    const formats = [];
    const allFormats = info.formats || [];

    // 1) Find all available video heights from video-only and combined streams
    const availableHeights = new Set();
    for (const f of allFormats) {
      if (f.vcodec && f.vcodec !== 'none' && f.height && f.height >= 360) {
        availableHeights.add(f.height);
      }
    }

    // 2) First: add combined (video+audio) formats — these download directly without ffmpeg
    const combinedFormats = allFormats
      .filter(f => f.vcodec && f.vcodec !== 'none' && f.acodec && f.acodec !== 'none')
      .sort((a, b) => (b.height || 0) - (a.height || 0));

    const seenQualities = new Set();

    for (const format of combinedFormats) {
      if (!format.height || format.height < 360) continue;
      const quality = `${format.height}p`;
      if (seenQualities.has(quality)) continue;
      seenQualities.add(quality);

      const sizeBytes = format.filesize || format.filesize_approx || null;
      formats.push({
        quality,
        format: format.ext || 'mp4',
        size: sizeBytes ? formatBytes(sizeBytes) : 'Size varies',
        itag: String(format.format_id),
        hasAudio: true,
        hasVideo: true,
      });
    }

    // 3) For heights that exist as video-only but NOT as combined, add them too
    //    These will need special handling (video-only download)
    const targetHeights = [2160, 1440, 1080, 720, 480, 360];
    for (const height of targetHeights) {
      const quality = `${height}p`;
      if (seenQualities.has(quality)) continue;
      if (!availableHeights.has(height)) continue;

      // Find best video-only stream at this height
      const videoOnly = allFormats
        .filter(f => f.height === height && f.vcodec && f.vcodec !== 'none')
        .sort((a, b) => (b.tbr || 0) - (a.tbr || 0))[0];

      if (videoOnly) {
        const sizeBytes = videoOnly.filesize || videoOnly.filesize_approx || null;
        seenQualities.add(quality);
        formats.push({
          quality: `${quality} (video only)`,
          format: videoOnly.ext || 'mp4',
          size: sizeBytes ? formatBytes(sizeBytes) : 'Size varies',
          itag: String(videoOnly.format_id),
          hasAudio: false,
          hasVideo: true,
        });
      }
    }

    // 4) Add best audio-only option
    const audioFormats = allFormats
      .filter(f => (f.vcodec === 'none' || !f.vcodec) && f.acodec && f.acodec !== 'none')
      .sort((a, b) => (b.abr || b.tbr || 0) - (a.abr || a.tbr || 0));

    if (audioFormats.length > 0) {
      const bestAudio = audioFormats[0];
      const sizeBytes = bestAudio.filesize || bestAudio.filesize_approx || null;
      formats.push({
        quality: `${Math.round(bestAudio.abr || bestAudio.tbr || 128)}kbps`,
        format: 'audio',
        size: sizeBytes ? formatBytes(sizeBytes) : 'Size varies',
        itag: 'bestaudio',
        hasAudio: true,
        hasVideo: false,
      });
    } else {
      formats.push({
        quality: '128kbps',
        format: 'audio',
        size: 'Size varies',
        itag: 'bestaudio',
        hasAudio: true,
        hasVideo: false,
      });
    }

    res.json({
      title: info.title || 'Unknown',
      author: info.uploader || info.channel || 'Unknown',
      thumbnail,
      duration,
      viewCount,
      formats,
    });
  } catch (error) {
    console.error('Error fetching video info:', error.message);
    res.status(500).json({
      error: 'Failed to fetch video info: ' + error.message,
    });
  }
});

// GET /api/video/download?url=<youtube_url>&itag=<format_id>
router.get('/download', async (req, res) => {
  try {
    const { url, itag } = req.query;

    if (!url || !itag) {
      return res.status(400).json({ error: 'Missing url or itag parameter' });
    }

    const ytRegex = /(youtube\.com\/(watch|shorts|embed)|youtu\.be\/)/;
    if (!ytRegex.test(url)) {
      return res.status(400).json({ error: 'Invalid YouTube URL' });
    }

    // Get the video title for filename
    let title = 'video';
    try {
      const titleJson = await runYtDlp([
        '--print', '%(title)s',
        '--no-playlist',
        '--no-warnings',
        url,
      ]);
      title = (titleJson || 'video')
        .replace(/[^\w\s-]/g, '')
        .replace(/\s+/g, '_')
        .substring(0, 100);
    } catch (e) {
      // Use default title
    }

    const isAudio = itag === 'bestaudio';
    const extension = isAudio ? 'webm' : 'mp4';
    const filename = `${title}.${extension}`;

    res.header('Content-Disposition', contentDisposition(filename));
    res.header('Content-Type', isAudio ? 'audio/webm' : 'video/mp4');

    // Build yt-dlp command args — stream directly to stdout
    const dlpArgs = [
      '-m', 'yt_dlp',
      '-f', itag,
      '--no-playlist',
      '--no-warnings',
      '--no-check-certificates',
      '-o', '-',
      url,
    ];

    console.log(`Starting download: format=${itag}, url=${url}`);

    const ytdlpProcess = spawn(YT_DLP_CMD, dlpArgs, {
      stdio: ['ignore', 'pipe', 'pipe'],
    });

    ytdlpProcess.stdout.pipe(res);

    ytdlpProcess.stderr.on('data', (data) => {
      const msg = data.toString();
      // Only log real errors, not progress
      if (!msg.includes('[download]') && !msg.includes('ETA')) {
        console.error('yt-dlp stderr:', msg);
      }
    });

    ytdlpProcess.on('error', (err) => {
      console.error('yt-dlp spawn error:', err.message);
      if (!res.headersSent) {
        res.status(500).json({ error: 'Download failed to start' });
      }
    });

    ytdlpProcess.on('close', (code) => {
      if (code !== 0) {
        console.error(`yt-dlp exited with code ${code}`);
        if (!res.headersSent) {
          res.status(500).json({ error: 'Download failed' });
        }
      }
    });

    // Handle client disconnect
    req.on('close', () => {
      ytdlpProcess.kill('SIGTERM');
    });

  } catch (error) {
    console.error('Error downloading video:', error.message);
    if (!res.headersSent) {
      res.status(500).json({ error: 'Failed to download. Please try again.' });
    }
  }
});

function formatBytes(bytes) {
  if (!bytes || bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
}

module.exports = router;
