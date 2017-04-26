include:
  - pwm/pwmfw
  - pwm/hostname

pkginstall:
  pkg.installed:
    - names:
      - java-1.8.0-openjdk
      - wget
      - unzip
      - httpd
      - inotify-tools
      - s3cmd
      - at
      - postfix
      - cyrus-sasl-plain

/usr/local/bin/apache-tomcat-7.0.67.tar.gz:
  archive.extracted:
    - name: /usr/local/bin/tomcat7
    - source: 'https://archive.apache.org/dist/tomcat/tomcat-7/v7.0.67/bin/apache-tomcat-7.0.67.tar.gz'
    - source_hash: 'https://archive.apache.org/dist/tomcat/tomcat-7/v7.0.67/bin/apache-tomcat-7.0.67.tar.gz.md5'
    - archive_format: tar
    - options: xzf

mv /usr/local/bin/tomcat7/apache-tomcat-7.0.67 /usr/local/bin/tomcat:
  cmd.run
  
mv /usr/local/bin/tomcat /usr/share/ -f --backup=numbered:
  cmd.run

/etc/init.d/tomcat:
  file.append:
    - text: |
        #!/bin/bash
        # description: Tomcat Start Stop Restart
        # processname: tomcat
        # chkconfig: 234 20 80
        JAVA_HOME=/usr/lib/jvm/jre-1.8.0-openjdk.x86_64
        export JAVA_HOME
        PATH=$JAVA_HOME/bin:$PATH
        export PATH
        CATALINA_HOME=/usr/share/tomcat
        
        case $1 in
        start)
        sh $CATALINA_HOME/bin/startup.sh
        ;;
        stop)
        sh $CATALINA_HOME/bin/shutdown.sh
        ;;
        restart)
        sh $CATALINA_HOME/bin/shutdown.sh
        sh $CATALINA_HOME/bin/startup.sh
        ;;
        esac
        exit 0

tomcatmode:
  file.managed:
    - name: /etc/init.d/tomcat
    - mode: 755
    - replace: False

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

/usr/share/tomcat/webapps/pwm.war:
  file.managed:
    - source: 'https://s3.amazonaws.com/dicelab-pwm/pwm.war'
    - source_hash: 'https://s3.amazonaws.com/dicelab-pwm/pwm.war.md5'

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
