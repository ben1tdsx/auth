import express from 'express';
import path from 'path';
import fs from 'fs/promises';
import { createReadStream } from 'fs';
import axios from 'axios';
import cookieParser from 'cookie-parser';
import { exec } from 'child_process';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = process.env.PORT || 3001;
const NODE_ENV = process.env.NODE_ENV || 'development';

// Configuration
const AUTH_SERVICE_URL = process.env.AUTH_SERVICE_URL || 'http://localhost:3000';
const PROTECTED_DIR = process.env.PROTECTED_DIR || path.join(__dirname, '../../node_access_control');

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());

// Serve static files from dist (production) or public (fallback)
const distPath = path.join(__dirname, 'dist');
const publicPath = path.join(__dirname, 'public');

// Check if dist exists (production build) - will be set in start()
let distExists = false;

// Ensure protected directory exists
async function ensureProtectedDir() {
  try {
    await fs.access(PROTECTED_DIR);
  } catch (error) {
    console.log(`Creating protected directory: ${PROTECTED_DIR}`);
    await fs.mkdir(PROTECTED_DIR, { recursive: true });
  }
}

// Check if user is authenticated by validating session cookie
async function checkAuth(req) {
  const sessionId = req.cookies.sessionId;
  if (!sessionId) {
    return null;
  }

  try {
    const response = await axios.get(`${AUTH_SERVICE_URL}/auth/validate`, {
      headers: {
        Cookie: `sessionId=${sessionId}`
      },
      validateStatus: () => true // Don't throw on any status
    });

    if (response.status === 200 && response.data.valid) {
      return response.data.username;
    }
    return null;
  } catch (error) {
    console.error('Auth check error:', error.message);
    return null;
  }
}

// Middleware to require authentication
async function requireAuth(req, res, next) {
  const username = await checkAuth(req);
  if (!username) {
    return res.status(401).json({
      error: 'Unauthorized',
      redirect: '/login'
    });
  }
  req.username = username;
  next();
}

// Handle login
app.post('/api/login', async (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).json({
      success: false,
      message: 'Username and password are required'
    });
  }

  try {
    const response = await axios.post(`${AUTH_SERVICE_URL}/login`, {
      username,
      password
    }, {
      validateStatus: () => true
    });

    if (response.status === 200) {
      // Extract session cookie from response
      const setCookieHeader = response.headers['set-cookie'];
      if (setCookieHeader) {
        // Parse the cookie and set it in the response
        const cookieMatch = setCookieHeader[0].match(/sessionId=([^;]+)/);
        if (cookieMatch) {
          res.cookie('sessionId', cookieMatch[1], {
            httpOnly: true,
            secure: NODE_ENV === 'production',
            sameSite: 'lax',
            maxAge: 24 * 60 * 60 * 1000 // 24 hours
          });
        }
      }

      return res.json({
        success: true,
        message: 'Login successful',
        username: response.data.username
      });
    } else {
      return res.status(401).json({
        success: false,
        message: response.data.message || 'Invalid username or password'
      });
    }
  } catch (error) {
    console.error('Login error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Error connecting to authentication service'
    });
  }
});

// Logout
app.post('/logout', async (req, res) => {
  const sessionId = req.cookies.sessionId;
  
  if (sessionId) {
    try {
      await axios.post(`${AUTH_SERVICE_URL}/logout`, {}, {
        headers: {
          Cookie: `sessionId=${sessionId}`
        },
        validateStatus: () => true
      });
    } catch (error) {
      console.error('Logout error:', error.message);
    }
  }

  res.clearCookie('sessionId');
  res.json({ success: true, message: 'Logged out successfully' });
});

// API: Get current user info
app.get('/api/user', requireAuth, async (req, res) => {
  res.json({
    username: req.username
  });
});

// API: Get directory listing
app.get('/api/files', requireAuth, async (req, res) => {
  try {
    const requestedPath = req.query.path || '/';
    const fullPath = path.join(PROTECTED_DIR, requestedPath);
    
    // Security: Ensure path is within protected directory
    const resolvedPath = path.resolve(fullPath);
    const resolvedProtectedDir = path.resolve(PROTECTED_DIR);
    
    if (!resolvedPath.startsWith(resolvedProtectedDir)) {
      return res.status(403).json({
        error: 'Access denied'
      });
    }

    const stats = await fs.stat(resolvedPath);
    
    if (stats.isDirectory()) {
      const entries = await fs.readdir(resolvedPath);
      const files = [];

      for (const entry of entries) {
        const entryPath = path.join(resolvedPath, entry);
        const entryStats = await fs.stat(entryPath);
        
        files.push({
          name: entry,
          type: entryStats.isDirectory() ? 'directory' : 'file',
          size: entryStats.isFile() ? entryStats.size : null,
          modified: entryStats.mtime.toISOString(),
          path: path.join(requestedPath, entry).replace(/\\/g, '/')
        });
      }

      // Sort: directories first, then files, both alphabetically
      files.sort((a, b) => {
        if (a.type !== b.type) {
          return a.type === 'directory' ? -1 : 1;
        }
        return a.name.localeCompare(b.name);
      });

      res.json({
        path: requestedPath,
        files: files
      });
    } else {
      res.status(400).json({
        error: 'Path is not a directory'
      });
    }
  } catch (error) {
    console.error('Directory listing error:', error);
    res.status(500).json({
      error: 'Error reading directory',
      message: error.message
    });
  }
});

// API: Get file info
app.get('/api/file-info', requireAuth, async (req, res) => {
  try {
    const requestedPath = req.query.path;
    if (!requestedPath) {
      return res.status(400).json({ error: 'Path is required' });
    }

    const fullPath = path.join(PROTECTED_DIR, requestedPath);
    
    // Security: Ensure path is within protected directory
    const resolvedPath = path.resolve(fullPath);
    const resolvedProtectedDir = path.resolve(PROTECTED_DIR);
    
    if (!resolvedPath.startsWith(resolvedProtectedDir)) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const stats = await fs.stat(resolvedPath);
    
    res.json({
      name: path.basename(requestedPath),
      type: stats.isDirectory() ? 'directory' : 'file',
      size: stats.size,
      modified: stats.mtime.toISOString(),
      created: stats.birthtime.toISOString(),
      path: requestedPath
    });
  } catch (error) {
    res.status(500).json({
      error: 'Error getting file info',
      message: error.message
    });
  }
});

// Serve files from protected directory
app.get('/api/download', requireAuth, async (req, res) => {
  try {
    const requestedPath = req.query.path;
    if (!requestedPath) {
      return res.status(400).json({ error: 'Path is required' });
    }

    const fullPath = path.join(PROTECTED_DIR, requestedPath);
    
    // Security: Ensure path is within protected directory
    const resolvedPath = path.resolve(fullPath);
    const resolvedProtectedDir = path.resolve(PROTECTED_DIR);
    
    if (!resolvedPath.startsWith(resolvedProtectedDir)) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const stats = await fs.stat(resolvedPath);
    
    if (stats.isDirectory()) {
      return res.status(400).json({ error: 'Cannot download directory' });
    }

    // Set appropriate headers for file download
    res.setHeader('Content-Disposition', `attachment; filename="${path.basename(requestedPath)}"`);
    res.setHeader('Content-Type', 'application/octet-stream');
    res.setHeader('Content-Length', stats.size);

    // Stream the file
    const fileStream = createReadStream(resolvedPath);
    fileStream.pipe(res);
  } catch (error) {
    res.status(500).json({
      error: 'Error downloading file',
      message: error.message
    });
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString()
  });
});

// Initialize and start server
async function start() {
  await ensureProtectedDir();
  
  // Check if dist/index.html exists (production build)
  try {
    await fs.access(path.join(distPath, 'index.html'));
    distExists = true;
    app.use(express.static(distPath));
  } catch {
    distExists = false;
    // In development, don't serve static files - Vite handles that
    // Only serve from public as fallback if needed
    app.use(express.static(publicPath));
  }
  
  // Serve Vue app for all other routes (SPA fallback)
  app.get('*', (req, res) => {
    // Don't serve index.html for API routes
    if (req.path.startsWith('/api')) {
      return res.status(404).json({ error: 'Not found' });
    }
    
    const indexPath = distExists 
      ? path.join(distPath, 'index.html')
      : path.join(publicPath, 'index.html');
    
    res.sendFile(indexPath);
  });
  
  app.listen(PORT, () => {
    const url = `http://localhost:${PORT}`;
    console.log(`File Browser Server running on port ${PORT}`);
    console.log(`Environment: ${NODE_ENV}`);
    if (distExists) {
      console.log(`Serving Vue app from: ${distPath}`);
    } else {
      console.log(`Development mode: Run 'npm run dev' to start Vite dev server`);
      console.log(`Vite dev server will proxy API requests to this server`);
    }
    console.log(`Login page: ${url}/login`);
    console.log(`File browser: ${url}/`);
    console.log(`Protected directory: ${PROTECTED_DIR}`);
    console.log(`Auth service: ${AUTH_SERVICE_URL}`);
  });
}

start().catch(console.error);
