# Nginx Setup Guide for Cookie-Based Session Management

This guide explains how to configure nginx to work with the Node.js cookie-based session management service. The configuration protects the `/node_access_control/` folder, requiring valid session cookies for access.

## Quick Setup (Automated)

For automated setup that handles custom Homebrew installations, use the provided script:

```bash
./setup_nginx.sh
```

This script will:
- Detect your Homebrew installation location (standard or custom)
- Install nginx if needed
- Create necessary directories
- Configure nginx with the example config file
- Test the configuration

**Note:** The script will prompt you for confirmation at various steps.

## Manual Setup

If you prefer to set up manually, follow the steps below.

## Prerequisites

- nginx installed on your system
- Node.js application running on port 3000 (or your configured port)
- Root or sudo access to configure nginx
- Basic understanding of nginx configuration

## Step 1: Install nginx (if not already installed)

### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install nginx
```

### macOS (using Homebrew)
```bash
brew install nginx
```

### CentOS/RHEL
```bash
sudo yum install nginx
# or for newer versions
sudo dnf install nginx
```

## Step 2: Verify auth_request Module

The `auth_request` module is required for cookie-based authentication. Check if it's available:

```bash
nginx -V 2>&1 | grep -o with-http_auth_request_module
```

If you see `with-http_auth_request_module` in the output, the module is available. If not, you may need to compile nginx with this module or install a version that includes it.

Most modern nginx distributions include this module by default.

## Step 3: Prepare the Configuration File

1. **Copy the example configuration:**
   ```bash
   sudo cp nginx.conf.example /etc/nginx/sites-available/node-cookies
   ```

   **Note:** On macOS with Homebrew, nginx configs are typically in:
   
   **For Intel Macs:**
   ```bash
   sudo cp nginx.conf.example /usr/local/etc/nginx/servers/node-cookies.conf
   ```
   
   **For Apple Silicon (M1/M2) Macs:**
   ```bash
   sudo cp nginx.conf.example /opt/homebrew/etc/nginx/servers/node-cookies.conf
   ```
   
   **Important:** The file must have a `.conf` extension to be automatically loaded by nginx.

2. **Edit the configuration file** to match your setup:
   ```bash
   sudo nano /etc/nginx/sites-available/node-cookies
   # or
   sudo vim /etc/nginx/sites-available/node-cookies
   ```

## Step 4: Customize the Configuration

Edit the following settings in the configuration file:

### Required Changes

1. **Server Name** (line 13):
   ```nginx
   server_name example.com;
   ```
   Change to your domain name or `localhost` for testing:
   ```nginx
   server_name localhost;
   ```

2. **Root Directory** (line 16):
   ```nginx
   root /var/www/html;
   ```
   Change to your web root directory:
   ```nginx
   root /path/to/your/web/root;
   ```

3. **Upstream Server** (line 7):
   ```nginx
   server 127.0.0.1:3000;
   ```
   If your Node.js app runs on a different host or port, update it:
   ```nginx
   server 192.168.1.100:8080;  # Different host/port
   ```

4. **Protected Directory Path** (line 46):
   ```nginx
   alias /var/www/html/node_access_control/;
   ```
   Update to match your actual protected directory:
   ```nginx
   alias /path/to/your/protected/folder/;
   ```

### Optional Changes

- **Log Paths** (lines 20-21): Adjust log file locations if needed
- **Error Pages**: Customize error page paths (lines 125-138)
- **HTTPS**: Uncomment and configure SSL section for production (lines 141-162)

## Step 5: Create Required Directories

Create the protected directory and ensure proper permissions:

```bash
# Create the protected directory
sudo mkdir -p /var/www/html/node_access_control

# Set ownership (adjust user/group as needed)
sudo chown -R www-data:www-data /var/www/html/node_access_control

# Set permissions
sudo chmod -R 755 /var/www/html/node_access_control

# Create error pages (optional)
sudo touch /var/www/html/401.html
sudo touch /var/www/html/403.html
sudo touch /var/www/html/404.html
sudo touch /var/www/html/50x.html
```

**Note:** On macOS, the web server user is typically `_www`:
```bash
sudo chown -R _www:_www /var/www/html/node_access_control
```

## Step 6: Enable the Site

### Ubuntu/Debian
Create a symbolic link to enable the site:
```bash
sudo ln -s /etc/nginx/sites-available/node-cookies /etc/nginx/sites-enabled/
```

### macOS (Homebrew)
The configuration file in the `servers/` directory is automatically loaded if your main `nginx.conf` includes it. Check your main config:

**For Intel Macs:**
```bash
cat /usr/local/etc/nginx/nginx.conf | grep "include servers"
```

**For Apple Silicon (M1/M2) Macs:**
```bash
cat /opt/homebrew/etc/nginx/nginx.conf | grep "include servers"
```

If you see `include servers/*;` or similar, files in the `servers/` directory are automatically loaded. If not, you may need to add this line to your main `nginx.conf` or place the config in a different location.

### CentOS/RHEL
Copy to the main config directory:
```bash
sudo cp /etc/nginx/sites-available/node-cookies /etc/nginx/conf.d/node-cookies.conf
```

## Step 7: Test the Configuration

Before restarting nginx, always test the configuration for syntax errors:

```bash
sudo nginx -t
```

**Expected output:**
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

If you see errors, fix them before proceeding.

## Step 8: Restart or Reload nginx

### Option 1: Reload (Recommended - No Downtime)
Reloads the configuration without dropping connections:
```bash
sudo nginx -s reload
```

Or using systemctl:
```bash
sudo systemctl reload nginx
```

### Option 2: Restart (Full Restart)
Completely restarts nginx:
```bash
sudo systemctl restart nginx
```

Or using service:
```bash
sudo service nginx restart
```

### Option 3: Start/Stop (if nginx is not running)
```bash
# Start nginx
sudo systemctl start nginx
# or
sudo service nginx start

# Stop nginx
sudo systemctl stop nginx
# or
sudo service nginx stop
```

### macOS (Homebrew)
```bash
# Reload
sudo nginx -s reload

# Restart
brew services restart nginx

# Start
brew services start nginx

# Stop
brew services stop nginx
```

## Step 9: Verify nginx is Running

Check nginx status:
```bash
sudo systemctl status nginx
```

Or check if the process is running:
```bash
ps aux | grep nginx
```

Check if nginx is listening on port 80:
```bash
sudo netstat -tlnp | grep :80
# or
sudo ss -tlnp | grep :80
```

## Step 10: Test the Setup

1. **Ensure Node.js app is running:**
   ```bash
   cd /path/to/node_cookies
   npm start
   ```

2. **Test login endpoint:**
   ```bash
   curl -X POST http://localhost/login \
     -H "Content-Type: application/json" \
     -d '{"username":"admin","password":"password123"}' \
     -c cookies.txt
   ```

3. **Test protected file access:**
   ```bash
   # With valid session cookie
   curl -b cookies.txt http://localhost/node_access_control/test.txt
   
   # Without session cookie (should return 401)
   curl http://localhost/node_access_control/test.txt
   ```

## Troubleshooting

### nginx returns 502 Bad Gateway

**Problem:** nginx can't connect to the Node.js app.

**Solutions:**
- Verify Node.js app is running: `ps aux | grep node`
- Check the upstream server address in nginx config matches your Node.js app
- Check firewall rules: `sudo ufw status` or `sudo iptables -L`
- Check nginx error logs: `sudo tail -f /var/log/nginx/error.log`

### Configuration test fails

**Problem:** `sudo nginx -t` shows syntax errors.

**Solutions:**
- Check for typos in the configuration file
- Verify all paths exist
- Check for missing semicolons or brackets
- Review error messages carefully

### Files not accessible (401 Unauthorized)

**Problem:** Even with valid session cookie, files return 401.

**Solutions:**
- Verify cookies are being sent: Check browser DevTools → Network → Request Headers
- Check nginx error logs: `sudo tail -f /var/log/nginx/error.log`
- Verify `/auth/validate` endpoint is working: `curl http://localhost/auth/validate`
- Check cookie name matches: Default is `sessionId`

### Files not accessible (403 Forbidden)

**Problem:** Files return 403 even with valid authentication.

**Solutions:**
- Check file permissions: `ls -la /var/www/html/node_access_control/`
- Verify nginx user has read access: `sudo chmod -R 755 /var/www/html/node_access_control`
- Check SELinux (if enabled): `sudo setenforce 0` (temporary) or configure SELinux policies

### Cookie not being set/sent

**Problem:** Session cookie is not being stored or sent.

**Solutions:**
- Verify `httpOnly` and `secure` settings match your environment
- For HTTPS, ensure `secure: true` in Node.js cookie settings
- Check browser cookie settings (some browsers block third-party cookies)
- Verify domain matches between nginx and Node.js app

### Range requests not working

**Problem:** Video streaming or large file downloads fail.

**Solutions:**
- Verify `proxy_request_buffering off` and `proxy_buffering off` are set
- Check timeout values are sufficient for large files
- Ensure `Range` header is being passed: Check nginx access logs

## Viewing Logs

### Access Logs
```bash
sudo tail -f /var/log/nginx/access.log
```

### Error Logs
```bash
sudo tail -f /var/log/nginx/error.log
```

### Filter logs by specific IP or path
```bash
sudo tail -f /var/log/nginx/access.log | grep "192.168.1.100"
sudo tail -f /var/log/nginx/access.log | grep "/node_access_control/"
```

## Common nginx Commands Reference

| Command | Description |
|---------|-------------|
| `sudo nginx -t` | Test configuration syntax |
| `sudo nginx -s reload` | Reload configuration |
| `sudo nginx -s stop` | Stop nginx |
| `sudo nginx -s quit` | Graceful shutdown |
| `sudo nginx -s reopen` | Reopen log files |
| `sudo systemctl status nginx` | Check nginx status |
| `sudo systemctl restart nginx` | Restart nginx service |
| `sudo systemctl reload nginx` | Reload nginx service |

## Production Considerations

1. **Enable HTTPS:** Uncomment and configure the SSL section in the config file
2. **Set proper file permissions:** Restrict access to configuration files
3. **Configure firewall:** Only allow necessary ports (80, 443)
4. **Set up log rotation:** Configure logrotate for nginx logs
5. **Monitor performance:** Set up monitoring for nginx and Node.js app
6. **Use process manager:** Use PM2 or similar for Node.js app management

## Additional Resources

- [Nginx Documentation](https://nginx.org/en/docs/)
- [Nginx auth_request Module](https://nginx.org/en/docs/http/ngx_http_auth_request_module.html)
- [Nginx Configuration Guide](https://nginx.org/en/docs/beginners_guide.html)

