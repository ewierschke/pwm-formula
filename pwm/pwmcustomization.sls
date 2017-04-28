include:
  - pwm/pwmconfigfile

mailerinstall:
  pkg.installed:
    - names:
      - mutt

/usr/local/bin/watchnewuser.sh:
  file.append:
    - text: |
        # This is a script that will grep a log file and send an email when a specified pattern is encountered.
        __ScriptName="watchnewuser.sh"
        
        log()
        {
            logger -i -t "${__ScriptName}" -s -- "$1" 2> /dev/console
            echo "$1"
        }  # ----------  end of function log  ----------
        
        #log "checking for new users"
        newusers=$(grep "CREATE_USER" /usr/share/tomcat/webapps/pwm/WEB-INF/logs/PWM.log)
        echo "$newusers" > /tmp/current-newusers.log
        
        if   [ -e "/tmp/prior-newusers.log" ]
        then 
             echo "prior-newusers.log Exists" > /dev/null
        else
             touch /tmp/prior-newusers.log | echo "" > /tmp/prior-newusers.log
        fi
        
        newuserentries=$(diff --suppress-common-lines -u /tmp/prior-newusers.log /tmp/current-newusers.log | grep '\+[0-9]')
        
        if   test "$newuserentries" != "" && test "$newusers" = ""
        then 
             log "should not see this log"
        elif test "$newuserentries" != ""
        then 
             sed 's/^.*\(perpetratorID.*perpetratorDN\).*$/\1/' /tmp/current-newusers.log > /tmp/output1
             cut -b 17- /tmp/output1 > /tmp/output2
             sed 's/",".*//' /tmp/output2 > /tmp/output3
             sed 's/, INFO.*//' /tmp/current-newusers.log > /tmp/datecreated
             sed 's/.*sourceAddress":"//' /tmp/current-newusers.log > /tmp/source1
             sed 's/,.*//' /tmp/source1 > /tmp/source2
             newusername=$(cat /tmp/output3)
             newuserdate=$(cat /tmp/datecreated)
             newusersource=$(cat /tmp/source2)
             newusername2=$(echo $newusername | sed -e "s/ /-and-/g")
             newuserdate2=$(echo $newuserdate | sed -e "s/ /,/g")
             newusersource2=$(echo $newusersource | sed -e "s/ /-and-/g")
             resourcedomain=$(cat /usr/local/bin/resourcedomain)
             envirname=$(cat /usr/local/bin/envirname)
             mailtodomain=$(cat /usr/local/bin/mailtodomain) 
             cp /usr/local/bin/email.html /tmp/email1.html
             sed -i "s/newuserdate/$newuserdate2/g" /tmp/email1.html
             sed -i "s/newusername/$newusername2/g" /tmp/email1.html
             sed -i "s/newusersource/$newusersource2/g" /tmp/email1.html
             sed -i "s/example/$envirname/g" /tmp/email1.html
             sed -i "s/resourcedomain/$resourcedomain/g" /tmp/email1.html
             mutt -F /root/.muttrc -e 'set content_type=text/html' -s "WARNING: New $envirname User Created" pwm-notifications@$mailtodomain < /tmp/email1.html
             rm -rf /tmp/email1.html
             echo "$newusers" > /tmp/prior-newusers.log
             log "emailed list of new users to postfix via mutt"
        else
             echo nothing > /dev/null
             #log "no new users"
        fi

/usr/local/bin/createmuttrc.sh:
  file.append:
    - text: |
        echo 'set realname="The PWM"' >> /root/.muttrc
        mailfromdomain=$(cat /usr/local/bin/mailfromdomain)
        echo 'set from="pwm@'$mailfromdomain'"' >> /root/.muttrc
        echo 'set use_from = yes' >> /root/.muttrc
        echo 'set edit_headers = yes' >> /root/.muttrc
        echo 'set use_envelope_from = yes' >> /root/.muttrc

createmuttrcmode:
  file.managed:
    - name: /usr/local/bin/createmuttrc.sh
    - mode: 777
    - replace: False

run createmuttrc script:
  cmd.run:
    - name: /usr/local/bin/createmuttrc.sh

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

/usr/share/tomcat/webapps/pwm/WEB-INF/jsp/fragment/dicelabwelcome.jsp:
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
    - name: /usr/share/tomcat/webapps/pwm/WEB-INF/jsp/login.jsp
    - marker_start: "        </table>"
    - marker_end: "    </div>"
    - show_changes: True
    - backup: '.bak'

adddicelabtexttologin-{{ myvar }}-accumulated1:
  file.accumulated:
    - filename: /usr/share/tomcat/webapps/pwm/WEB-INF/jsp/login.jsp
    - name: my-accumulator-{{ myvar }}
    - text: '        <% } %>'
    - require_in:
      - file: adddicelabtexttologin-{{ myvar }}

adddicelabtexttologin-{{ myvar }}-accumulated2:
  file.accumulated:
    - filename: /usr/share/tomcat/webapps/pwm/WEB-INF/jsp/login.jsp
    - name: my-accumulator-{{ myvar }}
    - text: '    <%@ include file="fragment/dicelabwelcome.jsp" %>'
    - require_in:
      - file: adddicelabtexttologin-{{ myvar }}

/usr/share/tomcat/webapps/pwm/public/resources/js/newuser.js:
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
    - name: /usr/share/tomcat/webapps/pwm/WEB-INF/jsp/fragment/form.jsp
    - pattern:        maxlength="<%=loopConfiguration.getMaximumLength.*
    - count: 1
    - repl: |{% raw %}
               maxlength="<%=loopConfiguration.getMaximumLength()%>"
                               <%if((loopConfiguration.getName().equals("sn"))||(loopConfiguration.getName().equals("givenName"))){%> onblur='autoGen(this.form.givenName.value, this.form.initials.value, this.form.sn.value)'<%}%>/>{% endraw %}
