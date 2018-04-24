include:
  - pwm/pwmfw
  - pwm/hostname

pkginstall:
  pkg.installed:
    - names:
      - java-1.8.0-openjdk
      - tomcat
      - wget
      - unzip
      - httpd
      - inotify-tools
      - s3cmd
      - at
      - postfix
      - cyrus-sasl-plain
      - chrony

pkgremove:
  pkg.removed:
    - names:
      - ntp
      - ntpdate

aws s3 cp s3://{{ salt['environ.get']('CONFIGBUCKETNAME') }}/files/pwm17.war /usr/share/tomcat/webapps/ROOT.war:
  cmd.run

/usr/share/tomcat/webapps/ROOT.war:
  file.managed:
    - user: tomcat
    - group: tomcat

runtomcatservice:
  service.running:
    - name: tomcat
    - enable: True

sleep 10:
  cmd.run

restarttomcatservice:
  service.running:
    - name: tomcat
    - enable: True
    - reload: True

/etc/httpd/conf.d/pwm.conf:
  file.append:
    - text: |
        LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
        LogFormat "%{X-Forwarded-For}i %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" proxy
        SetEnvIf X-Forwarded-For "^.*\..*\..*\..*" forwarded
        CustomLog "logs/access_log" combined env=!forwarded
        CustomLog "logs/access_log" proxy env=forwarded
        
        ProxyPass / http://localhost:8080/
        
        ProxyPassReverse / http://localhost:8080/
        
        Header always set Strict-Transport-Security "max-age=63072000; includeSubdomains; preload"
        Header always set X-Frame-Options DENY
        Header always set X-Content-Type-Options nosniff

runhttpdservice:
  service.running:
    - name: httpd
    - enable: True

runatdservice:
  service.running:
    - name: atd
    - enable: True

/usr/local/bin/selinuxproxy.sh:
  file.append:
    - text: |
        # Gotta make SELinux happy...
        if [[ $(getenforce) = "Enforcing" ]] || [[ $(getenforce) = "Permissive" ]]
        then
            chcon -R --reference=/usr/share/tomcat/webapps \
                /usr/share/tomcat/webapps/ROOT.war
            if [[ $(getsebool httpd_can_network_relay | \
                cut -d ">" -f 2 | sed 's/[ ]*//g') = "off" ]]
            then
                logger "Enabling httpd-based proxying within SELinux"
                setsebool -P httpd_can_network_relay=1
            fi
        fi

chmod 777 /usr/local/bin/selinuxproxy.sh:
  cmd.run

run selinuxproxy script:
  cmd.run:
    - name: /usr/local/bin/selinuxproxy.sh

/usr/share/tomcat/conf/tomcat.conf:
  file.append:
    - text: 'JAVA_OPTS="-Djava.security.egd=file:/dev/./urandom -Djava.awt.headless=true -Xmx512m -XX:MaxPermSize=256m -XX:+UseConcMarkSweepGC"'

/etc/chrony.conf:
  file.append:
    - text: 'server 169.254.169.123 prefer iburst'

/usr/local/bin/rerunhostnamestate:
  file.append:
    - text: 'salt-call --local state.apply pwm/hostname'

chmod 777 /usr/local/bin/rerunhostnamestate:
  cmd.run

runhostnamestate:
  cmd.run:
    - name: at now + 10 minutes -f /usr/local/bin/rerunhostnamestate
