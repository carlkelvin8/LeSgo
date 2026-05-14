# 🚀 LeSGo Production Deployment Guide

## 📱 Frontend (Customer App) Configuration

### Current Setup:
- **Development**: `http://10.0.2.2:8000/api` (local)
- **Production**: `https://api.lesgo.ph/api` (auto-switches based on build type)

### Build Commands:
```bash
# Development APK (connects to local server)
flutter build apk --debug

# Production APK (connects to production server)
flutter build apk --release
```

## 🖥️ Backend Deployment Steps

### 1. Server Requirements
- **Server**: Ubuntu 20.04+ or CentOS 8+
- **PHP**: 8.2+
- **Database**: PostgreSQL 13+
- **Web Server**: Nginx + PHP-FPM
- **SSL**: Let's Encrypt certificate
- **Domain**: api.lesgo.ph

### 2. Database Setup
```sql
-- Create production database
CREATE DATABASE lesgo_production_db;
CREATE USER lesgo_user WITH PASSWORD 'your-secure-password';
GRANT ALL PRIVILEGES ON DATABASE lesgo_production_db TO lesgo_user;
```

### 3. Environment Configuration
```bash
# Copy production environment file
cp .env.production .env

# Update these values in .env:
DB_HOST=your-production-db-host
DB_PASSWORD=your-secure-production-password
APP_KEY=generate-new-key-with-php-artisan-key-generate
```

### 4. Laravel Deployment Commands
```bash
# Install dependencies
composer install --optimize-autoloader --no-dev

# Generate application key
php artisan key:generate

# Run database migrations
php artisan migrate --force

# Seed initial data
php artisan db:seed --force

# Cache configuration
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Set proper permissions
chmod -R 755 storage bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache
```

### 5. Nginx Configuration
```nginx
server {
    listen 443 ssl http2;
    server_name api.lesgo.ph;
    root /var/www/lesgo-api/public;
    index index.php;

    ssl_certificate /etc/letsencrypt/live/api.lesgo.ph/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.lesgo.ph/privkey.pem;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
```

## 🔧 Production Configuration Updates

### Required Changes:
1. **Database Credentials**: Update production database settings
2. **API Keys**: Replace with production keys for:
   - Twilio (SMS)
   - Xendit (Payments)
   - Firebase (Push notifications)
   - AWS S3 (File storage)
3. **Domain Settings**: Update CORS and session domains
4. **SSL Certificates**: Install and configure SSL

## 📱 Mobile App Distribution

### APK Build for Production:
```bash
cd FRONTEND
flutter build apk --release
```

### App Store Deployment:
```bash
# For Google Play Store
flutter build appbundle --release

# For iOS App Store (if needed)
flutter build ios --release
```

## 🔒 Security Checklist

- [ ] Change all default passwords
- [ ] Generate new APP_KEY
- [ ] Enable HTTPS/SSL
- [ ] Configure proper CORS origins
- [ ] Set APP_DEBUG=false
- [ ] Use production database
- [ ] Configure proper file permissions
- [ ] Set up regular backups
- [ ] Configure monitoring and logging

## 🌐 DNS Configuration

### Required DNS Records:
```
api.lesgo.ph     A     your-server-ip
app.lesgo.ph     A     your-frontend-server-ip
ws.lesgo.ph      A     your-websocket-server-ip
```

## 📊 Monitoring Setup

### Recommended Tools:
- **Server Monitoring**: New Relic, DataDog
- **Error Tracking**: Sentry
- **Uptime Monitoring**: Pingdom, UptimeRobot
- **Log Management**: ELK Stack or Papertrail

## 🔄 Deployment Automation

### CI/CD Pipeline (GitHub Actions):
```yaml
name: Deploy to Production
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Deploy to server
        run: |
          # Add deployment commands here
```

## 📞 Support Contacts

- **Technical Issues**: tech@lesgo.ph
- **Server Issues**: devops@lesgo.ph
- **Emergency**: +63 XXX XXX XXXX

---

**Note**: Replace all placeholder values (your-server-ip, your-database-password, etc.) with actual production values before deployment.