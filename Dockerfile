FROM drupal:8

MAINTAINER Thom Toogood <thomtoogood@gmail.com>
ENV REFRESHED_AT 2015-08-03
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -qq update && apt-get install -y \
    libbz2-dev \
    unzip \
    git-core \
    curl \
    wget \
    mysql-client \
    mysql-server \
    php5-mysql \
    php5-gd \
    php5-curl \
    openssh-server \
    supervisor \
    && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-install bz2 pcntl zip \
    && rm -rf /usr/local/etc/php/conf.d/docker-php-ext-pdo.ini \
    && apt-get clean \
    && apt-get autoclean \
    && apt-get -y autoremove

# Disable sendmail.
ENV PHP_OPTIONS '-d sendmail_path=/bin/true -d phar.readonly=0'

# Install Composer.
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
ENV PATH $PATH:/root/.composer/vendor/bin

# Install Drush.
RUN composer global require drush/drush:dev-master

# Install Drupal console.
RUN curl -LSs http://drupalconsole.com/installer | php $PHP_OPTIONS && mv console.phar /usr/local/bin/drupal

WORKDIR /var/www/html

# Setup Drupal.
RUN cp sites/default/default.settings.php sites/default/settings.php \
    && cp sites/default/default.services.yml sites/default/services.yml \
    && mkdir -p sites/default/files \
    && chmod -R a+w sites/default

# Install Drupal.
RUN /etc/init.d/mysql start \
    && drush si -y -q standard \
        --db-url="mysql://root:@127.0.0.1:3306/drupal" \
        --account-name="drupal" \
        --account-pass="drupal" \
        --site-name="Drupal 8"

COPY ./start.sh /start.sh
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN mkdir -p /var/run/sshd /var/log/supervisor

EXPOSE 22 80
ENV SHELL /bin/bash
CMD ["/bin/bash", "/start.sh"]