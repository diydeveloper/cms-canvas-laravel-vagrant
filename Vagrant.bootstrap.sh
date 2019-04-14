#!/usr/bin/env bash

# ---------------------------------------
#          Update The Box
# ---------------------------------------

# Add PHP repositories
add-apt-repository -y ppa:ondrej/php

# Downloads the package lists from the repositories
# and "updates" them to get information on the newest
# versions of packages and their dependencies
apt-get update

# ---------------------------------------
#          Apache Setup
# ---------------------------------------

# Installing Packages
apt-get install -y apache2

# Remove /var/www default
rm -rf /var/www/
mkdir /var/www

# Add ServerName to apache2.conf
echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Setup hosts file
VHOST=$(cat <<EOF
<VirtualHost *:80>
  DocumentRoot "/var/www/public"
  ServerName localhost
  <Directory "/var/www/public">
    AllowOverride All
  </Directory>
</VirtualHost>
EOF
)
echo "${VHOST}" > /etc/apache2/sites-available/000-default.conf

# Enable mod_rewrite
a2enmod rewrite

# Restart apache
service apache2 restart

# ---------------------------------------
#          PHP Setup
# ---------------------------------------

# Installing packages
apt-get install -y php7.2 libapache2-mod-php7.2 php7.2-curl php7.2-gd php7.2-mbstring php7.2-xml php7.2-zip php-gettext zip unzip

# ---------------------------------------
#          MySQL Setup
# ---------------------------------------
 
# Setting MySQL root user password root/root
debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'
 
# Installing packages
apt-get install -y mysql-server mysql-client php7.2-mysql

# ---------------------------------------
#          PHPMyAdmin Setup
# ---------------------------------------
 
# Default PHPMyAdmin Settings
debconf-set-selections <<< 'phpmyadmin phpmyadmin/dbconfig-install boolean true'
debconf-set-selections <<< 'phpmyadmin phpmyadmin/app-password-confirm password root'
debconf-set-selections <<< 'phpmyadmin phpmyadmin/mysql/admin-pass password root'
debconf-set-selections <<< 'phpmyadmin phpmyadmin/mysql/app-pass password root'
debconf-set-selections <<< 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2'
 
# Install PHPMyAdmin
apt-get install -y phpmyadmin
 
# Restarting apache to make changes
service apache2 restart

# ---------------------------------------
#          Tools Setup
# ---------------------------------------

# Install cURL
apt-get install -y curl

# Install Git
apt-get install -y git

# Install Vim
apt-get install -y vim

# ---------------------------------------
#          Composer Setup
# ---------------------------------------

# Download composer installer
curl -s https://getcomposer.org/installer | php

# Make Composer available globally
mv composer.phar /usr/local/bin/composer

# ---------------------------------------
#          Laravel Setup
# ---------------------------------------

# Create project
composer create-project laravel/laravel /var/www/ "5.8.*"

# Set directory permissions
chmod -R 777 /var/www/storage/
chmod -R 777 /var/www/bootstrap/cache/

# Change to framework root directory
cd /var/www

# Add required packages to the laravel framework
composer config github-protocols https
composer config repositories.cmscanvas '{"type": "vcs", "url": "https://github.com/diyphpdeveloper/cms-canvas.git", "no-api": true}'
composer config repositories.twigbridge '{"type": "vcs", "url": "https://github.com/diyphpdeveloper/TwigBridge.git", "no-api": true}'
composer require diyphpdeveloper/twigbridge:'dev-master as 1.0.x-dev'
composer require diyphpdeveloper/cmscanvas:dev-master
composer update

# ---------------------------------------
#          CmsCanvas Setup
# ---------------------------------------

# Create cmscanvas database
mysql -uroot -proot -e "create database cmscanvas"

# Update database credentials in .env config
sed -i -e 's/DB_DATABASE=.*/DB_DATABASE=cmscanvas/' -e 's/DB_USERNAME=.*/DB_USERNAME=root/' -e 's/DB_PASSWORD=.*/DB_PASSWORD=root/' /var/www/.env

# Add Service Providers
sed -i "/Illuminate\\\View\\\ViewServiceProvider::class,/ r /vagrant/templates/service_providers.txt" /var/www/config/app.php

# Add Facades
sed -i "/'View'[ ]*=>[ ]*Illuminate\\\Support\\\Facades\\\View::class,/ r /vagrant/templates/facades.txt" /var/www/config/app.php

# Update Auth Model
sed -i "s/'model'[ ]*=>.*/'model' => CmsCanvas\\\Models\\\User::class,/" /var/www/config/auth.php

# Replace default routes 
cat /vagrant/templates/web.txt > routes/web.php

# Publish package files
php artisan vendor:publish

# Run migrations
php artisan migrate

# Seed database
php artisan db:seed --class="CmsCanvas\Database\Seeds\DatabaseSeeder"

# Make public directories writable
chmod 777 public/diyphpdeveloper/cmscanvas/thumbnails
chmod 777 public/diyphpdeveloper/cmscanvas/uploads

# Remove the root welcome route


# ---------------------------------------
#            Install Samba
# ---------------------------------------

# Installing Samba
apt-get install -y samba

# Append share info to samba config
cat /vagrant/templates/smb.txt >> /etc/samba/smb.conf

# Restart services
service smbd restart
service nmbd restart
