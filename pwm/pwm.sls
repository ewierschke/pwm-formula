java_pkg:
  pkg.installed:
    - names:
      - java-1.8.0-openjdk
      - wget
      - unzip

/usr/local/apache-tomcat-7.0.67.tar.gz:
  archive.extracted:
    - name: /usr/local/tomcat7/
    - source: 'http://mirror.cc.columbia.edu/pub/software/apache/tomcat/tomcat-7/v7.0.67/bin/apache-tomcat-7.0.67.tar.gz'
    - source_hash: 'https://www.apache.org/dist/tomcat/tomcat-7/v7.0.67/bin/apache-tomcat-7.0.67.tar.gz.md5'
    - archive_format: tar
    - tar_options: xzf

tomcat-users.xml:
  file.blockreplace:
    - name: /usr/local/tomcat7/apache-tomcat-7.0.67/conf/tomcat-users.xml
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

pwm_v1.7.1:
  archive.extracted:
    - name: /usr/local/tomcat7/apache-tomcat-7.0.67/temp/pwm/
    - source: 'https://s3.amazonaws.com/dicelab-pwm/pwm_v1.7.1.zip'
    - source_hash: 'https://s3.amazonaws.com/dicelab-pwm/pwm_v1.7.1.zip.md5'
    - archive_format: zip

/usr/local/tomcat7/apache-tomcat-7.0.67/webapps/pwm.war:
  file.managed:
    - source: /usr/local/tomcat7/apache-tomcat-7.0.67/temp/pwm/pwm.war

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
        CATALINA_HOME=/usr/local/tomcat7/apache-tomcat-7.0.67
        
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

runtomcatservice:
  service.running:
    - name: tomcat
    - enable: True

service tomcat restart:
  cmd.run

minionconfig:
  file.append:
    - name: /etc/salt/minion
    - text: 's3.role_arn: arn:aws:iam::701759196663:role/pwmconfig'

