#!/bin/bash

echo "Welcome to WordPress Installer for Koding!"

OUT="/tmp/_wordpressinstaller.out"
mkdir -p $OUT

touch $OUT/"0-Asking for sudo password"
sudo

touch $OUT/"10-Getting WordPress"
wget -O wordpress.tar.gz http://wordpress.org/latest.tar.gz
tar -zxvf wordpress.tar.gz
cd wordpress
cp -R . /var/www
chown -R www-data /var/www/wordpress

touch $OUT/"40-Turning on MySQL."
sudo service mysql start

touch $OUT/"50-Log in to mysql server as root user."
mysql -u root -p

touch $OUT/"60-Create database with name dbwordpress."
CREATE DATABASE dbwordpress;

touch $OUT/"70-Create a new user of username wordpressuser."
CREATE USER wordpressuser;

touch $OUT/"85-Create password 'wppassword' for user wordpressuser."
SET PASSWORD FOR wordpressuser = PASSWORD("wppassword");

touch $OUT/"90-Grant user wordpressuser all permissions on the database."
GRANT ALL PRIVILEGES ON dbwordpress.* TO wordpressuser@localhost IDENTIFIED BY ‘wppassword’;

touch $OUT/"95 - Flushing Priviliges"
FLUSH PRIVILEGES;

touch $OUT/"100-WordPress installation completed."
rm ../wordpress.tar.gz
