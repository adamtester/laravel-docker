FROM ubuntu:16.04

# Configure Packages
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y software-properties-common
RUN apt-get install -y nginx curl libnotify-bin git supervisor
RUN apt-get install -y php7.0-fpm php7.0-cli php7.0-zip php7.0-mcrypt php7.0-mbstring php7.0-mysql php7.0-pgsql php7.0-xml php7.0-gd

# Configure Nginx
RUN echo "daemon off;" >> /etc/nginx/nginx.conf
RUN rm /etc/nginx/sites-enabled/default
ADD nginx/sites-enabled/ /etc/nginx/sites-enabled

# Configure PHP FPM
ENV PHP_EXT_DIR  /usr/lib/php/20151012
ENV PHP_INI_DIR  /etc/php/7.0/fpm
ENV PHP_INI      ${PHP_INI_DIR}/php.ini

RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.0/fpm/php-fpm.conf
RUN sed -i "s/;clear_env = no/clear_env = no/" /etc/php/7.0/fpm/pool.d/www.conf
RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" $PHP_INI
RUN sed -i "s/display_errors = Off/display_errors = On/" $PHP_INI
RUN sed -i "s/;date.timezone =/date.timezone = Europe\/London/" $PHP_INI

# Install composer
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer

WORKDIR /code/app

RUN useradd -d /code/app -u 1000 www && \
    sed -i 's/www-data/www/g' /etc/nginx/nginx.conf && \
    sed -i "s/www-data/www/g" /etc/php/7.0/fpm/pool.d/www.conf && \
    sed -i "s/www-data/www/g" /etc/php/7.0/fpm/pool.d/www.conf && \
    chown -R www:www \
        /var/log/nginx \
        /code/app

# Cron
ADD crontab /etc/cron.d/app-cron
RUN chmod 0644 /etc/cron.d/app-cron
RUN touch /var/log/cron.log

# Supervisor
ADD supervisor.conf /etc/supervisor/conf.d/supervisor.conf
RUN touch /var/log/supervisor.log
