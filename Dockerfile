FROM ubuntu:latest
MAINTAINER Marcel Remmy <marcel.remmy@alumni.fh-aachen.de>

# Install packages
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install supervisor git apache2 php5-mysql php-apc php5-curl php5-gd php5-mcrypt php5-intl php5-xsl openssh-server libapache2-mod-php5 && php5enmod mcrypt

# Add image configuration and scripts
ADD start-apache2.sh /start-apache2.sh
ADD start-mysqld.sh /start-mysqld.sh
ADD run.sh /run.sh
ADD supervisord-apache2.conf /etc/supervisor/conf.d/supervisord-apache2.conf
ADD start-sshd.conf /etc/supervisor/conf.d/start-sshd.conf

# For openssh
RUN mkdir -p /var/run/sshd
RUN echo "root:admin123" | chpasswd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i '$a\PermitRootLogin yes' /etc/ssh/ssh_config

# config to enable .htaccess
ADD apache_default /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite && chmod 755 /*.sh

#Enviornment variables to configure php
ENV PHP_UPLOAD_MAX_FILESIZE 10M
ENV PHP_POST_MAX_SIZE 10M

RUN mkdir /app && cd /app && \
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php -r "if (hash_file('SHA384', 'composer-setup.php') === '55d6ead61b29c7bdee5cccfb50076874187bd9f21f65d8991d46ec5cc90518f447387fb9f76ebae1fbbacf329e583e30') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" && \
    php composer-setup.php && \
    php -r "unlink('composer-setup.php');" && \
    mv composer.phar /usr/local/bin/composer
    
# php -r "readfile('https://getcomposer.org/installer');" | php && \
# php composer.phar install --no-plugins --no-scripts
# composer config http-basic.repo.magento.com <publickkey> <privatekey> && \
# cat auth.json && \
# composer config -g repositories.magento2-standard vcs https://github.com/magento-hackathon/magento2-standard && \
# composer create-project magento-hackathon/magento2-standard /app && \

RUN cd /app && \
 wget http://149.201.48.81/gq/Magento-CE-2.1.5_sample_data-2017-02-20-05-42-11.tar.gz && \
 gunzip Magento-CE-2.1.5_sample_data-2017-02-20-05-42-11.tar.gz && \
 tar -xf Magento-CE-2.1.5_sample_data-2017-02-20-05-42-11.tar && \
 ls -la && \
 wget http://sourceforge.net/projects/adminer/files/latest/download?source=files && \
 mv download\?source\=files adminer.php

RUN mkdir -p /app && rm -rf /var/www/html && ln -s /app /var/www/html

EXPOSE 80 22
CMD ["/run.sh"]
