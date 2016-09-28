#!/bin/bash

# Run cron for each site.
while read line; do
  IFS=';' read -a sitearray <<< $line
  wget -O - -q -t 1 --no-check-certificate ${sitearray[1]}/${sitearray[2]}
done </app_config/sites
