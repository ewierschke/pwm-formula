include:
  - pwm/pwm

pwmconfig:
  file.managed:
    - name: /usr/local/tomcat7/apache-tomcat-7.0.67/webapps/pwm/WEB-INF/PwmConfiguration.xml
    - source: s3://dicelab-pwmconfig/PwmConfiguration.xml
    - source_hash: md5=93b10c35b8a0cb6f79ad28074e26cb3b
    - require:
      - sls: pwm/pwm

service tomcat stop:
  cmd.run

sleep 3:
  cmd.run

service tomcat start:
  cmd.run
