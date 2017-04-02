FROM ubuntu:14.04
MAINTAINER Viet Duong<viet.duong@hotmail.com>

# Keep upstart from complaining
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl
RUN mkdir /var/run/sshd
RUN mkdir /run/php

# Let the conatiner know that there is no tty
ENV DEBIAN_FRONTEND noninteractive

# Update the repositories
RUN add-apt-repository ppa:ondrej/php5-5.6
RUN apt-get -y install python-software-properties
RUN apt-get -y install software-properties-common

RUN apt-get -y update
RUN apt-get -y upgrade

#
# Apache, Php, MySQL and required packages installation
#

# Basic Requirements
RUN apt-get -y install pwgen python-setuptools curl git nano sudo unzip openssh-server openssl


# Magento Requirements
RUN apt-get -y install apache2 libcurl3 php5 php5-mhash php5-mcrypt php5-curl php5-cli php5-mysql php5-gd php5-imagick php5-intl php5-xsl mysql-client-5.6 mysql-client-core-5.6

RUN a2enmod rewrite
RUN php5enmod mcrypt

# mysql config
RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/explicit_defaults_for_timestamp = true\nbind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf

# Set apache permission
RUN gpasswd -a nesdo www-data

RUN sed -i -e"s/user\s*=\s*www-data/user = vietcli/" /etc/php5/fpm/pool.d/www.conf
RUN sed -i -e"s/listen.owner\s*=\s*www-data/listen.owner = vietcli/" /etc/php5/fpm/pool.d/www.conf

# apache2 configuration

# Install Mod-FastCGI and PHP5-FPM on Ubuntu 14.04
RUN apt-get -y install apache2-mpm-worker libapache2-mod-fastcgi php5-fpm
RUN a2enmod actions alias fastcgi

# Generate self-signed ssl cert
RUN mkdir /etc/apache2/ssl/
RUN openssl req \
    -new \
    -newkey rsa:4096 \
    -days 365 \
    -nodes \
    -x509 \
    -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=demoweb.local" \
    -keyout /etc/ssl/private/ssl-cert-demoweb.local.key \
-out /etc/ssl/certs/ssl-cert-snakeoil-demoweb.local.pem

# Add demo web virtualhost configuration
ADD ./demoweb-vhost.conf /etc/apache2/sites-available/demoweb.conf
ADD ./demoweb-vhost.conf /etc/apache2/sites-enable/demoweb.conf


# Install composer and modman
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN curl -sSL https://raw.github.com/colinmollenhour/modman/master/modman > /usr/sbin/modman
RUN chmod +x /usr/sbin/modman

# Install phpmyadmin
#RUN apt-get install phpmyadmin -y

# Supervisor Config
#RUN /usr/bin/easy_install supervisor
#RUN /usr/bin/easy_install supervisor-stdout
#ADD ./supervisord.conf /etc/supervisord.conf

# Add system user for host user
RUN useradd -m -d /home/vietcli -p $(openssl passwd -1 'vietcli') -G root -s /bin/bash nesdo \
    && usermod -a -G www-data vietcli \
    && usermod -a -G sudo vietcli \
    && mkdir -p /home/vietcli/files/html \
    && chown -R vietcli:www-data /home/vietcli/files \
    && chmod -R 775 /home/vietcli/files

# Magento Initialization and Startup Script
ADD ./start.sh /start.sh
RUN chmod 755 /start.sh

# NETWORK PORTS
# private expose

# Supervisor Port
#EXPOSE 9011

# Solr Server Port
#EXPOSE 8983

# MySQL Server Port
EXPOSE 3306

# SSL Port
EXPOSE 443

# HTTP Port
EXPOSE 80

# SSH Port
EXPOSE 22

# Volume for mysql database and web install
VOLUME ["/var/lib/mysql", "/home/vietcli/files", "/var/run/sshd"]

CMD ["/bin/bash", "/start.sh"]
