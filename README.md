# Node.js Cookie-Based Session Management

A Node.js application implementing cookie-based session management for HTTP requests using Express.js. This project provides authentication endpoints and middleware for protecting routes, with nginx integration examples for file access control.

## Features

- **Login Endpoint** (`/login`): Validates username/password and issues session cookies
- **Logout Endpoint** (`/logout`): Clears session cookies
- **Session Middleware**: Validates session cookies for protected routes
- **Protected Route** (`/protected`): Example protected endpoint
- **Auth Validation Endpoint** (`/auth/validate`): For nginx `auth_request` module integration
- **Nginx Integration**: Configuration examples for protecting file access

## Project Structure

```
node_cookies/
├── package.json          # Node.js dependencies
├── index.js              # Main Express server
├── users.json            # User credentials (username/password)
├── nginx.conf.example    # Nginx configuration example
└── README.md             # This file
```

## Prerequisites

- Node.js (v14 or higher)
- npm (Node Package Manager)
- nginx (for file access control integration)

## Installation

1. Clone or navigate to the project directory:
```bash
cd node_cookies
```

2. Install dependencies:
```bash
npm install
```

## Running the Application

### Development Mode

```bash
npm run dev
```

This uses `nodemon` to automatically restart the server on file changes.

### Production Mode

```bash
npm start
```

Or directly:
```bash
node index.js
```

The server will start on port 3000 by default. You can change this by setting the `PORT` environment variable:

```bash
PORT=8080 npm start
```

## API Endpoints

### POST /login

Authenticates a user and creates a session cookie.

**Request Body:**
```json
{
  "username": "admin",
  "password": "password123"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Login successful",
  "username": "admin"
}
```

**Error Response (401):**
```json
{
  "error": "Unauthorized",
  "message": "Invalid username or password"
}
```

### POST /logout

Logs out the current user and clears the session cookie.

**Headers Required:**
- Cookie: `sessionId=<session_id>`

**Success Response (200):**
```json
{
  "success": true,
  "message": "Logout successful"
}
```

### GET /protected

Protected route that requires a valid session cookie.

**Headers Required:**
- Cookie: `sessionId=<session_id>`

**Success Response (200):**
```json
{
  "success": true,
  "message": "You have successfully accessed a protected route",
  "username": "admin",
  "sessionInfo": {
    "createdAt": "2024-01-01T00:00:00.000Z",
    "expiresAt": "2024-01-02T00:00:00.000Z"
  }
}
```

**Error Response (401):**
```json
{
  "error": "Unauthorized",
  "message": "Valid session cookie required"
}
```

### GET /auth/validate

Internal endpoint for nginx `auth_request` module. Validates session cookies.

**Headers Required:**
- Cookie: `sessionId=<session_id>`

**Success Response (200):**
```json
{
  "valid": true,
  "username": "admin"
}
```

**Error Response (401):**
```json
{
  "valid": false,
  "error": "Invalid or expired session"
}
```

### GET /health

Health check endpoint.

**Response (200):**
```json
{
  "status": "ok",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

## Hardcoded Users

The application includes the following test users:

| Username | Password |
|----------|----------|
| admin | password123 |
| user1 | secret456 |
| testuser | testpass789 |

### Adding or Modifying Users

Users are stored in `users.json` and loaded on each login request, so you can add or modify users without restarting the server.

1. **Open `users.json`** file:
   ```json
   {
     "admin": "password123",
     "user1": "secret456",
     "testuser": "testpass789"
   }
   ```

2. **To add a new user**, add a new key-value pair:
   ```json
   {
     "admin": "password123",
     "user1": "secret456",
     "testuser": "testpass789",
     "newuser": "newpassword"
   }
   ```

3. **To modify a password**, change the value for the existing username:
   ```json
   {
     "admin": "newpassword123",
     "user1": "secret456",
     "testuser": "testpass789"
   }
   ```

4. **To remove a user**, simply delete the key-value pair from the JSON object.

5. **Save the file** - changes take effect immediately on the next login request. **No server restart required!**

**Note:** 
- The JSON file is loaded on each login request, allowing dynamic user management without server restarts.
- Passwords are stored in plain text. For production, consider using password hashing (bcrypt, argon2) and a proper database.
- Ensure `users.json` has proper file permissions to prevent unauthorized access.

## Testing the API

### Using cURL

1. **Login:**
```bash
curl -X POST http://localhost:3000/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"password123"}' \
  -c cookies.txt
```

2. **Access Protected Route:**
```bash
curl -X GET http://localhost:3000/protected \
  -b cookies.txt
```

3. **Logout:**
```bash
curl -X POST http://localhost:3000/logout \
  -b cookies.txt \
  -c cookies.txt
```

### Using Postman or Insomnia

1. Send a POST request to `http://localhost:3000/login` with JSON body:
   ```json
   {
     "username": "admin",
     "password": "password123"
   }
   ```
2. The response will include a `Set-Cookie` header. Most HTTP clients automatically handle this.
3. Subsequent requests to `/protected` will use the session cookie automatically.

## Nginx Integration

### Setup Instructions

1. **Install nginx** (if not already installed):
   ```bash
   # Ubuntu/Debian
   sudo apt-get install nginx
   
   # macOS (using Homebrew)
   brew install nginx
   ```

2. **Enable the auth_request module** (usually enabled by default):
   ```bash
   # Check if module is available
   nginx -V 2>&1 | grep -o with-http_auth_request_module
   ```

3. **Copy the example configuration:**
   ```bash
   sudo cp nginx.conf.example /etc/nginx/sites-available/node-cookies
   ```

4. **Edit the configuration** to match your setup:
   - Update `server_name` with your domain
   - Update `root` path to your web root directory
   - Adjust upstream server address if Node.js app runs on different host/port
   - Create the protected directory:
     ```bash
     sudo mkdir -p /var/www/html/node_access_control
     ```

5. **Create a symbolic link** to enable the site:
   ```bash
   sudo ln -s /etc/nginx/sites-available/node-cookies /etc/nginx/sites-enabled/
   ```

6. **Test the configuration:**
   ```bash
   sudo nginx -t
   ```

7. **Reload nginx:**
   ```bash
   sudo systemctl reload nginx
   # or
   sudo nginx -s reload
   ```

### How It Works

1. When a client requests a file from `/node_access_control/`, nginx intercepts the request.
2. The `auth_request` module sends a subrequest to `/auth/validate` on the Node.js app.
3. The Node.js app validates the session cookie and returns:
   - `200 OK` if the session is valid → nginx serves the file
   - `401 Unauthorized` if the session is invalid → nginx returns 401 error
4. HTTP Range requests are automatically handled by nginx for video streaming and large file downloads.

### Testing Nginx Integration

1. **Start the Node.js application:**
   ```bash
   npm start
   ```

2. **Login to get a session cookie:**
   ```bash
   curl -X POST http://localhost/login \
     -H "Content-Type: application/json" \
     -d '{"username":"admin","password":"password123"}' \
     -c cookies.txt
   ```

3. **Access a protected file:**
   ```bash
   # With valid session cookie
   curl -b cookies.txt http://localhost/node_access_control/example.mp4
   
   # Without session cookie (should return 401)
   curl http://localhost/node_access_control/example.mp4
   ```

## Security Considerations

1. **Session Storage**: The current implementation uses in-memory storage. For production:
   - Use Redis or a database for session storage
   - Implement session persistence across server restarts
   - Consider distributed session storage for load balancing

2. **Cookie Security**:
   - `httpOnly: true` prevents JavaScript access (XSS protection)
   - `secure: true` in production ensures cookies only sent over HTTPS
   - `sameSite: 'lax'` provides CSRF protection

3. **HTTPS**: Always use HTTPS in production. Update the nginx configuration to use SSL/TLS certificates.

4. **Password Storage**: Replace hardcoded passwords with proper password hashing (bcrypt, argon2, etc.) and database storage.

5. **Rate Limiting**: Consider adding rate limiting to prevent brute force attacks on the login endpoint.

6. **Session Expiration**: Sessions expire after 24 hours. Adjust `SESSION_DURATION` in `index.js` as needed.

## Environment Variables

- `PORT`: Server port (default: 3000)
- `NODE_ENV`: Environment mode (`production` enables secure cookies)

Example:
```bash
PORT=8080 NODE_ENV=production npm start
```

## Troubleshooting

### nginx returns 502 Bad Gateway

- Ensure the Node.js app is running on the port specified in the nginx upstream configuration
- Check nginx error logs: `sudo tail -f /var/log/nginx/error.log`

### Session cookie not being set

- Check browser console for cookie restrictions
- Ensure you're using HTTP (or HTTPS in production)
- Verify cookie settings in `index.js` match your environment

### Files not accessible through nginx

- Verify the directory path in nginx configuration matches the actual file location
- Check file permissions: `sudo chmod -R 755 /var/www/html/node_access_control`
- Ensure nginx user has read access to the files

## License

MIT

