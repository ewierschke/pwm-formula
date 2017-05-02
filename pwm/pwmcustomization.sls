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
        newusers=$(grep -a "CREATE_USER" /usr/share/tomcat/webapps/pwm/WEB-INF/logs/PWM.log)
        echo "$newusers" > /usr/local/bin/current-newusers.log
        
        if   [ -e "/usr/local/bin/prior-newusers.log" ]
        then
             echo "prior-newusers.log Exists" > /dev/null
        else
             touch /usr/local/bin/prior-newusers.log | echo "" > /usr/local/bin/prior-newusers.log
        fi
        
        #compare prior newusers to current newusers
        newuserentries=$(diff --suppress-common-lines -a /usr/local/bin/prior-newusers.log /usr/local/bin/current-newusers.log)
        if   test "$newuserentries" != "" && test "$newusers" = ""
        then
             log "should not see this log-diff of temp files isn't comparing correctly to actual log of new users"
        elif test "$newuserentries" != ""
        then
             #count new entries and collect json key value pairs from log entry
             echo "$newuserentries" > /usr/local/bin/newuserentries
             diffcount=$(wc -l < /usr/local/bin/newuserentries)
             count=$((diffcount-1))
             while IFS="," read a b c foo; do echo $foo >> /usr/local/bin/onlyjson; done < /usr/local/bin/newuserentries
             cut -b 14- /usr/local/bin/onlyjson > /usr/local/bin/cleanjson
             cat /usr/local/bin/cleanjson | jq '.targetID, .timestamp, .sourceAddress' >> /usr/local/bin/prearray
             readarray -t myarray < /usr/local/bin/prearray
             #create html table snippets for email
             v=0
             for (( c=1; c<=$count; c++ ))
             do  
                cp /usr/local/bin/emailsniporig.html /usr/local/bin/emailsnip$c.html
                __username__=${myarray[$v]}
                __time__=${myarray[$v+1]}
                __ip__=${myarray[$v+2]}
                sed -i "s/__username__/$__username__/g" /usr/local/bin/emailsnip$c.html
                sed -i "s/__time__/$__time__/g" /usr/local/bin/emailsnip$c.html
                sed -i "s/__ip__/$__ip__/g" /usr/local/bin/emailsnip$c.html
                v=$[v+3]
             done
             #concat html table snippets into one file
             for (( c=1; c<=$count; c++ ))
             do  
                cat /usr/local/bin/emailsnip$c.html >> /usr/local/bin/emailconcatsnip.html
             done
             #create full email
             cat /usr/local/bin/emailpart1.html /usr/local/bin/emailconcatsnip.html /usr/local/bin/emailpart2.html > /usr/local/bin/fullemail.html
             #send email
             mailtodomain=$(cat /usr/local/bin/mailtodomain) 
             mutt -F /root/.muttrc -e 'set content_type=text/html' -s "WARNING: New $envirname User Created" pwm-notifications@$mailtodomain < /usr/local/bin/fullemail.html
            #cleanup for next run
             rm -rf /usr/local/bin/fullemail.html
             for (( c=1; c<=$count; c++ ))
             do  
                rm -rf /usr/local/bin/emailsnip$c.html
             done
             rm -rf /usr/local/bin/emailconcatsnip.html
             rm -rf /usr/local/bin/newuserentries
             rm -rf /usr/local/bin/onlyjson
             rm -rf /usr/local/bin/cleanjson
             rm -rf /usr/local/bin/prearray
             echo "$newusers" > /usr/local/bin/prior-newusers.log
             log "emailed list of new users to postfix via mutt"
        else
             echo nothing > /dev/null
             #log "no new users"
        fi

/usr/local/bin/emailsniporig.html:
  file.append:
    - text: |
                                <table border="0" cellpadding="0" cellspacing="0">
                                  <tbody>
                                    <tr>
                                      <td align="left">
                                        <table border="0" cellpadding="0" cellspacing="0">
                                          <tbody>
                                            <tr>
                                              <td> <p>__username__ created an account __time__ from the following IP address: __ip__</p> </td>
                                            </tr>
                                          </tbody>
                                        </table>
                                      </td>
                                    </tr>
                                  </tbody>
                                </table>
        

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
