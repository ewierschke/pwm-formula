include:
  - pwm/pwmconfigfile
  - pwm/adpasswordexpirenotify
  - pwm/newusernotifyviaemail
  - pwm/newusernotifyviaapi

/usr/share/tomcat/webapps/ROOT/WEB-INF/jsp/fragment/envwelcome.jsp:
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
            <p style="text-align: center;"><strong>Welcome to the {{ salt['environ.get']('ENVIRNAME') }} account management system. &nbsp;</strong></p>
            <p style="text-align: center;">If you do not yet have a username please select 'New User Registration'.</p>
            <p style="text-align: center;">Otherwise, login with your credentials, or select 'Forgotten Password' to recover your credentials.</p>
            <p>&nbsp;</p>
        </body>
        </html>

{% set myvar = 42%}
addenvtexttologin-{{ myvar }}:
  file.blockreplace:
    - name: /usr/share/tomcat/webapps/ROOT/WEB-INF/jsp/login.jsp
    - marker_start: "        </table>"
    - marker_end: "    </div>"
    - show_changes: True
    - backup: '.bak'

addenvtexttologin-{{ myvar }}-accumulated1:
  file.accumulated:
    - filename: /usr/share/tomcat/webapps/ROOT/WEB-INF/jsp/login.jsp
    - name: my-accumulator-{{ myvar }}
    - text: '            </pwm:if>'
    - require_in:
      - file: addenvtexttologin-{{ myvar }}

addenvtexttologin-{{ myvar }}-accumulated2:
  file.accumulated:
    - filename: /usr/share/tomcat/webapps/ROOT/WEB-INF/jsp/login.jsp
    - name: my-accumulator-{{ myvar }}
    - text: '        </pwm:if>'
    - require_in:
      - file: addenvtexttologin-{{ myvar }}

addenvtexttologin-{{ myvar }}-accumulated3:
  file.accumulated:
    - filename: /usr/share/tomcat/webapps/ROOT/WEB-INF/jsp/login.jsp
    - name: my-accumulator-{{ myvar }}
    - text: '    <%@ include file="fragment/envwelcome.jsp" %>'
    - require_in:
      - file: addenvtexttologin-{{ myvar }}

/usr/share/tomcat/webapps/ROOT/public/resources/js/newuser.js:
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
    - name: /usr/share/tomcat/webapps/ROOT/WEB-INF/jsp/fragment/form.jsp
    - pattern:        maxlength="<%=loopConfiguration.getMaximumLength.*
    - count: 1
    - repl: |{% raw %}
               maxlength="<%=loopConfiguration.getMaximumLength()%>"
                               <%if((loopConfiguration.getName().equals("sn"))||(loopConfiguration.getName().equals("givenName"))){%> onblur='autoGen(this.form.givenName.value, this.form.initials.value, this.form.sn.value)'<%}%>/>{% endraw %}
