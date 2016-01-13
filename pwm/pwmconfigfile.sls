include:
  - pwm/pwm

pwmconfig:
  file.managed:
    - name: /usr/local/tomcat7/apache-tomcat-7.0.67/webapps/pwm/WEB-INF/PwmConfiguration.xml
    - source: s3://dicelab-pwmconfig/PwmConfiguration.xml
    - source_hash: https://s3.amazonaws.com/dicelab-pwmconfig/PwmConfiguration.xml.md5

service tomcat stop:
  cmd.run

sleep 3:
  cmd.run

service tomcat start:
  cmd.run

/etc/incron.d/pwmconfigwatch:
  file.append:
    - text: | 
        /usr/local/tomcat7/apache-tomcat-7.0.67/webapps/pwm/WEB-INF/PwmConfiguration.xml IN_CLOSE_WRITE /usr/local/bin/pwmconfmgmt
		
/usr/local/bin/pwmconfmgmt:
  file.append:
    - text: |
        md5tmp=$(md5sum /usr/local/tomcat7/apache-tomcat-7.0.67/webapps/pwm/WEB-INF/PwmConfiguration.xml)
        echo $md5tmp > /tmp/md5conf
        IFS=' ' read -a myarray <<< "$md5tmp"
        echo ${myarray[0]} > /tmp/PwmConfiguration.xml.md5
        sed 's/.*\///' /tmp/md5conf >> /tmp/PwmConfiguration.xml.md5
        sed -i ':a;N;$!ba;s/\n/\ /g' /tmp/PwmConfiguration.xml.md5
        rm -rf /tmp/md5conf
        logger "created md5file in tmp"
        logger "placeholder for s3 put conf.xml file"
        s3cmd put -P /tmp/PwmConfiguration.xml.md5 s3://dicelab-pwmconfig/PwmConfiguration.xml.md5

runincrondservice:
  service.running:
    - name: incrond
    - enable: True

pwmconfmgmtmode:
  file.managed:
    - name: /usr/local/bin/pwmconfmgmt
    - mode: 777
