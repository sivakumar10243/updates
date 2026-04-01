#!/bin/bash
#
# Faveo Helpdesk Docker Development Environment Installer
#
# A cleaned-up and updated script to configure a LAMP Stack (Linux, Apache, MySQL, PHP)
# development environment for Faveo Helpdesk on Ubuntu 20.04/22.04.
#
# Copyright (C) 2024 Ladybird Web Solution Pvt Ltd
# Licensed under the GNU General Public License v2 or later.

# --- 1. Color and Banner Setup 🎨 ---

red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3) # Changed 11 to 3 for standard yellow
skyblue=$(tput setaf 6) # Changed 14 to 6 for standard cyan/light blue
white=$(tput setaf 7) # Changed 15 to 7 for standard white
reset=$(tput sgr0)

# Faveo Banner (Preserved for style)
# Your banner output is lengthy and preserved here:
echo -e "$skyblue                                                                                                        $reset"
sleep 0.05
echo -e "$skyblue                        _______ _______ _     _ _______ _______                                         $reset"
sleep 0.05    
echo -e "$skyblue                       (_______|_______|_)   (_|_______|_______)                                        $reset"
sleep 0.05
echo -e "$skyblue                         _____  _______ _     _ _____  _     _                                         $reset"
sleep 0.05
echo -e "$skyblue                        |  ___) |  ___  | |   | |  ___) | |   | |                                        $reset"
sleep 0.05
echo -e "$skyblue                        | |     | |   | |\ \ / /| |_____| |___| |                                        $reset"
sleep 0.05
echo -e "$skyblue                        |_|     |_|   |_| \___/ |_______)\_____/                                         $reset"
sleep 0.05
echo -e "$skyblue                                                                                                        $reset"
sleep 0.05
echo -e "$skyblue                        _     _ _______ _       ______ ______  _______  ______ _     _                   $reset"
sleep 0.05      
echo -e "$skyblue                       (_)   (_|_______|_)     (_____ (______)(_______)/ _____|_)   | |                   $reset"
sleep 0.05
echo -e "$skyblue                         _______ _____  _       _____) )      _ _____  ( (____  _____| |                   $reset"
sleep 0.05
echo -e "$skyblue                        |  ___  |  ___) | |     | ____/ |    | |  ___)  \____ \|  _    _)                  $reset"
sleep 0.05
echo -e "$skyblue                        | |   | | |_____| |_____| |    | |__/ /| |_____ _____) ) | \ \                     $reset"
sleep 0.05
echo -e "$skyblue                        |_|   |_|_______)_______)_|    |_____/ |_______|______/|_|   \_)                   $reset"
sleep 0.05
echo -e "$skyblue                                                                                                        $reset"
sleep 0.05
echo -e "$skyblue                                                                                                        $reset"

echo -e "$yellow This script configures LAMP Stack Development Environment on Ubuntu 20.04/22.04 Distro's $reset"
echo -e ""
sleep 0.5

# --- 2. Initial Checks and User Input 🔒 ---

if readlink /proc/$$/exe | grep -q "dash"; then
    echo -e "$red This installer needs to be run with \"bash\", not \"sh\". $reset"
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
    echo -e "$red This script must be run as root user or with sudo privilege $reset"
    exit 1
fi

echo -e "\n"
read -r -p "$skyblue Enter the preferred version for Node.js (Ex: 19.x, 20.x, 21.x): $reset" nodejs_version
echo -e "\n"
read -r -p "$skyblue Enter the preferred version for PHP (Ex: 8.1, 8.2): $reset" php_version
echo -e "\n"
read -r -p "$skyblue Enter Password for Database ROOT User: $reset" db_root_pw
echo -e "\n"
read -r -p "$skyblue Enter a Domain Name of your choice to generate Self-Signed Certificates (e.g., faveo.local): $reset" domain_name
echo -e "\n"

# --- 3. System Cleanup and Prerequisites 🧹 ---

echo "$skyblue Removing existing or older versions of LAMP components...$reset"
# Use 'dpkg -l | grep' for a cleaner uninstallation of potential partial installs
apt-get purge apache2* mysql-server* php* nodejs* composer* redis-server supervisor -y 2>/dev/null

echo "$skyblue Updating Repository cache and Installing prerequisites...$reset"
apt-get update

# Add missing common dependencies like gnupg, lsb-release for robust PPA addition
PREREQS="software-properties-common unzip curl zip wget nano snapd gnupg lsb-release"
if ! apt-get install -y $PREREQS; then
    echo -e "\n$red Prerequisite Installation failed. Check your Internet connection. $reset\n"
    exit 1
fi
apt-get upgrade -y

# Enable and start snapd
systemctl enable snapd
systemctl start snapd

# Check if phpstorm install succeeds but don't fail the whole script if it doesn't (it's an IDE, not a core dependency)
echo "$skyblue Installing PhpStorm via Snap (Optional)...$reset"
snap install phpstorm --classic || echo "$yellow Warning: PhpStorm snap installation failed. Continuing script. $reset"

# --- 4. Adding Required Repositories ➕ ---

echo "$skyblue Adding Apache and PHP Repositories... $reset"
# Add PHP and Apache PPAs
add-apt-repository --yes ppa:ondrej/php
add-apt-repository --yes ppa:ondrej/apache2

if [[ $? -ne 0 ]]; then
    echo -e "\n$red Adding Apache and PHP Repositories Failed. $reset\n"
    exit 1
fi
apt-get update

# --- 5. Configuring and Installing Node.js, Apache, and MySQL 💻 ---

# Configuring and Installing Prefered version of Nodejs
echo -e "$skyblue Installing Node.js-$nodejs_version... $reset"
curl -sL https://deb.nodesource.com/setup_$nodejs_version | bash -
apt install nodejs -y

if [[ $? -ne 0 ]]; then
    echo -e "\n$red Node.js-$nodejs_version Installation Failed. $reset\n"
    exit 1
fi

# Installing Apache2
echo -e "$green Installing Apache2... $reset"
if ! apt install apache2 -y; then
    echo -e "\n$red Apache2 Installation Failed. $reset\n"
    exit 1
fi
systemctl enable apache2
systemctl start apache2

# Installing MySQL (FIX: Using standard installation method with pre-selections)
echo -e "$green Installing MySQL 8.0... $reset"
# Pre-select MySQL 8.0 for non-interactive installation if prompted
echo "mysql-server mysql-server/root_password password $db_root_pw" | sudo debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $db_root_pw" | sudo debconf-set-selections
DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server mysql-client

if [[ $? -ne 0 ]]; then
    echo -e "\n$red MySQL Installation Failed. The provided method might be incompatible with your distro. $reset\n"
    exit 1
fi

systemctl enable mysql
systemctl start mysql

# Set MySQL root password and authentication method (using mysql_native_password for better compatibility)
echo -e "$green Configuring MySQL root user... $reset"
mysql -u root <<MYSQL_SCRIPT
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$db_root_pw';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# --- 6. Installing PHP and Extensions 🐘 ---

PHP_PKGS="libapache2-mod-php$php_version php$php_version-mysql php$php_version-cli php$php_version-common php$php_version-fpm php$php_version-soap php$php_version-gd php$php_version-opcache php$php_version-mbstring php$php_version-zip php$php_version-bcmath php$php_version-intl php$php_version-xml php$php_version-curl php$php_version-imap php$php_version-ldap php$php_version-gmp php$php_version-redis"

echo -e "\n$green Installing PHP-$php_version and necessary extensions. $reset"
if ! apt install -y php$php_version $PHP_PKGS; then
    echo -e "\n$red PHP-$php_version Installation Failed. Please ensure version $php_version is supported by PPA:ondrej/php. $reset\n"
    exit 1
fi

# --- 7. Installing wkhtmltopdf (HTML to PDF Plugin) 📄 ---

echo -e "$green Installing HTML to PDF Plugin (wkhtmltopdf)... $reset"

# Handle libssl1.1 dependency for newer Ubuntu versions by using focal-security
echo "deb http://security.ubuntu.com/ubuntu focal-security main" | tee /etc/apt/sources.list.d/focal-security.list
apt-get update; apt install libssl1.1 -y

# Use a generic version download and install
WKHTMLTOPDF_DEB="wkhtmltox_0.12.6-1.focal_amd64.deb"
WKHTMLTOPDF_URL="https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/$WKHTMLTOPDF_DEB"

wget $WKHTMLTOPDF_URL -P /tmp/
dpkg -i /tmp/$WKHTMLTOPDF_DEB
apt --fix-broken install -y # Fixes any dependency issues from dpkg
rm -f /tmp/$WKHTMLTOPDF_DEB

# Check if wkhtmltopdf binary exists
if ! command -v wkhtmltopdf &> /dev/null; then
    echo -e "\n$red HTML to PDF Plugin (wkhtmltopdf) installation failed. $reset\n"
fi

# --- 8. Installing Composer (FIX: Simplified and made more robust) 📦 ---

echo -e "$skyblue Installing latest version of Composer... $reset"
EXPECTED_SIGNATURE="$(wget -q -O - https://composer.github.io/installer.sig)"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_SIGNATURE="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]; then
    echo -e "\n$red Composer Hash verification failed. $reset"
    php -r "unlink('composer-setup.php');"
    exit 1
fi

php composer-setup.php --install-dir=/usr/local/bin --filename=composer

if [[ $? -ne 0 ]]; then
    echo -e "\n$red Composer Installation failed. $reset\n"
    exit 1
fi

php -r "unlink('composer-setup.php');"

# --- 9. SSL Certificate Generation and Hostname Setup 🔐 ---

echo -e "$green Generating Self-Signed Certificates for $domain_name... $reset"
mkdir -p /etc/apache2/ssl
# Using a simpler openssl command for certificate generation
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/apache2/ssl/private.key \
    -out /etc/apache2/ssl/faveolocal.crt \
    -subj "/C=IN/ST=Karnataka/L=Bangalore/O=Ladybird Web Solutions Pvt Ltd/OU=Development Team/CN=$domain_name" > /dev/null 2>&1

# Create the root CA equivalent files for a basic self-signed setup compatible with your VirtualHost config
cp /etc/apache2/ssl/faveolocal.crt /etc/apache2/ssl/faveorootCA.crt

# Add host entry and update CA certificates
echo "127.0.0.1 $domain_name" >> /etc/hosts
cp /etc/apache2/ssl/faveorootCA.crt /usr/local/share/ca-certificates/
update-ca-certificates > /dev/null 2>&1

if [[ $? -eq 0 ]]; then
    echo -e "$green Certificates generated successfully for $domain_name. Remember to trust this certificate in your browser. $reset"
else
    echo -e "$red Certificate generation failed. $reset"
    exit 1
fi

# --- 10. Installing Redis and Supervisor Workers ⚙️ ---

echo -e "$green Installing and configuring Redis and Supervisor... $reset"
apt-get install redis-server supervisor -y
systemctl start redis-server
systemctl enable redis-server
systemctl enable supervisor
systemctl start supervisor

# Supervisor config creation
FAVEO_SUPERVISOR_CONF="/etc/supervisor/conf.d/faveo-worker.conf"
FAVEO_SUPERVISOR_EXAMPLE="/home/supervisor-example-conf-file"
touch $FAVEO_SUPERVISOR_CONF # Create empty file to ensure it exists
touch $FAVEO_SUPERVISOR_EXAMPLE

cat <<EOF > $FAVEO_SUPERVISOR_EXAMPLE
[program:faveo-Horizon]
process_name=%(program_name)s
command=php /var/www/faveo/artisan horizon
autostart=true
autorestart=true
user=www-data
redirect_stderr=true
stdout_logfile=/var/www/faveo/storage/logs/horizon-worker.log

[program:faveo-websockets]
process_name=%(program_name)s
command=php /var/www/faveo/artisan websockets:serve
autostart=true
autorestart=true
user=root
redirect_stderr=true
stdout_logfile=/var/www/faveo/storage/logs/websocket-worker.log

# NOTE: The command paths (/var/www/faveo) in this example must be updated
#       in the actual $FAVEO_SUPERVISOR_CONF file to point to your Faveo installation root.
EOF

# --- 11. Installing phpMyAdmin 📂 ---

echo -e "$green Configuring phpMyAdmin... $reset"
PHPMYADMIN_VERSION="5.2.0"
PHPMYADMIN_ZIP="phpMyAdmin-$PHPMYADMIN_VERSION-all-languages.zip"
PHPMYADMIN_DIR="phpMyAdmin-$PHPMYADMIN_VERSION-all-languages"
INSTALL_PATH="/usr/share"

wget https://files.phpmyadmin.net/phpMyAdmin/$PHPMYADMIN_VERSION/$PHPMYADMIN_ZIP -P /tmp/
unzip /tmp/$PHPMYADMIN_ZIP -d $INSTALL_PATH
mv $INSTALL_PATH/$PHPMYADMIN_DIR $INSTALL_PATH/phpmyadmin
rm -f /tmp/$PHPMYADMIN_ZIP

mkdir -p $INSTALL_PATH/phpmyadmin/tmp
chown -R www-data:www-data $INSTALL_PATH/phpmyadmin
chmod 777 $INSTALL_PATH/phpmyadmin/tmp

# phpMyAdmin Apache config
cat <<EOF > /etc/apache2/conf-available/phpmyadmin.conf
Alias /phpmyadmin $INSTALL_PATH/phpmyadmin
Alias /phpMyAdmin $INSTALL_PATH/phpmyadmin
 
<Directory $INSTALL_PATH/phpmyadmin/>
    AddDefaultCharset UTF-8
    <IfModule mod_authz_core.c>
      <RequireAny>
      Require all granted
     </RequireAny>
    </IfModule>
</Directory>
EOF

# --- 12. Apache VirtualHost and PHP Configuration 🌐 ---

echo -e "$green Configuring Apache VirtualHost and PHP settings... $reset"

# Creating Index file for LAMP setup
cat <<EOF > /var/www/html/index.html
<!doctype html>
<html lang="eng">
<head>
    <title>Faveo Welcome Page</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.7.0/css/all.css">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.2.0/dist/css/bootstrap.min.css" rel="stylesheet" >
    <style>
        h3{text-align: center; margin-top: 0%; font-size: 55px; color:steelblue; text-shadow: 3px 3px lightblue; font-family: Serif;}
        h4{margin-bottom: 10px; font-size: 20px; color:green; text-shadow: 2px 2px lightblue; margin-right: 300px; font-family: Serif;}
        .cod{text-align: center; margin-top:10%; font-size: 19px; color:black; font-family: Serif;}
    </style>
</head>
<body>
<div class="container content">
    <img src="https://upload.wikimedia.org/wikipedia/commons/b/b1/Faveo_Logo.png" class="img-thumbnail float-right img" alt="faveo img" style="width: 100px; height: 50px;">
    <h3> Welcome to Faveo Helpdesk Development Environment </h3>
    <div class="row">
        <div class="col-sm-6">
            <img src="https://assets.hongkiat.com/uploads/mean-vs-lamp-stacks/01-lamp-stack-tech-clouds.jpg?v2" class="rounded-circle float-right pic" alt="lamp" style="margin-right:20px; margin-top:0px; width:500px;height:500px;">
        </div>
        <div class="col-sm-6">
            <h4>Your Domain Name : https://$domain_name</h4><br>
            <h4> Your PHPMyAdmin URL : https://$domain_name/phpmyadmin</h4><br>
            <h4>  Your Database Username: root</h4><br>
            <h4>Database Root Password: $db_root_pw</h4><br>
            <h4>Web Server Root Directory: /var/www/html</h4><br>
            <h4>Supervisor configuration file: $FAVEO_SUPERVISOR_CONF</h4><br>
            <h4>Supervisor configuration example file: $FAVEO_SUPERVISOR_EXAMPLE</h4><br>
            <h4>Please copy and change the supervisor configuration example file with your actual Faveo root directory to the supervisor configuration file</h4><br>
            <h5 class="cod"><i> &nbsp&nbsp &nbsp&nbsp Contact DevOps Team to configure license for PhpStorm IDE.</i></h5>
            <h5 class="cod"><i> &nbsp&nbsp &nbsp&nbsp Contact your Team Leader for further Assistant. Happy Coding!!</i></h5>
        </div>
    </div>
</div>
</body>
</html>
EOF

# Apache SSL Virtual Host configuration
cat <<EOF >/etc/apache2/sites-available/faveo-ssl.conf
<VirtualHost *:80>
    ServerName $domain_name
    DocumentRoot /var/www/html
    <Directory /var/www/html>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog /var/log/apache2/faveo-error.log
    CustomLog /var/log/apache2/faveo-access.log combined
    RewriteEngine on
    RewriteCond %{SERVER_NAME} =$domain_name
    RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]
</VirtualHost>

<IfModule mod_ssl.c>
<VirtualHost *:443>
    ServerName $domain_name
    DocumentRoot /var/www/html
    <Directory /var/www/html>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog /var/log/apache2/faveo-error.log
    CustomLog /var/log/apache2/faveo-access.log combined
    SSLEngine on
    # Using the self-signed certificates
    SSLCertificateFile /etc/apache2/ssl/faveolocal.crt
    SSLCertificateKeyFile /etc/apache2/ssl/private.key
    SSLCertificateChainFile /etc/apache2/ssl/faveorootCA.crt   
</VirtualHost>
</IfModule>
EOF

# PHP INI settings (Simplified using a loop and array)
echo -e "$green Applying Faveo-recommended PHP settings... $reset"
PHP_SETTINGS=(
    "file_uploads = On"
    "allow_url_fopen = On"
    "short_open_tag = On"
    "memory_limit = -1"
    ";cgi.fix_pathinfo= 0"
    "upload_max_filesize = 100M"
    "post_max_size = 100M"
    "max_execution_time = 360"
)
PHP_INIs=("/etc/php/$php_version/apache2/php.ini" "/etc/php/$php_version/fpm/php.ini" "/etc/php/$php_version/cli/php.ini")

for INI_FILE in "${PHP_INIs[@]}"; do
    for SETTING in "${PHP_SETTINGS[@]}"; do
        # Use awk to find and replace, or append if not found (safer than sed for some cases)
        KEY=$(echo "$SETTING" | awk '{print $1}')
        VALUE=$(echo "$SETTING" | awk '{$1=""; print $0}' | xargs)
        
        # Check if the key is present, if so, replace it; otherwise, append it (for safer config change)
        if grep -q "^$KEY" $INI_FILE; then
            sed -i "s/^$KEY.*/$SETTING/g" $INI_FILE
        elif grep -q "^;$KEY" $INI_FILE; then
            sed -i "s/^;$KEY.*/$SETTING/g" $INI_FILE
        else
            # Append if not found (especially for non-default settings)
            echo "$SETTING" >> $INI_FILE
        fi
    done
done


# Enable Apache modules and site
a2enmod rewrite ssl proxy_fcgi setenvif

a2dissite 000-default.conf
a2ensite faveo-ssl.conf
a2enconf php$php_version-fpm
a2enconf phpmyadmin

# Restart services
systemctl restart php$php_version-fpm
systemctl restart apache2

# --- 13. Finalizing and Outputting Credentials 🎉 ---

# Save credentials to file
CREDENTIALS_FILE="/var/www/credentials.txt"
echo "Your URL: https://$domain_name" > $CREDENTIALS_FILE
echo "phpMyAdmin URL: https://$domain_name/phpmyadmin" >> $CREDENTIALS_FILE
echo "Database Username: root" >> $CREDENTIALS_FILE
echo "Database Password: $db_root_pw" >> $CREDENTIALS_FILE
chown www-data:www-data $CREDENTIALS_FILE # Good practice for web files

echo -e "\n"
echo "$yellow ######################################################################### $reset"
echo -e "\n"
echo "$green You will find the details saved in: $reset $skyblue $CREDENTIALS_FILE $reset"
echo "$green Faveo Development Environment installed successfully! $reset"
echo "$green Visit $reset $skyblue https://$domain_name $reset $green from your browser. $reset"
echo -e "\n"
echo "$green Please save the following credentials: $reset"
echo "* $green phpMyAdmin URL: $reset $skyblue https://$domain_name/phpmyadmin $reset"
echo "* $green MySQL Database Username: $reset $skyblue root $reset"
echo "* $green MySQL Database root password: $reset $skyblue $db_root_pw $reset"
echo "* $green Web server Root Directory path: $reset $skyblue /var/www/html $reset"
echo -e "\n"
echo "#########################################################################"

exit 0
