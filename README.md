# PD-Cert

![Shell Script](https://img.shields.io/badge/Shell-Bash-green)
![Platform](https://img.shields.io/badge/Platform-Ubuntu%20%7C%20Debian-blue)
![SSL](https://img.shields.io/badge/SSL-Let's%20Encrypt-orange)
![DNS](https://img.shields.io/badge/DNS-Cloudflare-yellow)
![License](https://img.shields.io/badge/License-MIT-lightgrey)

**PD-Cert** is a simple Bash-based SSL certificate installer for servers using **Let's Encrypt** with **Cloudflare DNS Challenge**.

It helps you issue, renew, delete, and reissue SSL certificates without manually configuring Certbot and Cloudflare DNS plugins.

---

## 🇬🇧 English

### Overview

PD-Cert automates the process of getting SSL certificates using the Cloudflare DNS-01 challenge method.

This is especially useful when:

* Your server is behind Cloudflare.
* Port `80` is closed or unavailable.
* You want to issue a wildcard certificate.
* You want a simple interactive installer.
* You want to delete and reissue existing certificates.

---

### Features

* 🚀 Issue SSL certificates using Let's Encrypt
* 🌍 Supports main domain and `www`
* ⭐ Supports wildcard certificates
* 🗑️ Delete existing certificates
* ♻️ Delete and reissue certificates
* 🔐 Uses Cloudflare API Token
* 🧩 Installs Certbot and Cloudflare DNS plugin automatically
* 🧪 Tests automatic renewal with Certbot dry-run
* 🎨 Colored terminal interface
* 📦 One-command installation

---

### Supported Systems

Currently supported:

```text
Ubuntu
Debian
Debian-based Linux distributions
```

The script uses `apt`, so it is not currently compatible with CentOS, AlmaLinux, Rocky Linux, Fedora, or Arch Linux.

---

### Requirements

Before running the script, make sure:

1. Your domain is managed by Cloudflare.
2. You have root or sudo access to your server.
3. Your server is running Ubuntu or Debian.
4. You have a valid Cloudflare API Token.
5. DNS records for your domain are active in Cloudflare.

---

### Cloudflare API Token Permissions

Create a Cloudflare API Token with these permissions:

```text
Zone → DNS → Edit
Zone → Zone → Read
```

Recommended resource scope:

```text
Include → Specific zone → your-domain.com
```

Using a limited API Token is safer than using the Global API Key.

---

### One-command Installation

Run this command on your server:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/Mehdi682007/PD-Cert/main/install.sh)
```

The script will guide you through the process interactively.

---

### Certificate Options

The script supports three certificate types:

```text
1) Main domain only
   example.com

2) Main domain + www
   example.com
   www.example.com

3) Wildcard certificate
   example.com
   *.example.com
```

Wildcard certificates are useful when you want to secure multiple subdomains, such as:

```text
api.example.com
panel.example.com
app.example.com
```

---

### Available Actions

The script provides these actions:

```text
1) Issue / renew certificate
2) Delete existing certificate, then issue again
3) Delete existing certificate only
```

Use option `2` if you already have a certificate and want to remove it before issuing a new one.

---

### Certificate Paths

After a successful installation, your certificate files will be available at:

```text
/etc/letsencrypt/live/your-domain.com/fullchain.pem
/etc/letsencrypt/live/your-domain.com/privkey.pem
```

For Nginx, use:

```nginx
ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
```

Then reload Nginx:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

### Example Nginx Configuration

```nginx
server {
    listen 443 ssl http2;
    server_name example.com www.example.com;

    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

    root /var/www/html;
    index index.html;
}
```

---

### Cloudflare SSL/TLS Mode

If your website is behind Cloudflare, set SSL/TLS mode to:

```text
Full (strict)
```

Avoid using:

```text
Flexible
```

When using Let's Encrypt certificates on your origin server, `Full (strict)` is the recommended mode.

---

### Renewal

Certbot usually creates an automatic renewal timer.

The script also tests renewal using:

```bash
certbot renew --dry-run
```

You can manually check Certbot timers with:

```bash
systemctl list-timers | grep certbot
```

or:

```bash
systemctl status certbot.timer
```

---

### Security Notes

The Cloudflare API Token is stored in:

```text
/etc/letsencrypt/cloudflare.ini
```

The script sets secure permissions:

```text
600
```

This means only the root user can read the file.

For better security:

* Do not use your Cloudflare Global API Key.
* Use a limited API Token.
* Restrict the token to only the required domain.
* Do not share your token publicly.
* Do not commit `.ini`, `.env`, token, or private key files to GitHub.

---

### Common Issues

#### Invalid Cloudflare API Token

Make sure your API Token has these permissions:

```text
Zone → DNS → Edit
Zone → Zone → Read
```

#### Certificate Delete Failed

If deleting fails, check the exact certificate name:

```bash
sudo certbot certificates
```

Then make sure the certificate name matches your domain.

#### DNS Challenge Failed

Make sure your domain is active in Cloudflare and the API Token has access to the correct zone.

#### Nginx Reload Failed

Test your Nginx configuration:

```bash
sudo nginx -t
```

If there is an error, fix the SSL paths or server block before reloading.

---

### Uninstall / Delete Certificate

Run the installer and choose:

```text
3) Delete existing certificate only
```

Or delete manually:

```bash
sudo certbot delete --cert-name your-domain.com
```

---

### Project Structure

Recommended repository structure:

```text
PD-Cert/
├── install.sh
├── README.md
├── LICENSE
└── .gitignore
```

---

### Recommended `.gitignore`

```gitignore
# Secrets
*.ini
*.env
.env
cloudflare.ini

# SSL private files
*.key
*.pem
*.crt
*.csr

# Logs
*.log

# System files
.DS_Store
Thumbs.db
```

---

### Disclaimer

This script modifies SSL certificate files on your server and installs required packages. Review the script before running it on production systems.

Running remote scripts directly with `curl | bash` is convenient, but you should always inspect the script first if you are using it on a sensitive server.

To inspect before running:

```bash
curl -Ls https://raw.githubusercontent.com/Mehdi682007/PD-Cert/main/install.sh
```

Then run:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/Mehdi682007/PD-Cert/main/install.sh)
```

---

### Contributing

Contributions are welcome.

You can contribute by:

* Reporting bugs
* Suggesting features
* Improving documentation
* Adding support for more Linux distributions
* Submitting pull requests

---

### License

This project is released under the MIT License.

---

<br>

# 🇮🇷 راهنمای فارسی

## معرفی

**PD-Cert** یک اسکریپت Bash ساده برای دریافت، حذف، تمدید و صدور مجدد گواهی SSL با استفاده از **Let's Encrypt** و **Cloudflare DNS Challenge** است.

این ابزار برای سرورهایی مناسب است که دامنه آن‌ها روی Cloudflare مدیریت می‌شود و می‌خواهند بدون تنظیمات پیچیده Certbot، گواهی SSL دریافت کنند.

---

## کاربرد

این اسکریپت زمانی کاربرد دارد که:

* سرور شما پشت Cloudflare است.
* پورت `80` باز نیست یا نمی‌خواهید از HTTP Challenge استفاده کنید.
* می‌خواهید گواهی wildcard بگیرید.
* می‌خواهید گواهی قبلی را حذف و دوباره صادر کنید.
* می‌خواهید نصب و تنظیم Certbot به‌صورت خودکار انجام شود.

---

## امکانات

* 🚀 دریافت گواهی SSL با Let's Encrypt
* 🌍 پشتیبانی از دامنه اصلی و `www`
* ⭐ پشتیبانی از wildcard certificate
* 🗑️ حذف گواهی فعلی
* ♻️ حذف و دریافت مجدد گواهی
* 🔐 استفاده از Cloudflare API Token
* 🧩 نصب خودکار Certbot و افزونه Cloudflare DNS
* 🧪 تست تمدید خودکار با `dry-run`
* 🎨 محیط رنگی در ترمینال
* 📦 نصب تک‌دستوری

---

## سیستم‌عامل‌های پشتیبانی‌شده

در حال حاضر این اسکریپت از سیستم‌های زیر پشتیبانی می‌کند:

```text
Ubuntu
Debian
توزیع‌های مبتنی بر Debian
```

چون اسکریپت از `apt` استفاده می‌کند، فعلاً برای CentOS، AlmaLinux، Rocky Linux، Fedora یا Arch Linux مناسب نیست.

---

## پیش‌نیازها

قبل از اجرا مطمئن شوید:

1. دامنه شما روی Cloudflare فعال است.
2. به سرور دسترسی root یا sudo دارید.
3. سیستم‌عامل سرور Ubuntu یا Debian است.
4. Cloudflare API Token معتبر دارید.
5. رکوردهای DNS دامنه داخل Cloudflare مدیریت می‌شوند.

---

## دسترسی‌های موردنیاز Cloudflare API Token

در Cloudflare یک API Token با دسترسی‌های زیر بسازید:

```text
Zone → DNS → Edit
Zone → Zone → Read
```

بهتر است Token فقط به همان دامنه محدود شود:

```text
Include → Specific zone → your-domain.com
```

استفاده از API Token محدودشده بسیار امن‌تر از Global API Key است.

---

## نصب تک‌دستوری

برای اجرای اسکریپت روی سرور:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/Mehdi682007/PD-Cert/main/install.sh)
```

بعد از اجرا، اسکریپت به‌صورت مرحله‌ای اطلاعات لازم را از شما می‌گیرد.

---

## نوع گواهی‌ها

اسکریپت از سه حالت پشتیبانی می‌کند:

```text
1) فقط دامنه اصلی
   example.com

2) دامنه اصلی همراه با www
   example.com
   www.example.com

3) گواهی wildcard
   example.com
   *.example.com
```

گواهی wildcard برای زمانی مناسب است که می‌خواهید چندین ساب‌دامنه را پوشش دهید، مثل:

```text
api.example.com
panel.example.com
app.example.com
```

---

## گزینه‌های اصلی اسکریپت

در ابتدای اجرا، اسکریپت این گزینه‌ها را نمایش می‌دهد:

```text
1) دریافت / تمدید گواهی
2) حذف گواهی فعلی و دریافت مجدد
3) فقط حذف گواهی فعلی
```

اگر قبلاً گواهی گرفته‌اید و می‌خواهید آن را پاک کنید و دوباره بگیرید، گزینه `2` را انتخاب کنید.

---

## مسیر فایل‌های گواهی

بعد از صدور موفق گواهی، فایل‌ها در مسیر زیر قرار می‌گیرند:

```text
/etc/letsencrypt/live/your-domain.com/fullchain.pem
/etc/letsencrypt/live/your-domain.com/privkey.pem
```

برای Nginx از این مسیرها استفاده کنید:

```nginx
ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
```

سپس Nginx را تست و reload کنید:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

## نمونه کانفیگ Nginx

```nginx
server {
    listen 443 ssl http2;
    server_name example.com www.example.com;

    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

    root /var/www/html;
    index index.html;
}
```

---

## تنظیم SSL در Cloudflare

اگر سایت شما پشت Cloudflare است، در بخش SSL/TLS حالت زیر را انتخاب کنید:

```text
Full (strict)
```

از حالت زیر استفاده نکنید:

```text
Flexible
```

وقتی روی سرور اصلی خودتان گواهی معتبر Let's Encrypt دارید، حالت صحیح معمولاً `Full (strict)` است.

---

## تمدید خودکار

Certbot معمولاً برای تمدید خودکار گواهی‌ها timer ایجاد می‌کند.

اسکریپت بعد از صدور گواهی، تمدید خودکار را با این دستور تست می‌کند:

```bash
certbot renew --dry-run
```

برای بررسی timer:

```bash
systemctl list-timers | grep certbot
```

یا:

```bash
systemctl status certbot.timer
```

---

## نکات امنیتی

Cloudflare API Token در این فایل ذخیره می‌شود:

```text
/etc/letsencrypt/cloudflare.ini
```

اسکریپت permission فایل را روی مقدار امن زیر قرار می‌دهد:

```text
600
```

یعنی فقط کاربر root می‌تواند فایل را بخواند.

برای امنیت بیشتر:

* از Cloudflare Global API Key استفاده نکنید.
* فقط از API Token محدودشده استفاده کنید.
* Token را فقط به دامنه موردنیاز محدود کنید.
* Token را عمومی منتشر نکنید.
* فایل‌های `.ini`، `.env`، کلید خصوصی و certificate را داخل گیتهاب commit نکنید.

---

## خطاهای رایج

### خطای API Token

مطمئن شوید Token این دسترسی‌ها را دارد:

```text
Zone → DNS → Edit
Zone → Zone → Read
```

### خطا هنگام حذف گواهی

اگر حذف گواهی انجام نشد، نام دقیق certificate را بررسی کنید:

```bash
sudo certbot certificates
```

گاهی نام certificate دقیقاً با دامنه یکی نیست و ممکن است چیزی مثل این باشد:

```text
example.com-0001
```

### خطای DNS Challenge

مطمئن شوید دامنه داخل Cloudflare فعال است و API Token به zone صحیح دسترسی دارد.

### خطا هنگام reload کردن Nginx

ابتدا کانفیگ Nginx را تست کنید:

```bash
sudo nginx -t
```

اگر خطا وجود داشت، مسیر certificate یا server block را اصلاح کنید.

---

## حذف گواهی

برای حذف از طریق اسکریپت، آن را اجرا کنید و گزینه زیر را انتخاب کنید:

```text
3) فقط حذف گواهی فعلی
```

یا به‌صورت دستی:

```bash
sudo certbot delete --cert-name your-domain.com
```

---

## ساختار پیشنهادی پروژه

ساختار پیشنهادی repository:

```text
PD-Cert/
├── install.sh
├── README.md
├── LICENSE
└── .gitignore
```

---

## فایل پیشنهادی `.gitignore`

```gitignore
# Secrets
*.ini
*.env
.env
cloudflare.ini

# SSL private files
*.key
*.pem
*.crt
*.csr

# Logs
*.log

# System files
.DS_Store
Thumbs.db
```

---

## هشدار

این اسکریپت روی سرور شما package نصب می‌کند و فایل‌های مربوط به SSL را تغییر می‌دهد. قبل از اجرا روی سرور production، محتوای اسکریپت را بررسی کنید.

اجرای مستقیم اسکریپت با `curl | bash` راحت است، اما روی سرورهای حساس بهتر است ابتدا محتوای اسکریپت را بررسی کنید:

```bash
curl -Ls https://raw.githubusercontent.com/Mehdi682007/PD-Cert/main/install.sh
```

سپس اجرا کنید:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/Mehdi682007/PD-Cert/main/install.sh)
```

---

## مشارکت

مشارکت در این پروژه آزاد است.

شما می‌توانید از این روش‌ها کمک کنید:

* گزارش باگ
* پیشنهاد قابلیت جدید
* بهبود مستندات
* اضافه کردن پشتیبانی برای توزیع‌های بیشتر لینوکس
* ارسال Pull Request

---

## لایسنس

این پروژه تحت لایسنس MIT منتشر می‌شود.
