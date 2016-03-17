include:
  - pwm/pwmfw

pkginstall:
  pkg.installed:
    - names:
      - http://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
      - java-1.8.0-openjdk
      - tomcat
      - tomcat-admin-webapps
      - tomcat-webapps
      - wget
      - unzip
      - httpd
      - inotify-tools
      - s3cmd
      - at
      - postfix
      - cyrus-sasl-plain

tomcat-users.xml:
  file.blockreplace:
    - name: /usr/share/tomcat/conf/tomcat-users.xml
    - marker_start: '<tomcat-users>'
    - marker_end: '</tomcat-users>'
    - content: |
        <!-- user manager can access only manager section -->
        <role rolename="manager-gui" />
        <user username="manager" password="manager" roles="manager-gui" />
        <!-- user admin can access manager and admin section both -->
        <role rolename="admin-gui" />
        <user username="admin" password="admin" roles="manager-gui,admin-gui" />
    - show_changes: True

pwm_zip:
  archive.extracted:
    - name: /usr/local/bin/pwm/
    - source: 'https://s3.amazonaws.com/dicelab-pwm/pwm-1.8.0-SNAPSHOT-2016-02-05T18-09-31Z-pwm-bundle.zip'
    - source_hash: 'https://s3.amazonaws.com/dicelab-pwm/pwm-1.8.0-SNAPSHOT-2016-02-05T18-09-31Z-pwm-bundle.zip.md5'
    - archive_format: zip

/usr/share/tomcat/webapps/pwm.war:
  file.managed:
    - source: /usr/local/bin/pwm/pwm.war

runtomcatservice:
  service.running:
    - name: tomcat
    - enable: True

service tomcat restart:
  cmd.run
  
sleep 5:
  cmd.run

/etc/httpd/conf.d/pwm.conf:
  file.append:
    - text: |
        ProxyRequests Off
        <Proxy *>
                Order allow,deny
                Allow from all
        </Proxy>
        
        #ProxyPass /pwm/admin !
        #ProxyPass /pwm/config !
        
        ProxyPass /pwm http://localhost:8080/pwm
        
        ProxyPassReverse /pwm http://localhost:8080/pwm
        
        <Location />
                Order allow,deny
                Allow from all
                ProxyPass http://localhost:8080/pwm/ flushpackets=on
                ProxyPassReverse http://localhost:8080/pwm/
                ProxyPassReverseCookiePath /pwm/ /
        </Location>

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
                /usr/share/tomcat/webapps/pwm.war
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
    - name: /usr/share/tomcat/webapps/pwm/WEB-INF/web.xml
    - marker_start: "        <param-name>applicationPath</param-name>"
    - marker_end: "    </context-param>"
    - content: "        <param-value>/usr/share/tomcat/webapps/pwm/WEB-INF</param-value>"
    - show_changes: True
    - backup: '.bak'
