include:
  - pwm/pwmconfigfile
  - pwm/adpasswordexpirenotify

mailxinstall:
  pkg.installed:
    - names:
      - mutt
      - jq

/usr/local/bin/watchnewuser.sh:
  file.append:
    - text: |
        #!/bin/sh
        # This is a script that will grep a log file and send an email when a specified pattern is encountered.
        __ScriptName="watchnewuser.sh"
        
        log()
        {
            logger -i -t "${__ScriptName}" -s -- "$1" 2> /dev/console
            echo "$1"
        }  # ----------  end of function log  ----------
        
        #log "checking for new users"
        newusers=$(grep -a "CREATE_USER" /usr/share/tomcat/webapps/ROOT/WEB-INF/logs/PWM.log)
        echo "$newusers" > /usr/local/bin/current-newusers.log
        chmod 600 /usr/local/bin/current-newusers.log
        
        if   [ -e "/usr/local/bin/prior-newusers.log" ]
        then
             echo "prior-newusers.log Exists" > /dev/null
        else
             touch /usr/local/bin/prior-newusers.log
             echo "" > /usr/local/bin/prior-newusers.log
             chmod 600 /usr/local/bin/prior-newusers.log
        fi
        
        #compare prior newusers to current newusers
        newuserentries=$(diff --suppress-common-lines -a /usr/local/bin/prior-newusers.log /usr/local/bin/current-newusers.log | grep -v "^---" | grep -v "^<")
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
                #get username
                user=${myarray[$v]}
                #remove last fullemail
                rm -rf /usr/local/bin/fullemail.html
                #create full email
                cat /usr/local/bin/emailpart1.html /usr/local/bin/emailsnip$c.html /usr/local/bin/emailpart2.html > /usr/local/bin/fullemail.html
                #send email
                envirname=$(cat /usr/local/bin/envirname)
                mailtodomain=$(cat /usr/local/bin/mailtodomain)
                mailfromdomain=$(cat /usr/local/bin/mailfromdomain)
                #mutt -F /root/.muttrc -e 'set content_type=text/html' -s "WARNING: $user created an account in $envirname" pwm-notifications@$mailtodomain < /usr/local/bin/fullemail.html
                mutt -F /root/.muttrc -e 'set content_type=text/html' -s "NEW USER: $user created an account in $envirname" help@$mailfromdomain < /usr/local/bin/fullemail.html
                v=$[v+3]
             done
             #cleanup for next run
             shred -u /usr/local/bin/fullemail.html
             for (( c=1; c<=$count; c++ ))
             do
                shred -u /usr/local/bin/emailsnip$c.html
             done
             shred -u /usr/local/bin/emailconcatsnip.html
             shred -u /usr/local/bin/newuserentries
             shred -u /usr/local/bin/onlyjson
             shred -u /usr/local/bin/cleanjson
             shred -u /usr/local/bin/prearray
             echo "$newusers" > /usr/local/bin/prior-newusers.log
             chmod 600 /usr/local/bin/prior-newusers.log
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
        

/usr/local/bin/emailpart1.html:
  file.append:
    - text: |
        <!doctype html>
        <html>
          <head>
            <meta name="viewport" content="width=device-width" />
            <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
            <title>Simple Transactional Email</title>
            <style>
              /* -------------------------------------
                  GLOBAL RESETS
              ------------------------------------- */
              img {
                border: none;
                -ms-interpolation-mode: bicubic;
                max-width: 100%; }
        
              body {
                background-color: #f6f6f6;
                font-family: sans-serif;
                -webkit-font-smoothing: antialiased;
                font-size: 14px;
                line-height: 1.4;
                margin: 0;
                padding: 0; 
                -ms-text-size-adjust: 100%;
                -webkit-text-size-adjust: 100%; }
        
              table {
                border-collapse: separate;
                mso-table-lspace: 0pt;
                mso-table-rspace: 0pt;
                width: 100%; }
                table td {
                  font-family: sans-serif;
                  font-size: 14px;
                  vertical-align: top; }
        
              /* -------------------------------------
                  BODY & CONTAINER
              ------------------------------------- */
        
              .body {
                background-color: #f6f6f6;
                width: 100%; }
        
              /* Set a max-width, and make it display as block so it will automatically stretch to that width, but will also shrink down on a phone or something */
              .container {
                display: block;
                Margin: 0 auto !important;
                /* makes it centered */
                max-width: 580px;
                padding: 10px;
                width: 580px; }
        
              /* This should also be a block element, so that it will fill 100% of the .container */
              .content {
                box-sizing: border-box;
                display: block;
                Margin: 0 auto;
                max-width: 580px;
                padding: 10px; }
        
              /* -------------------------------------
                  HEADER, FOOTER, MAIN
              ------------------------------------- */
              .main {
                background: #fff;
                border-radius: 3px;
                width: 100%; }
        
              .wrapper {
                box-sizing: border-box;
                padding: 20px; }
        
              .footer {
                clear: both;
                padding-top: 10px;
                text-align: center;
                width: 100%; }
                .footer td,
                .footer p,
                .footer span,
                .footer a {
                  color: #999999;
                  font-size: 12px;
                  text-align: center; }
        
              /* -------------------------------------
                  TYPOGRAPHY
              ------------------------------------- */
              h1,
              h2,
              h3,
              h4 {
                color: #000000;
                font-family: sans-serif;
                font-weight: 400;
                line-height: 1.4;
                margin: 0;
                Margin-bottom: 30px; }
        
              h1 {
                font-size: 35px;
                font-weight: 300;
                text-align: center;
                text-transform: capitalize; }
        
              p,
              ul,
              ol {
                font-family: sans-serif;
                font-size: 14px;
                font-weight: normal;
                margin: 0;
                Margin-bottom: 15px; }
                p li,
                ul li,
                ol li {
                  list-style-position: inside;
                  margin-left: 5px; }
        
              a {
                color: #3498db;
                text-decoration: underline; }
        
              /* -------------------------------------
                  BUTTONS
              ------------------------------------- */
              .btn {
                box-sizing: border-box;
                width: 100%; }
                .btn > tbody > tr > td {
                  padding-bottom: 15px; }
                .btn table {
                  width: auto; }
                .btn table td {
                  background-color: #ffffff;
                  border-radius: 5px;
                  text-align: center; }
                .btn a {
                  background-color: #ffffff;
                  border: solid 1px #3498db;
                  border-radius: 5px;
                  box-sizing: border-box;
                  color: #3498db;
                  cursor: pointer;
                  display: inline-block;
                  font-size: 14px;
                  font-weight: bold;
                  margin: 0;
                  padding: 12px 25px;
                  text-decoration: none;
                  text-transform: capitalize; }
        
              .btn-primary table td {
                background-color: #3498db; }
        
              .btn-primary a {
                background-color: #3498db;
                border-color: #3498db;
                color: #ffffff; }
        
              /* -------------------------------------
                  OTHER STYLES THAT MIGHT BE USEFUL
              ------------------------------------- */
              .last {
                margin-bottom: 0; }
        
              .first {
                margin-top: 0; }
        
              .align-center {
                text-align: center; }
        
              .align-right {
                text-align: right; }
        
              .align-left {
                text-align: left; }
        
              .clear {
                clear: both; }
        
              .mt0 {
                margin-top: 0; }
        
              .mb0 {
                margin-bottom: 0; }
        
              .preheader {
                color: transparent;
                display: none;
                height: 0;
                max-height: 0;
                max-width: 0;
                opacity: 0;
                overflow: hidden;
                mso-hide: all;
                visibility: hidden;
                width: 0; }
        
              .powered-by a {
                text-decoration: none; }
        
              hr {
                border: 0;
                border-bottom: 1px solid #f6f6f6;
                Margin: 20px 0; }
        
              /* -------------------------------------
                  RESPONSIVE AND MOBILE FRIENDLY STYLES
              ------------------------------------- */
              @media only screen and (max-width: 620px) {
                table[class=body] h1 {
                  font-size: 28px !important;
                  margin-bottom: 10px !important; }
                table[class=body] p,
                table[class=body] ul,
                table[class=body] ol,
                table[class=body] td,
                table[class=body] span,
                table[class=body] a {
                  font-size: 16px !important; }
                table[class=body] .wrapper,
                table[class=body] .article {
                  padding: 10px !important; }
                table[class=body] .content {
                  padding: 0 !important; }
                table[class=body] .container {
                  padding: 0 !important;
                  width: 100% !important; }
                table[class=body] .main {
                  border-left-width: 0 !important;
                  border-radius: 0 !important;
                  border-right-width: 0 !important; }
                table[class=body] .btn table {
                  width: 100% !important; }
                table[class=body] .btn a {
                  width: 100% !important; }
                table[class=body] .img-responsive {
                  height: auto !important;
                  max-width: 100% !important;
                  width: auto !important; }}
        
              /* -------------------------------------
                  PRESERVE THESE STYLES IN THE HEAD
              ------------------------------------- */
              @media all {
                .ExternalClass {
                  width: 100%; }
                .ExternalClass,
                .ExternalClass p,
                .ExternalClass span,
                .ExternalClass font,
                .ExternalClass td,
                .ExternalClass div {
                  line-height: 100%; }
                .apple-link a {
                  color: inherit !important;
                  font-family: inherit !important;
                  font-size: inherit !important;
                  font-weight: inherit !important;
                  line-height: inherit !important;
                  text-decoration: none !important; } 
                .btn-primary table td:hover {
                  background-color: #34495e !important; }
                .btn-primary a:hover {
                  background-color: #34495e !important;
                  border-color: #34495e !important; } }
        
            </style>
          </head>
          <body class="">
            <table border="0" cellpadding="0" cellspacing="0" class="body">
              <tr>
                <td>&nbsp;</td>
                <td class="container">
                  <div class="content">
        
                    <!-- START CENTERED WHITE CONTAINER -->
                    <span class="preheader">New {{ salt['environ.get']('ENVIRNAME') }} Account Created.</span>
                    <table class="main">
        
                      <!-- START MAIN CONTENT AREA -->
                      <tr>
                        <td class="wrapper">
                          <table border="0" cellpadding="0" cellspacing="0">
                            <tr>
                              <td>
                                <p>Hi there,</p>
                                <p>Someone just created a new {{ salt['environ.get']('ENVIRNAME') }} account that needs approval.</p>
                                <p>The following new account(s) were created:</p>
        <!-- https://github.com/leemunroe/responsive-html-email-template -->
        

/usr/local/bin/emailpart2.html:
  file.append:
    - text: |
        <!-- https://github.com/leemunroe/responsive-html-email-template -->
                                <table border="0" cellpadding="0" cellspacing="0" class="btn btn-primary">
                                  <tbody>
                                    <tr>
                                      <td align="left">
                                        <table border="0" cellpadding="0" cellspacing="0">
                                          <tbody>
                                            <tr>
                                              <td> <a href="https://guac.{{ salt['environ.get']('RESOURCEDOMAIN') }}" target="_blank">Login to Guac to review the Account</a> </td>
                                            </tr>
                                          </tbody>
                                        </table>
                                      </td>
                                    </tr>
                                  </tbody>
                                </table>
                                <p>The account(s) should currently be disabled, please confirm the account justification with the account manager, enable the account, and send the new user(s) the appropriate notification.</p>
                                <p>Good luck! Hope it works.</p>
                              </td>
                            </tr>
                          </table>
                        </td>
                      </tr>
        
                      <!-- END MAIN CONTENT AREA -->
                      </table>
        
                    <!-- START FOOTER -->
                    <div class="footer">
                      <table border="0" cellpadding="0" cellspacing="0">
                        <tr>
                          <td class="content-block">
                            <span class="apple-link">{{ salt['environ.get']('ENVIRNAME') }}</span>
                            <br> Don't like these emails? <a href="http://i.imgur.com/CScmqnj.gif">Unsubscribe</a>.
                          </td>
                        </tr>
                        <tr>
                          <td class="content-block powered-by">
                            Powered by <a href="http://htmlemail.io">HTMLemail</a>.
                          </td>
                        </tr>
                      </table>
                    </div>
                    <!-- END FOOTER -->
                    
                  <!-- END CENTERED WHITE CONTAINER -->
                  </div>
                </td>
                <td>&nbsp;</td>
              </tr>
            </table>
          </body>
        </html>
        <!-- https://github.com/leemunroe/responsive-html-email-template -->
        

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
    - mode: 700
    - replace: False

run createmuttrc script:
  cmd.run:
    - name: /usr/local/bin/createmuttrc.sh

watchnewusermode:
  file.managed:
    - name: /usr/local/bin/watchnewuser.sh
    - mode: 700
    - replace: False

runcrondservice:
  service.running:
    - name: crond
    - enable: True

/etc/crontab:
  file.append:
    - text: |
        */1 * * * * root /usr/local/bin/watchnewuser.sh

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
            <p style="text-align: center;">If you have already been provided a username but need to setup your password please select 'Activate Account'.</p>
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
