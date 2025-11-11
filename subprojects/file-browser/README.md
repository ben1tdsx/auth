# File Browser

A web-based file browser for accessing protected files in the `node_access_control` directory. This application provides a login interface and file browsing functionality that integrates with the cookie-based session management service.

## Features

- **Login Interface**: Secure login using the cookie session manager
- **File Browser**: Browse directories and files in the protected `node_access_control` folder
- **File Download**: Download files directly from the browser
- **Breadcrumb Navigation**: Easy navigation through directory structure
- **Responsive Design**: Works on desktop and mobile devices

## Prerequisites

- Node.js (v14 or higher)
- The cookie session manager service running on port 3000 (or configured port)
- Access to the `node_access_control` directory

## Installation

1. Navigate to the file-browser directory:
   ```bash
   cd subprojects/file-browser
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

## Configuration

The application can be configured using environment variables:

- `PORT`: Server port (default: 3001)
- `AUTH_SERVICE_URL`: URL of the cookie session manager service (default: http://localhost:3000)
- `PROTECTED_DIR`: Path to the protected directory (default: ../../node_access_control)

Example:
```bash
PORT=3001 AUTH_SERVICE_URL=http://localhost:3000 PROTECTED_DIR=/path/to/protected npm start
```

## Running the Application

### Development Mode (Recommended)

For development with hot module replacement, you need to run two servers:

**Terminal 1 - Backend Server:**
```bash
npm run server
# or
npm start
```
This starts the Express backend on port 3001.

**Terminal 2 - Vite Dev Server:**
```bash
npm run dev
```
This starts the Vite dev server on port 5173 with hot reload.

Then visit: **http://localhost:5173** (Vite dev server proxies API requests to the backend)

### Production Mode

1. **Build the Vue app:**
   ```bash
   npm run build
   ```
   This creates an optimized build in the `dist/` folder.

2. **Start the server:**
   ```bash
   npm start
   ```
   The server will serve the built Vue app on port 3001.

   Access the application at:
   - Login page: http://localhost:3001/login
   - File browser: http://localhost:3001/

## Usage

1. **Start the cookie session manager** (if not already running):
   ```bash
   cd ../..
   npm start
   ```

2. **Start the file browser**:
   ```bash
   cd subprojects/file-browser
   npm start
   ```

3. **Access the application**:
   - Open http://localhost:3001/login in your browser
   - Login with your credentials (e.g., admin/password123)
   - Browse and download files from the protected directory

## API Endpoints

### GET /login
Login page (HTML)

### POST /login
Authenticate user and create session cookie

**Request Body:**
```json
{
  "username": "admin",
  "password": "password123"
}
```

### POST /logout
Logout and clear session cookie

### GET /
File browser page (requires authentication)

### GET /api/files?path=/directory
Get directory listing

**Response:**
```json
{
  "path": "/directory",
  "files": [
    {
      "name": "file.txt",
      "type": "file",
      "size": 1024,
      "modified": "2024-01-01T00:00:00.000Z",
      "path": "/directory/file.txt"
    }
  ]
}
```

### GET /api/download?path=/file.txt
Download a file (requires authentication)

### GET /api/file-info?path=/file.txt
Get file information (requires authentication)

## Security

- All file browser routes require authentication via session cookie
- Path traversal protection ensures users can only access files within the protected directory
- Session cookies are validated against the cookie session manager service

## Project Structure

```
file-browser/
├── server.js           # Express backend server
├── vite.config.js      # Vite configuration
├── package.json        # Dependencies
├── README.md           # This file
├── src/                # Vue.js source files
│   ├── main.js         # Vue app entry point
│   ├── App.vue         # Root component
│   ├── index.html      # HTML template
│   ├── styles.css      # Global styles
│   └── components/     # Vue components
│       ├── Login.vue   # Login page component
│       └── Browser.vue # File browser component
├── dist/               # Production build (generated)
└── public/             # Static assets (fallback)
```

## Troubleshooting

### Cannot connect to authentication service
- Ensure the cookie session manager is running on port 3000
- Check the `AUTH_SERVICE_URL` environment variable

### Files not showing
- Verify the `PROTECTED_DIR` path is correct
- Check file permissions on the protected directory
- Ensure the directory exists

### Login fails
- Verify credentials in the cookie session manager's `users.json`
- Check that the authentication service is accessible

## License

MIT

