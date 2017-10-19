{%- if salt['grains.has_value']('setupadpasswordexpirenotify') %}
{%- if grains['setupadpasswordexpirenotify'] == 'yes' %}
adpassexpnotifypkginstall:
  pkg.installed:
    - names:
      - git
      - php
      - php-ldap
      - cyrus-sasl-plain

gitproj:
  git.latest:
    - name: https://github.com/ewierschke/ad-password-expire-notify
    - target: /usr/local/bin/ad-password-expire-notify
    - rev: pwm

envadjustmode:
  file.managed:
    - name: /usr/local/bin/ad-password-expire-notify/envadjust.sh
    - mode: 700
    - replace: False

runenvadjust:
  cmd.run:
    - name: /usr/local/bin/ad-password-expire-notify/envadjust.sh

createdailynotifycronjob:
  cmd.run:
    - name: export OUPATH=$(cat /usr/local/bin/oupath) && eval echo '0 12 \* \* \* root /usr/bin/php /usr/local/bin/ad-password-expire-notify/check_expire.php -o \"${OUPATH}\"' > /etc/cron.d/ad-password-expire-notify

dailynotifycronmode:
  file.managed:
    - name: /etc/cron.d/ad-password-expire-notify
    - mode: 644
    - replace: False

{% endif %}
{% endif %}