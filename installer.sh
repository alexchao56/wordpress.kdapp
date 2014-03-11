#/bin/bash
dbname="dbwordpress"
dbuser="wordpressuser"
dbpass="wppassword"

#download wordpress
curl -O http://wordpress.org/latest.tar.gz
#unzip wordpress
tar -zxvf latest.tar.gz
#change dir to wordpress
cd wordpress
#create wp config
cp wp-config-sample.php wp-config.php
#set database details with perl find and replace
sed -e "s/database_name_here/$dbname/g" wp-config.php
sed -e "s/username_here/$dbuser/g" wp-config.php
sed "s/password_here/$dbpass/g" wp-config.php
#create uploads folder and set permissions
mkdir wp-content/uploads
chmod 777 wp-content/uploads
#remove zip file
rm ../latest.tar.gz
