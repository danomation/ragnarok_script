#!/bin/bash
MARIADB_ROOT_PASS=ragnarok
RAGNAROK_DATABASE_PASS=ragnarok
RO_PACKET_VER=20211103

#RAGNAROK_USER_PASS=ragnarok
#RATHENA_USER_PASS=ragnarok
sudo apt-get -y update && sudo NEEDRESTART_SUSPEND=1 apt-get upgrade --yes
sudo NEEDRESTART_SUSPEND=1 apt-get -y install net-tools
WAN_IP=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'`
echo ${WAN_IP}


#create ragnarok account
#adduser --quiet --disabled-password --shell /bin/bash --home /home/ragnarok --gecos "User" ragnarok
#echo "ragnarok:${RAGNAROK_USER_PASS}" | chpasswd
#usermod -aG sudo ragnarok
##

#install nginx as ragnarok
#su ragnarok
#sudo apt-get -y update && sudo NEEDRESTART_SUSPEND=1 apt-get upgrade --yes
sudo NEEDRESTART_SUSPEND=1 apt-get -y install nginx
sudo NEEDRESTART_SUSPEND=1 apt-get install php8.1-fpm -y
cd /etc/nginx/sites-available/
mv default default.old
echo "server {
        listen 80 default_server;
        listen [::]:80 default_server;


    root /var/www/html;
    index index.php index.html index.htm;


        server_name _;


         location / {
                      try_files \$uri \$uri/ /index.php\$is_args\$args;
         }

         location ~ \.php\$ {
            fastcgi_split_path_info ^(.+\.php)(/.+)\$;
            fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
            fastcgi_index index.php;
            include fastcgi.conf;
    }

}
" > default
echo " <html xmlns=\"http://www.w3.org/1999/xhtml\">    
  <head>      
    <title>ragnarok.sh</title>      
    <meta http-equiv=\"refresh\" content=\"0;URL='http://${WAN_IP}/roBrowserLegacy/examples/api-online-popup.html'\" />    
  </head>    
  <body> 
    <p>Redirecting to the <a href=\"http://${WAN_IP}/roBrowserLegacy/examples/api-online-popup.html\">
      example url</a>.</p> 
  </body>    
</html>" > /var/www/html/index.html
chmod 777 -R /etc/nginx/sites-available/
chmod 775 /var/www/html/index.html
systemctl restart nginx
systemctl restart php8.1-fpm

cd /var/www/html/
##
#clone repo for robrowser
cd /var/www/html/ && git clone https://github.com/MrAntares/roBrowserLegacy.git

cd /var/www/html/roBrowserLegacy/examples/
##
#no longer needed
#sed -i 's/5.135.190.4:443/'"$WAN_IP"':5999/g' /var/www/html/roBrowserLegacy/examples/api-online-popup.html
#sed -i 's/5.135.190.4/'"$WAN_IP"'/g' /var/www/html/roBrowserLegacy/examples/api-online-popup.html
#sed -i 's/7000/6900/g' /var/www/html/roBrowserLegacy/examples/api-online-popup.html
##

##
#hack to fix character selection screen
## I just disabled that....
#sed -i 's|charSelectNum = 2; //Old UI with mapname|charSelectNum = 1; //Old UI with mapname|g' /var/www/html/roBrowserLegacy/src/Engine/CharEngine.js
##

echo "
<!DOCTYPE html>
<html>
        <head>
                <title>Ragnarok</title>
                <meta name=\"viewport\" content=\"initial-scale=1.0, user-scalable=yes\" />
                <script type=\"text/javascript\" src=\"roBrowserLegacy/api.js\"></script>
                <script type=\"text/javascript\">
                        function initialize() {
                                var ROConfig = {
                                        target:        document.getElementById(\"robrowser\"),
                                        type:          ROBrowser.TYPE.FRAME,
                                        application:   ROBrowser.APP.ONLINE,
                                        development:    true,
                                        servers: [{
                                                display:     \"Demo Server\",
                                                desc:        \"roBrowser's demo server\",
                                                address:     \"${WAN_IP}\",
                                                port:        6900,
                                                version:     25,
                                                langtype:    12,
                                                packetver:   ${RO_PACKET_VER},
                                                packetKeys:  false,
                                                socketProxy: \"ws://${WAN_IP}:5999/\",
                                                adminList:   []
                                        }],
                                        skipServerList:  true,
                                        skipIntro:       true,
                                };
                                var RO = new ROBrowser(ROConfig);
                                RO.start();
                        }
                        window.addEventListener(\"load\", initialize, false);
                </script>
        </head>
        <body bgcolor=\"black\" style=\"overflow: hidden;\">
        <div id=\"robrowser\" style=\"height:100vh; width:100vw; position: fixed; left: 0; top:0; overflow: hidden;\"></div>
        </body>
</html>
" > /var/www/html/index.html
mkdir /home/ragnarok/
cd /home/ragnarok/
sudo NEEDRESTART_SUSPEND=1 apt-get -y install npm
npm install wsproxy -g

#create user for rathena
#adduser --quiet --disabled-password --shell /bin/bash --home /home/rathena --gecos "User" rathena
#echo "rathena:${RAGNAROK_USER_PASS}" | chpasswd
#usermod -aG sudo rathena
#su rathena

mkdir /home/rathena
cd /home/rathena
sudo apt-get -y update && sudo NEEDRESTART_SUSPEND=1 apt-get upgrade --yes

#install some pre-requisites

sudo NEEDRESTART_SUSPEND=1 apt -y install build-essential zlib1g-dev libpcre3-dev
sudo NEEDRESTART_SUSPEND=1 apt -y install libmariadb-dev libmariadb-dev-compat
cd /home/rathena & git clone https://github.com/rathena/rathena.git
cd /home/rathena/rathena

##
# testing a hack somebody provided
sed -i '48 s/^/\/\/ /' /home/rathena/rathena/src/config/packets.hpp
sed -i '56 s/^/\/\/ /' /home/rathena/rathena/src/config/packets.hpp
##

## old packetver
#bash /home/rathena/rathena/configure --enable-epoll=yes --enable-prere=no --enable-vip=no --enable-packetver=20131223
##
bash /home/rathena/rathena/configure --enable-epoll=yes --enable-prere=no --enable-vip=no --enable-packetver=${RO_PACKET_VER}

make clean && make server
sudo NEEDRESTART_SUSPEND=1 apt -y install mariadb-server
sudo NEEDRESTART_SUSPEND=1 apt-get -y install mariadb-client
sudo NEEDRESTART_SUSPEND=1 apt-get -y install expect

cd /home/rathena/rathena
MARIADB_STRING="FLUSH PRIVILEGES;
drop user if exists 'ragnarok'@'localhost';
drop user if exists ragnarok; DROP DATABASE IF EXISTS ragnarok;
create user 'ragnarok'@'localhost' identified by '${RAGNAROK_DATABASE_PASS}';
FLUSH PRIVILEGES;
CREATE DATABASE ragnarok; GRANT ALL ON ragnarok.* TO 'ragnarok'@'localhost';
FLUSH PRIVILEGES;"


        SECURE_MYSQL=$(expect -c "
        set timeout 3
        spawn mysql_secure_installation
        expect \"Enter current password for root (enter for none):\"
        send \"\r\"
        expect \"Switch to unix_socket authentication \[Y/n\]\"
        send \"n\r\"
        expect \"Set root password? \[Y/n\]\"
        send \"y\r\"
        expect \"New password:\"
        send \"${MARIADB_ROOT_PASS}\r\"
        expect \"Re-enter new password:\"
        send \"${MARIADB_ROOT_PASS}\r\"
        expect \"Remove anonymous users? \[Y/n\]\"
        send \"y\r\"
        expect \"Disallow root login remotely? \[Y/n\]\"
        send \"n\r\"
        expect \"Remove test database and access to it? \[Y/n\]\"
        send \"y\r\"
        expect \"Reload privilege tables now? \[Y/n\]\"
        send \"y\r\"
        expect eof
        ")

echo "${SECURE_MYSQL}"


        SECURE_MYSQL_2=$(expect -c "
        set timeout 3
        spawn mysql -u root -p -e \"${MARIADB_STRING}\"
        expect \"Enter password:\"
        send \"${MARIADB_ROOT_PASS}\r\"
        expect eof
        send \"exit\r\"
        expect eof
        ")

echo "${SECURE_MYSQL_2}"

        SECURE_MYSQL_3=$(expect -c "
        set timeout 3
        spawn mysql -u root -p
        expect \"Enter password:\"
        send \"${MARIADB_ROOT_PASS}\r\"
        expect eof
        send \"use ragnarok;\r\"
        expect eof
        send \"show tables;\r\"
        expect eof
        send \"source /home/rathena/rathena/sql-files/item_db.sql;\r\"
        expect eof
        send \"source /home/rathena/rathena/sql-files/item_db_equip.sql;\r\"
        expect eof
        send \"source /home/rathena/rathena/sql-files/item_db_etc.sql;\r\"
        expect eof
        send \"source /home/rathena/rathena/sql-files/item_db_re.sql;\r\"
        expect eof
        send \"source /home/rathena/rathena/sql-files/item_db_re_equip.sql;\r\"
        expect eof
        send \"source /home/rathena/rathena/sql-files/item_db_re_etc.sql;\r\"
        expect eof
        send \"source /home/rathena/rathena/sql-files/item_db2.sql;\r\"
        expect eof
        send \"source /home/rathena/rathena/sql-files/item_db_re_usable.sql;\r\"
        expect eof
        send \"source /home/rathena/rathena/sql-files/item_db_usable.sql;\r\"
        expect eof
        send \"source /home/rathena/rathena/sql-files/item_db2_re.sql;\r\"
        expect eof
        send \"source /home/rathena/rathena/sql-files/main.sql;\r\"
        expect eof
        send \"source /home/rathena/rathena/sql-files/mob_db.sql;\r\"
        expect eof
        send \"source /home/rathena/rathena/sql-files/mob_skill_db.sql;\r\"
        expect eof
        send \"source /home/rathena/rathena/sql-files/mob_db_re.sql;\r\"
        expect eof
        send \"source /home/rathena/rathena/sql-files/mob_db2.sql;\r\"
        expect eof
        send \"source /home/rathena/rathena/sql-files/mob_db2_re.sql;\r\"
        expect eof
        send \"source /home/rathena/rathena/sql-files/mob_skill_db2_re.sql;\r\"
        expect eof
        send \"source /home/rathena/rathena/sql-files/mob_skill_db_re.sql;\r\"
        expect eof
        send \"source /home/rathena/rathena/sql-files/mob_skill_db2.sql;\r\"
        expect eof
        send \"source /home/rathena/rathena/sql-files/web.sql;\r\"
        expect eof
        send \"source /home/rathena/rathena/sql-files/roulette_default_data.sql;\r\"
        expect eof
        send \"source /home/rathena/rathena/sql-files/logs.sql;\r\"
        expect eof
        send \"exit\r\"
        expect eof
        ")

echo "${SECURE_MYSQL_3}"
#set ragnarok database pass
sed -i 's/login_server_pw: ragnarok/login_server_pw: '"$RAGNAROK_DATABASE_PASS"'/g' /home/rathena/rathena/conf/login_athena.conf
sed -i 's/ipban_db_pw: ragnarok/ipban_db_pw: '"$RAGNAROK_DATABASE_PASS"'/g' /home/rathena/rathena/conf/login_athena.conf
sed -i 's/char_server_pw: ragnarok/char_server_pw: '"$RAGNAROK_DATABASE_PASS"'/g' /home/rathena/rathena/conf/login_athena.conf
sed -i 's/map_server_pw: ragnarok/map_server_pw: '"$RAGNAROK_DATABASE_PASS"'/g' /home/rathena/rathena/conf/login_athena.conf
sed -i 's/web_server_pw: ragnarok/web_server_pw: '"$RAGNAROK_DATABASE_PASS"'/g' /home/rathena/rathena/conf/login_athena.conf
sed -i 's/log_db_pw: ragnarok/log_db_pw: '"$RAGNAROK_DATABASE_PASS"'/g' /home/rathena/rathena/conf/login_athena.conf

sed -i 's/new_account: no/new_account: yes/g' /home/rathena/rathena/conf/login_athena.conf
sed -i 's/start_point: iz_int,18,26:iz_int01,18,26:iz_int02,18,26:iz_int03,18,26:iz_int04,18,26/start_point: prontera,155,187/g' /home/rathena/rathena/conf/char_athena.conf
sed -i 's/start_point_pre: new_1-1,53,111:new_2-1,53,111:new_3-1,53,111:new_4-1,53,111:new_5-1,53,111/start_point: prontera,155,187/g' /home/rathena/rathena/conf/char_athena.conf
sed -i 's/start_point_doram: lasa_fild01,48,297/start_point: prontera,155,187/g' /home/rathena/rathena/conf/char_athena.conf
sed -i 's/server_name: rAthena/server_name: ragnarok.sh/g' /home/rathena/rathena/conf/char_athena.conf
##
#add to crontab so it starts the server on reboot
(crontab -l 2>/dev/null; echo "@reboot sleep 5 && cd /home/rathena/rathena/ && nohup bash athena-start start \&") | crontab -
(crontab -l 2>/dev/null; echo "@reboot sleep 6 && wsproxy -p 5999 -a localhost:6900,localhost:6121,localhost:5121") | crontab -
#start server
cd /home/rathena/rathena/
nohup bash athena-start start &
wsproxy -p 5999 -a localhost:6900,localhost:6121,localhost:5121
