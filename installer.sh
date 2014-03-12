#/bin/bash
dbname="dbwordpress"
dbuser="wordpressuser"
dbpass="wppassword"

OUT="/tmp/_WordPressinstaller.out"
mkdir -p $OUT

#download wordpress
touch $OUT/"0-Downloading Wordpress"
curl -O http://wordpress.org/latest.tar.gz

#unzip wordpress
touch $OUT/"20-Unzipping Wordpress"
tar -zxvf latest.tar.gz

#change dir to wordpress
touch $OUT/"30-Changing directory to Wordpress"
cd wordpress

#create wp config
touch $OUT/"40-Creating wp config"
cp wp-config-sample.php wp-config.php

#set database details with perl find and replace
touch $OUT/"60-Setting up database profiles"
sed -e "s/database_name_here/$dbname/g" wp-config.php
sed -e "s/username_here/$dbuser/g" wp-config.php
sed "s/password_here/$dbpass/g" wp-config.php

touch $OUT/"90-Creating uploads folder and setting permissions"
#create uploads folder and set permissions
mkdir wp-content/uploads
chmod 777 wp-content/uploads

touch $OUT/"95-Removing Zip File"
#remove zip file
rm ../latest.tar.gz

touch $OUT/"100-Installation completed"

