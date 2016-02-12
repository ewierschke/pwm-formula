include:
  - pwm/pwmconfigfile

mailxinstall:
  pkg.installed:
    - names:
      - mailx

/usr/local/bin/watchnewuser.sh:
  file.append:
    - text: |
        # This is a script that will grep a log file and send an email when a specified patter is encountered.
        newusers=$(grep "CREATE_USER" /usr/local/tomcat7/apache-tomcat-7.0.67/webapps/pwm/WEB-INF/logs/PWM.log)
        echo "$newusers" > /tmp/current-newusers.log
        
        if      [ -e "/tmp/prior-newusers.log" ]
                 then echo "prior-newusers.log Exists" > /dev/null
        else
                touch /tmp/prior-newusers.log | echo "" > /tmp/prior-newusers.log
        fi
        
        newuserentries=$(diff --suppress-common-lines -u /tmp/prior-newusers.log /tmp/current-newusers.log | grep '\+[0-9]')
        
        if
                        test "$newuserentries" != "" && test "$newusers" = ""
                        then echo "No New Errors" > /dev/null
                        logger "no new users"
                elif
                        test "$newuserentries" != ""
                        then echo "$newuserentries" | mailx -s "WARNING: New DICELAB User Created" -r "pwm@dicelab.net" pwm-notifications@plus3it.com
                        echo "$newusers" > /tmp/prior-newusers.log
                        logger "emailed list of new users"
        fi

watchnewusermode:
  file.managed:
    - name: /usr/local/bin/watchnewuser.sh
    - mode: 777
    - replace: False

runcrondservice:
  service.running:
    - name: crond
    - enable: True

/etc/crontab:
  file.append:
    - text: |
        */5 * * * * root /usr/local/bin/watchnewuser.sh

/usr/local/tomcat7/apache-tomcat-7.0.67/webapps/pwm/WEB-INF/jsp/fragment/dicelabwelcome.jsp:
  file.append:
    - text: |
        <!DOCTYPE html>
        
        <html lang="en" xmlns="http://www.w3.org/1999/xhtml">
        <head>
            <meta charset="utf-8" />
            <title></title>
        </head>
        <body>
            <p>&nbsp;</p>
            <p style="text-align: center; color: #7e7e7e; font-size: 15px; font-family: avenir; font-weight: $aileron-ultra-light;">&nbsp;</p>
            <p style="text-align: center;"><strong>=====</strong></p>
            <p style="text-align: center;"><strong>Welcome to the DICELAB account management system. &nbsp;</strong></p>
            <p style="text-align: center;">If you have already been provided a username but need to setup your password please select 'Activate Account'.</p>
            <p style="text-align: center;">If you do not yet have a username please select 'New User Registration'.</p>
            <p style="text-align: center;">Otherwise, login with your credentials, or select 'Forgotten Password' to recover your credentials.</p>
            <p>&nbsp;</p>
        </body>
        </html>

{% set myvar = 42%}
adddicelabtexttologin-{{ myvar }}:
  file.blockreplace:
    - name: /usr/local/tomcat7/apache-tomcat-7.0.67/webapps/pwm/WEB-INF/jsp/login.jsp
    - marker_start: "        </table>"
    - marker_end: "    </div>"
    - show_changes: True
    - backup: '.bak'

adddicelabtexttologin-{{ myvar }}-accumulated1:
  file.accumulated:
    - filename: /usr/local/tomcat7/apache-tomcat-7.0.67/webapps/pwm/WEB-INF/jsp/login.jsp
    - name: my-accumulator-{{ myvar }}
    - text: '        <% } %>'
    - require_in:
      - file: adddicelabtexttologin-{{ myvar }}

adddicelabtexttologin-{{ myvar }}-accumulated2:
  file.accumulated:
    - filename: /usr/local/tomcat7/apache-tomcat-7.0.67/webapps/pwm/WEB-INF/jsp/login.jsp
    - name: my-accumulator-{{ myvar }}
    - text: '    <%@ include file="fragment/dicelabwelcome.jsp" %>'
    - require_in:
      - file: adddicelabtexttologin-{{ myvar }}

/usr/local/tomcat7/apache-tomcat-7.0.67/webapps/pwm/public/resources/js/newuser.js:
  file.append:
    - text: |
        function autoGen(prenom, inits, nom){
        	var prenom = document.getElementById("givenName").value;
        	var nom = document.getElementById("sn").value;
                var inits = document.getElementById("initials").value;
        	uidGen(prenom, inits, nom);
        	cnGen(prenom, inits, nom);
        }
        
        function uidGen(prenom, inits, nom){
        	var sAMAccountName = prenom.toLowerCase() + '.' + inits.toLowerCase() + '.' + nom.toLowerCase();
        	document.getElementById("sAMAccountName").value = sAMAccountName;
        }
        
        function cnGen(prenom, inits, nom){
        	var cn = prenom.toLowerCase() + '.' + inits.toLowerCase() + '.' + nom.toLowerCase();
        	document.getElementById("cn").value = cn;
        }
        

formjspaddscript:
  file.replace:
    - name: /usr/local/tomcat7/apache-tomcat-7.0.67/webapps/pwm/WEB-INF/jsp/fragment/form.jsp
    - pattern:        maxlength="<%=loopConfiguration.getMaximumLength.*
    - count: 1
    - repl: |{% raw %}
               maxlength="<%=loopConfiguration.getMaximumLength()%>"
                               <%if((loopConfiguration.getName().equals("sn"))||(loopConfiguration.getName().equals("givenName"))){%> onblur='autoGen(this.form.givenName.value, this.form.initials.value, this.form.sn.value)'<%}%>/>{% endraw %}
