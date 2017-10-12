include:
  - pwm/pwm

aws s3 cp s3://{{ salt['environ.get']('CONFIGBUCKETNAME') }}/PwmConfiguration.xml /usr/share/tomcat/webapps/ROOT/WEB-INF/PwmConfiguration.xml:
  cmd.run

aws s3 cp s3://{{ salt['environ.get']('CONFIGBUCKETNAME') }}/sasl_passwd /etc/postfix/sasl_passwd:
  cmd.run

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
        configbucketname=$(cat /usr/local/bin/configbucketname) 
        sha1tmp=$(sha1sum /usr/share/tomcat/webapps/ROOT/WEB-INF/PwmConfiguration.xml)
        echo $sha1tmp > /tmp/sha1conf
        IFS=' ' read -a myarray <<< "$sha1tmp"
        echo ${myarray[0]} > /tmp/PwmConfiguration.xml.sha1
        sed 's/.*\///' /tmp/sha1conf >> /tmp/PwmConfiguration.xml.sha1
        sed -i ':a;N;$!ba;s/\n/\ /g' /tmp/PwmConfiguration.xml.sha1
        rm -rf /tmp/sha1conf
        logger "created sha1file in tmp"
        s3cmd put /usr/share/tomcat/webapps/ROOT/WEB-INF/PwmConfiguration.xml s3://$configbucketname/PwmConfiguration.xml
        logger "s3 put conf.xml file"
        s3cmd put -P /tmp/PwmConfiguration.xml.sha1 s3://$configbucketname/PwmConfiguration.xml.sha1
        logger "s3 put conffile sha1"


/usr/local/bin/inotifypwmconfig:
  file.append:
    - text: | 
        #!/bin/sh
        while inotifywait -e modify -e create -e delete -o /var/log/inotify --format '%w%f-%e' /usr/share/tomcat/webapps/ROOT/WEB-INF/; do
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

aws s3 cp s3://{{ salt['environ.get']('CONFIGBUCKETNAME') }}/postfix_conf.sh /usr/local/bin/postfix_conf.sh:
  cmd.run

postfixconfmode:
  file.managed:
    - name: /usr/local/bin/postfix_conf.sh
    - mode: 777
    - replace: False

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
