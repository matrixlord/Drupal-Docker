FROM ubuntu:16.04

RUN apt-get update && apt-get install -y --no-install-recommends wget nano cron && \
  apt-get clean && rm -rf /var/cache/apt/* && rm -rf /var/lib/apt/lists/*
  
# Remove cron.* directories.
RUN rm -Rf /etc/cron.daily
RUN rm -Rf /etc/cron.weekly
RUN rm -Rf /etc/cron.monthly
RUN rm -Rf /etc/cron.hourly

# Copy our cron.
ADD crontab /etc/crontab

# Copy script.
ADD servercrons.sh /tmp/servercrons.sh
RUN mkdir /scripts && mv /tmp/servercrons.sh /scripts/servercrons.sh && chmod +x /scripts/servercrons.sh

# Prepend env.
RUN env |cat - /etc/crontab > /tmp/crontab && mv /tmp/crontab /etc/crontab && chmod +x /etc/crontab

# Run cron.
CMD ["/usr/sbin/cron", "-f"]
