const express = require('express');
const cors = require('cors');
const videoRoutes = require('./routes/video');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST'],
  allowedHeaders: ['Content-Type'],
}));
app.use(express.json());

// Health check
app.get('/', (req, res) => {
  res.json({
    status: 'ok',
    message: '🎬 VidGrab API is running!',
    version: '1.0.0',
  });
});

// Video routes
app.use('/api/video', videoRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Server Error:', err.message);
  res.status(500).json({
    error: 'Internal server error',
    message: err.message,
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`\n🎬 VidGrab Server running on port ${PORT}`);
  console.log(`   Health: http://localhost:${PORT}/`);
  console.log(`   API:    http://localhost:${PORT}/api/video/info?url=<youtube_url>\n`);
});
