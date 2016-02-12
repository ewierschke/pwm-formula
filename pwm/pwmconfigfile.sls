include:
  - pwm/pwm

pwmconfig:
  file.managed:
    - name: /usr/local/tomcat7/apache-tomcat-7.0.67/webapps/pwm/WEB-INF/PwmConfiguration.xml
    - source: s3://dicelab-pwmconfig/PwmConfiguration.xml
    - source_hash: https://s3.amazonaws.com/dicelab-pwmconfig/PwmConfiguration.xml.md5

saslpasswd:
  file.managed:
    - name: /etc/postfix/sasl_passwd
    - source: s3://dicelab-pwmconfig/sasl_passwd
    - source_hash: https://s3.amazonaws.com/dicelab-pwmconfig/sasl_passwd.md5

service tomcat stop:
  cmd.run

sleep 3:
  cmd.run

service tomcat start:
  cmd.run

/usr/local/bin/pwmconfmgmt:
  file.append:
    - text: |
        #!/bin/sh
        sleep 2
        md5tmp=$(md5sum /usr/local/tomcat7/apache-tomcat-7.0.67/webapps/pwm/WEB-INF/PwmConfiguration.xml)
        echo $md5tmp > /tmp/md5conf
        IFS=' ' read -a myarray <<< "$md5tmp"
        echo ${myarray[0]} > /tmp/PwmConfiguration.xml.md5
        sed 's/.*\///' /tmp/md5conf >> /tmp/PwmConfiguration.xml.md5
        sed -i ':a;N;$!ba;s/\n/\ /g' /tmp/PwmConfiguration.xml.md5
        rm -rf /tmp/md5conf
        logger "created md5file in tmp"
        s3cmd put /usr/local/tomcat7/apache-tomcat-7.0.67/webapps/pwm/WEB-INF/PwmConfiguration.xml s3://dicelab-pwmconfig/PwmConfiguration.xml
        logger "s3 put conf.xml file"
        s3cmd put -P /tmp/PwmConfiguration.xml.md5 s3://dicelab-pwmconfig/PwmConfiguration.xml.md5
        logger "s3 put conffile md5"


/usr/local/bin/inotifypwmconfig:
  file.append:
    - text: | 
        #!/bin/sh
        while inotifywait -e modify -e create -e delete -o /var/log/inotify --format '%w%f-%e' /usr/local/tomcat7/apache-tomcat-7.0.67/webapps/pwm/WEB-INF/; do
            /usr/local/bin/pwmconfmgmt
        done
        

pwmconfmgmtmode:
  file.managed:
    - name: /usr/local/bin/pwmconfmgmt
    - mode: 777
    - replace: False

inotifypwmconfigmode:
  file.managed:
    - name: /usr/local/bin/inotifypwmconfig
    - mode: 777
    - replace: False

runinotifyscript:
  cmd.run:
    - name: at now + 20 minutes -f /usr/local/bin/inotifypwmconfig

postfixconf:
  file.managed:
    - name: /usr/local/bin/postfix_conf.sh
    - mode: 777
    - source: s3://dicelab-pwmconfig/postfix_conf.sh
    - source_hash: https://s3.amazonaws.com/dicelab-pwmconfig/postfix_conf.sh.md5

runpostfixconf:
  cmd.run:
    - name: /usr/local/bin/postfix_conf.sh

postmapsasl:
  cmd.run:
    - name: postmap /etc/postfix/sasl_passwd

enablepostfix:
  service.running:
    - name: postfix
    - enable: True
