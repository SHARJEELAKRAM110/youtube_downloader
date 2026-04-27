FROM node:18-alpine

# Install Python, FFmpeg, and pip
RUN apk add --no-cache python3 py3-pip ffmpeg \
    && python3 -m venv /opt/venv \
    && /opt/venv/bin/pip install --no-cache-dir -U "https://github.com/yt-dlp/yt-dlp/archive/master.tar.gz"

# Add venv to PATH so 'python' and 'yt-dlp' commands work
ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3000

CMD ["node", "server.js"]
