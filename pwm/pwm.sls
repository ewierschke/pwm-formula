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

/usr/share/tomcat/webapps/ROOT.war:
  file.managed:
    - source: 'https://s3.amazonaws.com/app-chemistry/files/pwm18.war'
    - source_hash: 'https://s3.amazonaws.com/app-chemistry/files/pwm18.war.sha1'

runtomcatservice:
  service.running:
    - name: tomcat
    - enable: True

sleep 5:
  cmd.run

/etc/httpd/conf.d/pwm.conf:
  file.append:
    - text: |
        
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

pwmapppath:
  file.blockreplace:
    - name: /usr/share/tomcat/webapps/ROOT/WEB-INF/web.xml
    - marker_start: "        <param-name>applicationPath</param-name>"
    - marker_end: "    </context-param>"
    - content: "        <param-value>/usr/share/tomcat/webapps/ROOT/WEB-INF</param-value>"
    - show_changes: True
    - backup: '.bak'

/usr/share/tomcat/conf/tomcat.conf:
  file.append:
    - text: 'JAVA_OPTS="-Djava.security.egd=file:/dev/./urandom -Djava.awt.headless=true -Xmx512m -XX:MaxPermSize=256m -XX:+UseConcMarkSweepGC"'

/usr/local/bin/rerunhostnamestate:
  file.append:
    - text: 'salt-call --local state.apply pwm/hostname'

chmod 777 /usr/local/bin/rerunhostnamestate:
  cmd.run

runhostnamestate:
  cmd.run:
    - name: at now + 10 minutes -f /usr/local/bin/rerunhostnamestate
