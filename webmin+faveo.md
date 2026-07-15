# Ubuntu 24.04 Webmin + Faveo Server Installation Guide

## Overview

This document explains the complete installation and configuration steps for setting up:

- Webmin
- Apache Web Server
- SSL Configuration
- PHP 8.4
- Ioncube Loader
- MySQL 8.0
- phpMyAdmin
- Redis
- Supervisor
- Node.js
- Yarn
- Composer
- SSH User Configuration
- Webmin User Permission Setup

Operating System:

```

Ubuntu 24.04

````

---

# 1. Install Webmin

## Download Webmin Repository Setup Script

```bash
curl -o webmin-setup-repo.sh https://raw.githubusercontent.com/webmin/webmin/master/webmin-setup-repo.sh
````

Run the installation script:

```bash
sudo sh webmin-setup-repo.sh
```

Install Webmin and Usermin:

```bash
sudo apt-get install --install-recommends webmin usermin
```

---

# 2. Access Webmin

After installation, Webmin can be accessed using:

```
https://IP:10000
```

or

```
https://domain:10000
```

Example:

```
https://webmin.faveodemo.com:10000
```

---

# 3. Set Root Password for Webmin Login

Set the root password:

```bash
passwd root
```

Use the same credentials for Webmin login.

```
Username:
root

Password:
<root password>
```

---

# 4. Install Apache Web Server from Webmin

Login to Webmin.

Search:

```
Apache Webserver
```

Click:

```
Install Now
```

Webmin will list the required packages.

Click:

```
Install Now
```

Apache2 installation will start.

---

# 5. Configure Apache Virtual Host

Create Apache configuration:

```bash
nano /etc/apache2/sites-available/faveo.conf
```

Add the configuration:

```apache
<VirtualHost *:80>
    ServerName webmin.faveodemo.com 
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/

    <Directory /var/www/html/>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/faveo-error.log
    CustomLog ${APACHE_LOG_DIR}/faveo-access.log combined

# Uncomment the below lines and replace the Server-IP and Domainame to configure IP to Domainname rewrite rule

#    RewriteEngine on
#    RewriteCond %{HTTP_HOST} ^--Server-IP--
#    RewriteRule (.*) http://--Domainname--

</VirtualHost>
```

Disable default site:

```bash
a2dissite 000-default.conf
```

Enable Faveo site:

```bash
a2ensie faveo.conf
```

---

# 6. Configure SSL Certificate

Install Certbot Apache plugin:

```bash
apt install python3-certbot-apache
```

Generate SSL certificate:

```bash
certbot --apache -d webmin.faveodemo.com
```

---

# 7. Configure Webmin SSL Certificate

View Apache SSL configuration:

```bash
cat /etc/apache2/sites-enabled/faveo-le-ssl.conf
```

Edit Webmin SSL configuration:

```bash
sudo nano /etc/webmin/miniserv.conf
```

Comment the existing certificate:

```
#keyfile=/etc/webmin/miniserv.pem
```

Copy the SSL certificate path from:

```
faveo-le-ssl.conf
```

and configure the same certificate path in Webmin.

Restart Webmin:

```bash
sudo systemctl restart webmin
```

Check status:

```bash
sudo systemctl status webmin
```

---

# 8. Install Utility Packages

```bash
apt install -y git wget curl unzip nano zip
```

---

# 9. Install PHP 8.4

Add PHP repository:

```bash
add-apt-repository ppa:ondrej/php
```

Update packages:

```bash
apt update
```

Install PHP packages:

```bash
apt install -y php8.4 libapache2-mod-php8.4 php8.4-mysql \
    php8.4-cli php8.4-common php8.4-fpm php8.4-soap php8.4-gd \
    php8.4-opcache php8.4-mbstring php8.4-zip \
    php8.4-bcmath php8.4-intl php8.4-xml php8.4-curl \
    php8.4-imap php8.4-ldap php8.4-gmp php8.4-redis php8.4-memcached
```

---

# 10. Install Ioncube Loader PHP 8.4

Download:

```bash
wget http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
```

Extract:

```bash
tar -xvf ioncube_loaders_lin_x86-64.tar.gz
```

Copy loader:

```bash
cp ioncube/ioncube_loader_lin_8.4.so /usr/lib/php/20240924
```

Add extension:

Apache:

```bash
sed -i '2 a zend_extension = "/usr/lib/php/20240924/ioncube_loader_lin_8.4.so"' /etc/php/8.4/apache2/php.ini
```

CLI:

```bash
sed -i '2 a zend_extension = "/usr/lib/php/20240924/ioncube_loader_lin_8.4.so"' /etc/php/8.4/cli/php.ini
```

FPM:

```bash
sed -i '2 a zend_extension = "/usr/lib/php/20240924/ioncube_loader_lin_8.4.so"' /etc/php/8.4/fpm/php.ini
```

---

# 11. PHP-FPM Configuration

Update:

```
/etc/php/8.4/fpm/php.ini
```

```bash
sudo sed -i -e 's/^file_uploads =.*/file_uploads = On/' \
           -e 's/^allow_url_fopen =.*/allow_url_fopen = On/' \
           -e 's/^short_open_tag =.*/short_open_tag = On/' \
           -e 's/^memory_limit =.*/memory_limit = 256M/' \
           -e 's/^;cgi.fix_pathinfo=1.*/cgi.fix_pathinfo = 0/' \
           -e 's/^upload_max_filesize =.*/upload_max_filesize = 100M/' \
           -e 's/^post_max_size =.*/post_max_size = 100M/' \
           -e 's/^max_execution_time =.*/max_execution_time = 360/' \
           /etc/php/8.4/fpm/php.ini
```

---

# 12. PHP CLI Configuration

```bash
sudo sed -i -e 's/^file_uploads =.*/file_uploads = On/' \
           -e 's/^allow_url_fopen =.*/allow_url_fopen = On/' \
           -e 's/^short_open_tag =.*/short_open_tag = On/' \
           -e 's/^memory_limit =.*/memory_limit = 256M/' \
           -e 's/^;cgi.fix_pathinfo=1.*/cgi.fix_pathinfo = 0/' \
           -e 's/^upload_max_filesize =.*/upload_max_filesize = 100M/' \
           -e 's/^post_max_size =.*/post_max_size = 100M/' \
           -e 's/^max_execution_time =.*/max_execution_time = 360/' \
           /etc/php/8.4/cli/php.ini
```

---

# 13. Enable PHP-FPM

```bash
a2enconf php8.4-fpm
```

Restart services:

```bash
systemctl restart php8.4-fpm
systemctl restart apache2
```

---

# 14. Install MySQL 8.0

```bash
sudo apt update
```

Install:

```bash
sudo apt install mysql-server
```

Start:

```bash
sudo systemctl start mysql
```

Enable:

```bash
sudo systemctl enable mysql
```

---

# 15. Install phpMyAdmin (Optional)

```bash
apt install -y phpmyadmin
```

Set PHP 8.4:

```bash
update-alternatives --config php
```

Select:

```
php8.4
```

---

# 16. Create MySQL User

Login to MySQL:

```sql
CREATE USER 'faveo'@'localhost' IDENTIFIED BY 'Faveo@12345';

GRANT ALL PRIVILEGES ON *.* TO 'faveo'@'localhost' WITH GRANT OPTION;

FLUSH PRIVILEGES;
```

Credentials:

```
Username:
faveo

Password:
Faveo@12345
```

---

# 17. Install Redis

```bash
apt-get install redis-server
```

Start:

```bash
systemctl start redis-server
```

Enable:

```bash
systemctl enable redis-server
```

---

# 18. Install Supervisor

```bash
apt-get install supervisor
```

Create configuration:

```bash
nano /etc/supervisor/conf.d/faveo-worker.conf
```

Add:

```ini
[program:faveo-Horizon]
process_name=%(program_name)s
command=php /var/www/html/faveo/artisan horizon
autostart=true
autorestart=true
user=www-data
redirect_stderr=true
stdout_logfile=/var/www/html/faveo/storage/logs/horizon-worker.log
```

Restart:

```bash
systemctl restart supervisor
```

---

# 19. Install Node.js and Yarn

Install Node.js:

```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
```

```bash
sudo apt install -y nodejs
```

Enable Corepack:

```bash
corepack enable
```

Install Yarn:

```bash
corepack prepare yarn@4.10.3 --activate
```

Check version:

```bash
yarn -v
```

---

# 20. Install Composer

Download installer:

```bash
curl -sS https://getcomposer.org/installer -o composer-setup.php
```

Verify:

```bash
HASH=$(curl -sS https://composer.github.io/installer.sig)
```

```bash
php -r "if (hash_file('sha384', 'composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
```

Install Composer:

```bash
php composer-setup.php --install-dir=/usr/local/bin --filename=composer --version=2.9.5
```

Remove installer:

```bash
rm composer-setup.php
```

Check:

```bash
composer --version
```

---

# 21. Create SSH User

Create user:

```bash
adduser faveo
```

Install sudo:

```bash
apt-get install sudo
```

Add user to sudo:

```bash
usermod -a -G sudo faveo
```

---

# 22. SSH Configuration

Edit:

```bash
nano /etc/ssh/sshd_config
```

Set:

```
PermitRootLogin yes

PasswordAuthentication yes

PubkeyAuthentication yes

ChallengeResponseAuthentication no

UsePAM yes
```

Add:

```
AllowUsers faveo
```

Restart SSH:

```bash
service ssh restart
```

Edit for cloud Server:

```bash
nano /etc/ssh/sshd_config.d/50-cloud-init.conf
```

```bash
nano 60-cloudimg-settings.conf
```

Set:

```
passwordauthentication yes
```

---

# 23. Create Webmin User

Navigate:

```
Webmin → Webmin Users
```

Click:

```
Create a new privileged user
```

Username:

```
faveo
```

Authentication:

```
Unix authentication
```

Create user.

---

# 24. Webmin Module Permissions

Edit user:

```
Webmin User → Edit Webmin User
```

Enable modules:

## System

* Disk Quotas
* Running Processes
* Scheduled Cron Jobs
* Software Packages

## Servers

* Apache Webserver
* MySQL Database Server
* SSH Server

## Tools

* Command Shell
* File Manager
* PHP Configuration
* Terminal
* Perl Modules
* System and Server Status
* Upload and Download

Save configuration.
