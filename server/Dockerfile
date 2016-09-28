FROM ubuntu:16.04

# Install apache and php.
RUN apt-get update && apt-get install -y --no-install-recommends apache2 curl git unzip ca-certificates wget nano mysql-client supervisor openssh-server && \
  apt-get remove make && apt-get install make

# Install php7.
#RUN apt-get install -y --no-install-recommends php php-curl php-cli libapache2-mod-php php-mcrypt \
#  php-mysql php-mbstring php-redis php7.0-xml php7.0-gd php-xdebug php7.0-sqlite3

# Install php5.6. Install phpredis separately. Install xdebug.
RUN apt-get update && apt-get install -y --no-install-recommends language-pack-en-base && export LC_ALL=en_US.UTF-8 && export LANG=en_US.UTF-8 && \
  apt-get install -y --no-install-recommends software-properties-common && add-apt-repository -y ppa:ondrej/php && apt-get update
RUN apt-get update && apt-get install -y --no-install-recommends \
  php5.6 php5.6-curl php5.6-curl php5.6-cli libapache2-mod-php5.6 php5.6-mcrypt php5.6-mysql php5.6-mbstring php5.6-xml php5.6-gd php5.6-dev php5.6-sqlite3 php5.6-pgsql
RUN cd /tmp && wget https://github.com/phpredis/phpredis/archive/master.zip -O phpredis.zip && \
  unzip -o /tmp/phpredis.zip && mv /tmp/phpredis-* /tmp/phpredis && cd /tmp/phpredis && phpize && ./configure && make && make install && \
  touch /etc/php/5.6/mods-available/redis.ini && echo extension=redis.so > /etc/php/5.6/mods-available/redis.ini && \
  ln -s /etc/php/5.6/mods-available/redis.ini /etc/php/5.6/apache2/conf.d/ && \
  ln -s /etc/php/5.6/mods-available/redis.ini /etc/php/5.6/cli/conf.d/ && \
  find . -type f -name "/tmp/phpredis-*" -delete
ENV xdebug xdebug-2.4.1
RUN cd /tmp && wget http://xdebug.org/files/$xdebug.tgz -O $xdebug.tgz && tar -xvzf $xdebug.tgz && cd $xdebug && phpize && ./configure && make && \
  cp modules/xdebug.so /usr/lib/php/20131226 && rm -rf /tmp/$xdebug && rm /tmp/$xdebug.tgz  && \
  touch /etc/php/5.6/apache2/conf.d/xdebug.ini && echo 'zend_extension = /usr/lib/php/20131226/xdebug.so' > /etc/php/5.6/apache2/conf.d/xdebug.ini
ADD xdebug /tmp/xdebug
RUN cat /tmp/xdebug >> /etc/php/5.6/apache2/conf.d/xdebug.ini && rm /tmp/xdebug && cp /etc/php/5.6/apache2/conf.d/xdebug.ini /etc/php/5.6/cli/conf.d/xdebug.ini
RUN sed -i -e"s/^;date.timezone\s=/date.timezone = \"Europe\/Athens\"/" /etc/php/5.6/cli/php.ini
RUN sed -i -e"s/^;date.timezone\s=/date.timezone = \"Europe\/Athens\"/" /etc/php/5.6/apache2/php.ini
RUN sed -i -e"s/^;always_populate_raw_post_data/always_populate_raw_post_data/" /etc/php/5.6/cli/php.ini
RUN sed -i -e"s/^;always_populate_raw_post_data/always_populate_raw_post_data/" /etc/php/5.6/apache2/php.ini

# Remove package lists.
RUN apt-get clean && rm -rf /var/cache/apt/* && rm -rf /var/lib/apt/lists/*

# Enable mod_rewrite.
RUN a2enmod rewrite

# Set server name.
RUN echo 'ServerName localhost' >> /etc/apache2/apache2.conf

# Create user, vhosts, permissions.
# Change user apache runs.
RUN sed -i -e"s/^export\s*APACHE_RUN_USER=www-data/export APACHE_RUN_USER=serveruser/" /etc/apache2/envvars
RUN sed -i -e"s/^export\s*APACHE_RUN_GROUP=www-data/export APACHE_RUN_GROUP=serveruser/" /etc/apache2/envvars

# Create user.
RUN useradd -ms /bin/bash serveruser

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

# Install Bundler, Node.js, Grunt.
USER root
RUN apt-get update && apt-get install -y --no-install-recommends nodejs npm bundler && npm install -g grunt-cli && ln -s /usr/bin/nodejs /usr/bin/node
RUN apt-get install -y --no-install-recommends ruby-dev && gem install bundler && gem install chunky_png -v '1.3.5' && gem install multi_json -v '1.12.1' && \
  gem install sass -v '3.4.22' && gem install rb-fsevent -v '0.9.7' && gem install ffi -v '1.9.10' && gem install compass-core -v '1.0.3' && \
  gem install compass-import-once -v '1.0.5' && gem install rb-inotify -v '0.9.7' && gem install sass-globbing -v '1.1.5' && \
  gem install susy -v '2.2.12' && gem install susy -v '2.2.12' && gem install compass -v '1.0.3' && gem install modular-scale -v '2.1.1'

# Restart apache.
WORKDIR /root

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

# Add vhosts and enable sites.
USER root
ADD vhosts/drupal7.conf /etc/apache2/sites-available/
RUN a2ensite drupal7
ADD vhosts/drupal8.conf /etc/apache2/sites-available/
RUN a2ensite drupal8

RUN service apache2 restart

EXPOSE 80 9000 22

CMD ["/usr/bin/supervisord", "-n"]
