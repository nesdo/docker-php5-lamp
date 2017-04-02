#!/bin/bash
if [ ! -f /nesdo-pw.txt ]; then
    #mysql has to be started this way as it doesn't work to call from /etc/init.d
    /usr/bin/mysqld_safe &
    sleep 10s
    # Here we generate random passwords (thank you pwgen!). The first two are for mysql users, the last batch for random keys in wp-config.php
    ROOT_PASSWORD=`pwgen -c -n -1 12`
    MYSQL_ROOT_PASSWORD="vietcli"
    MYSQL_VIETCLI_PASSWORD="vietcli"
    VIETCLI_PASSWORD="vietcli"
    # echo "vietcli:$VIETCLI_PASSWORD" | chpasswd
    echo "root:$ROOT_PASSWORD" | chpasswd

    #This is so the passwords show up in logs.
    echo root password: $ROOT_PASSWORD
    echo magento password: $MAGENTO_PASSWORD
    echo mysql root password: $MYSQL_ROOT_PASSWORD
    echo mysql vietcli password: $MYSQL_VIETCLI_PASSWORD
    echo $ROOT_PASSWORD > /root-pw.txt
    echo $VIETCLI_PASSWORD > /vietcli-pw.txt
    echo $MYSQL_ROOT_PASSWORD > /mysql-vietcli-root-pw.txt
    echo $MYSQL_VIETCLI_PASSWORD > /mysql-vietcli-pw.txt

    mysqladmin -u root password $MYSQL_ROOT_PASSWORD
    mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD' WITH GRANT OPTION; FLUSH PRIVILEGES;"
    mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "CREATE DATABASE vietcli_db; GRANT ALL PRIVILEGES ON vietcli_db.* TO 'vietcli'@'localhost' IDENTIFIED BY '$MYSQL_VIETCLI_PASSWORD'; FLUSH PRIVILEGES;"
    killall mysqld
    mv /var/lib/mysql/ibdata1 /var/lib/mysql/ibdata1.bak
    cp -a /var/lib/mysql/ibdata1.bak /var/lib/mysql/ibdata1
fi

# start all the services
/usr/local/bin/supervisord -n -c /etc/supervisord.conf