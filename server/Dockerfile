FROM ubuntu:16.04

# Get user id and group id from arguments
ARG UID
ARG GID

# Install apache and php.
RUN apt-get update && apt-get install -y --no-install-recommends apache2 curl git unzip ca-certificates wget nano mysql-client supervisor openssh-server && \
  apt-get remove make && apt-get install make

# Install php7.
RUN apt-get install -y --no-install-recommends php php-dev php-curl php-cli libapache2-mod-php php-mcrypt \
  php-mysql php-mbstring php-redis php7.0-xml php7.0-gd php-xdebug php7.0-sqlite3 php7.0-pgsql
# Configuration.
ADD xdebug /tmp/xdebug
RUN cat /tmp/xdebug >> /etc/php/7.0/apache2/conf.d/20-xdebug.ini && rm /tmp/xdebug
RUN sed -i -e"s/^;date.timezone\s=/date.timezone = \"Europe\/Athens\"/" /etc/php/7.0/cli/php.ini
RUN sed -i -e"s/^;date.timezone\s=/date.timezone = \"Europe\/Athens\"/" /etc/php/7.0/apache2/php.ini
RUN sed -i -e"s/^memory_limit\s=.*/memory_limit = 512M/" /etc/php/7.0/cli/php.ini
RUN sed -i -e"s/^memory_limit\s=.*/memory_limit = 512M/" /etc/php/7.0/apache2/php.ini

# Remove package lists.
RUN apt-get clean && rm -rf /var/cache/apt/* && rm -rf /var/lib/apt/lists/*

# Enable apache modules.
RUN a2enmod rewrite proxy proxy_http headers proxy_wstunnel

# Set server name.
RUN echo 'ServerName localhost' >> /etc/apache2/apache2.conf

# Create user, vhosts, permissions.
# Change user apache runs.
RUN sed -i -e"s/^export\s*APACHE_RUN_USER=www-data/export APACHE_RUN_USER=serveruser/" /etc/apache2/envvars
RUN sed -i -e"s/^export\s*APACHE_RUN_GROUP=www-data/export APACHE_RUN_GROUP=serveruser/" /etc/apache2/envvars

# Create user.
RUN groupadd -r serveruser -g $GID && useradd -ms /bin/bash serveruser -u $UID -g $GID

# Set logs to 777.
USER root
RUN chmod -R 777 /var/log/apache2

# Install composer.
RUN cd ~
RUN curl -sS https://getcomposer.org/installer -o composer-setup.php
RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer
RUN rm -rf composer-setup.php

# Instal drush.
USER serveruser
WORKDIR /home/serveruser
RUN composer global require drush/drush drupal/console:@stable
RUN echo "PATH=$PATH:~/.composer/vendor/bin" >> ~/.bashrc

# Use root user.
USER root

# Install phpunit.
RUN wget https://phar.phpunit.de/phpunit.phar
RUN chmod +x phpunit.phar
RUN mv phpunit.phar /usr/local/bin/phpunit

# Install Bundler, Node.js, Grunt.
RUN apt-get update && apt-get install -y --no-install-recommends nodejs npm bundler && npm install -g grunt-cli && ln -s /usr/bin/nodejs /usr/bin/node
RUN apt-get install -y --no-install-recommends ruby-dev && gem install bundler && gem install chunky_png -v '1.3.5' && gem install multi_json -v '1.12.1' && \
  gem install sass -v '3.4.22' && gem install rb-fsevent -v '0.9.7' && gem install ffi -v '1.9.10' && gem install compass-core -v '1.0.3' && \
  gem install compass-import-once -v '1.0.5' && gem install rb-inotify -v '0.9.7' && gem install sass-globbing -v '1.1.5' && \
  gem install susy -v '2.2.12' && gem install susy -v '2.2.12' && gem install compass -v '1.0.3' && gem install modular-scale -v '2.1.1'
RUN npm install -g gulp-cli babel-cli webpack
# Restart apache.
WORKDIR /root

# Install symfony.
RUN curl -LsS https://symfony.com/installer -o /usr/local/bin/symfony && chmod a+x /usr/local/bin/symfony

# Setup ssh.
RUN mkdir /var/run/sshd
RUN echo 'root:root' | chpasswd
RUN sed -i 's/prohibit-password/yes/' /etc/ssh/sshd_config

# Setup supervisor to run child processes.
ADD ./supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
ADD ./supervisor/apache.conf /etc/supervisor/conf.d/apache.conf
ADD ./supervisor/ssh.conf /etc/supervisor/conf.d/ssh.conf
RUN chown root:root /etc/supervisor/conf.d/* && chmod 644 /etc/supervisor/conf.d/*

# Create vhosts.
USER serveruser
WORKDIR /home/serveruser
RUN mkdir -p vhosts
RUN mkdir -p vhosts/drupal7
RUN mkdir -p vhosts/drupal8
RUN mkdir -p vhosts/human_factor
RUN mkdir -p vhosts/symfony

# Add vhosts and enable sites.
USER root
ADD vhosts/drupal7.conf /etc/apache2/sites-available/
RUN a2ensite drupal7
ADD vhosts/drupal8.conf /etc/apache2/sites-available/
RUN a2ensite drupal8
ADD vhosts/human_factor.conf /etc/apache2/sites-available/
RUN a2ensite human_factor
ADD vhosts/symfony.conf /etc/apache2/sites-available/
RUN a2ensite symfony

RUN service apache2 restart

EXPOSE 80 9000 22

CMD ["/usr/bin/supervisord", "-n"]
