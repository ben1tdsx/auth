const express = require('express');
const cookieParser = require('cookie-parser');
const crypto = require('crypto');
const fs = require('fs').promises;
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());

// Path to users JSON file
const USERS_FILE = path.join(__dirname, 'users.json');

// In-memory session store (in production, use Redis or a database)
const sessions = new Map();

// Session configuration
const SESSION_COOKIE_NAME = 'sessionId';
const SESSION_DURATION = 24 * 60 * 60 * 1000; // 24 hours in milliseconds

/**
 * Generate a secure random session ID
 */
function generateSessionId() {
  return crypto.randomBytes(32).toString('hex');
}

/**
 * Create a new session
 */
function createSession(username) {
  const sessionId = generateSessionId();
  const expiresAt = Date.now() + SESSION_DURATION;
  
  sessions.set(sessionId, {
    username,
    expiresAt,
    createdAt: Date.now()
  });
  
  return sessionId;
}

/**
 * Validate a session
 */
function validateSession(sessionId) {
  if (!sessionId) {
    return null;
  }
  
  const session = sessions.get(sessionId);
  
  if (!session) {
    return null;
  }
  
  // Check if session has expired
  if (Date.now() > session.expiresAt) {
    sessions.delete(sessionId);
    return null;
  }
  
  return session;
}

/**
 * Delete a session
 */
function deleteSession(sessionId) {
  if (sessionId) {
    sessions.delete(sessionId);
  }
}

/**
 * Middleware to validate session cookie for protected routes
 */
function requireAuth(req, res, next) {
  const sessionId = req.cookies[SESSION_COOKIE_NAME];
  const session = validateSession(sessionId);
  
  if (!session) {
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'Valid session cookie required'
    });
  }
  
  // Attach session info to request object
  req.session = session;
  req.username = session.username;
  
  next();
}

/**
 * Endpoint for nginx auth_request module
 * Validates session cookie and returns appropriate status
 */
app.get('/auth/validate', (req, res) => {
  const sessionId = req.cookies[SESSION_COOKIE_NAME];
  const session = validateSession(sessionId);
  
  if (session) {
    // Valid session - return 200 OK
    res.status(200).json({
      valid: true,
      username: session.username
    });
  } else {
    // Invalid or expired session - return 401 Unauthorized
    res.status(401).json({
      valid: false,
      error: 'Invalid or expired session'
    });
  }
});

/**
 * Load users from JSON file
 * This function is called on each login request to allow dynamic user updates
 */
async function loadUsers() {
  try {
    const data = await fs.readFile(USERS_FILE, 'utf8');
    return JSON.parse(data);
  } catch (error) {
    console.error('Error loading users file:', error.message);
    // Return empty object if file doesn't exist or can't be read
    return {};
  }
}

/**
 * Login endpoint
 * Accepts username and password, validates against users from JSON file,
 * and issues a session cookie on successful authentication
 * Loads users from JSON file on each request to allow dynamic updates
 */
app.post('/login', async (req, res) => {
  const { username, password } = req.body;
  
  if (!username || !password) {
    return res.status(400).json({
      error: 'Bad Request',
      message: 'Username and password are required'
    });
  }
  
  // Load users from JSON file on each login request
  const users = await loadUsers();
  
  // Validate credentials
  if (users[username] && users[username] === password) {
    // Create session
    const sessionId = createSession(username);
    
    // Set session cookie
    res.cookie(SESSION_COOKIE_NAME, sessionId, {
      httpOnly: true, // Prevents JavaScript access (XSS protection)
      secure: process.env.NODE_ENV === 'production', // Only send over HTTPS in production
      sameSite: 'lax', // CSRF protection
      maxAge: SESSION_DURATION
    });
    
    return res.status(200).json({
      success: true,
      message: 'Login successful',
      username: username
    });
  } else {
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'Invalid username or password'
    });
  }
});

/**
 * Logout endpoint
 * Clears the session cookie
 */
app.post('/logout', requireAuth, (req, res) => {
  const sessionId = req.cookies[SESSION_COOKIE_NAME];
  
  // Delete session from store
  deleteSession(sessionId);
  
  // Clear session cookie
  res.clearCookie(SESSION_COOKIE_NAME, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax'
  });
  
  return res.status(200).json({
    success: true,
    message: 'Logout successful'
  });
});

/**
 * Protected test route
 * Only returns content if a valid session cookie is present
 */
app.get('/protected', requireAuth, (req, res) => {
  res.status(200).json({
    success: true,
    message: 'You have successfully accessed a protected route',
    username: req.username,
    sessionInfo: {
      createdAt: new Date(req.session.createdAt).toISOString(),
      expiresAt: new Date(req.session.expiresAt).toISOString()
    }
  });
});

/**
 * Health check endpoint
 */
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    timestamp: new Date().toISOString()
  });
});

/**
 * Cleanup expired sessions periodically (every hour)
 */
setInterval(() => {
  const now = Date.now();
  let cleaned = 0;
  
  for (const [sessionId, session] of sessions.entries()) {
    if (now > session.expiresAt) {
      sessions.delete(sessionId);
      cleaned++;
    }
  }
  
  if (cleaned > 0) {
    console.log(`Cleaned up ${cleaned} expired session(s)`);
  }
}, 60 * 60 * 1000); // Run every hour

// Start server
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
  console.log(`Login endpoint: http://localhost:${PORT}/login`);
  console.log(`Protected endpoint: http://localhost:${PORT}/protected`);
  console.log(`Auth validation endpoint: http://localhost:${PORT}/auth/validate`);
});

