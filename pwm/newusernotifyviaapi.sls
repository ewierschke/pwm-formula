{%- if salt['grains.has_value']('setupnewusernotifyviaapi') %}
{%- if grains['setupnewusernotifyviaapi'] == 'yes' %}
notifyviaapipkginstall:
  pkg.installed:
    - names:
      - php
      - jq

/usr/local/bin/ostapi-newuserticket.php:
  file.append:
    - text: |
        #!/usr/bin/php -q
        <?php
        #
        # Configuration: Enter the url and key. That is it.
        #  url => URL to api/task/cron e.g #  http://yourdomain.com/support/api/tickets.json
        #  key => API's Key (see admin panel on how to generate a key)
        #  $data add custom required fields to the array.
        #
        #  Originally authored by jared@osTicket.com
        #  Modified by ntozier@osTicket / tmib.net
        
        // If 1, display things to debug.
        $debug="0";
        
        // You must configure the url and key in the array below.
        $config = array(
                'url'=>'_OSTURL_/api/http.php/tickets.json',  // URL to site.tld/api/tickets.json
                'key'=>'_OSTAPIKEY_'  // API Key goes here
        );
        # NOTE: some people have reported having to use "http://your.domain.tld/api/http.php/tickets.json" instead.
        
        if($config['url'] === 'http://your.domain.tld/api/tickets.json') {
          echo "<p style=\"color:red;\"><b>Error: No URL</b><br>You have not configured this script with your URL!</p>";
          echo "Please edit this file ".__FILE__." and add your URL at line 18.</p>";
          die();  
        }
        if(IsNullOrEmptyString($config['key']) || ($config['key'] === 'PUTyourAPIkeyHERE'))  {
          echo "<p style=\"color:red;\"><b>Error: No API Key</b><br>You have not configured this script with an API Key!</p>";
          echo "<p>Please log into osticket as an admin and navigate to: Admin panel -> Manage -> Api Keys then add a new API Key.<br>";
          echo "Once you have your key edit this file ".__FILE__." and add the key at line 19.</p>";
          die();
        }
        
        # Fill in the data for the new ticket, this will likely come from $_POST.
        # NOTE: your variable names in osT are case sensiTive. 
        # So when adding custom lists or fields make sure you use the same case
        
        $message = '<html><body style="font-family: Helvetica, Arial, san-serif; font-size:12pt;"><p>';
        $message .= 'Someone just created a new _ENVIRNAME_ account that needs approval.<br>';
        $message .= 'The following new account was created:<br><br>';
        $message .= '__username__ created an account at __time__ GMT from the following IP address: __ip__<br><br> ';
        $message .= 'The account is currently disabled, please confirm the account justification with the account manager, enable the account, and send the new user the appropriate notification.<br><br>';
        $message .= 'Note - Ticket created via API from PWM.</p>';
        
        $data = array(
            'name'      =>      'The PWM via API',  // from name aka User/Client Name
            'email'     =>      '_EMAILFROMPWM_',  // from email aka User/Client Email
            'subject'   =>      'NEW USER: __username__ created an account in _ENVIRNAME_',  // test subject, aka Issue Summary
            'message'   =>      "data:text/html;charset=utf-8,$message",
            'topicId'   =>      '1', // the help Topic that you want to use for the ticket 
            'attachments' => array()
        );
        
        # more fields are available and are documented at:
        # https://github.com/osTicket/osTicket-1.8/blob/develop/setup/doc/api/tickets.md
        
        if($debug=='1') {
          print_r($data);
          die();
        }
        
        #pre-checks
        function_exists('curl_version') or die('CURL support required');
        function_exists('json_encode') or die('JSON support required');
        
        #set timeout
        set_time_limit(30);
        
        #curl post
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $config['url']);
        curl_setopt($ch, CURLOPT_POST, 1);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
        curl_setopt($ch, CURLOPT_USERAGENT, 'osTicket API Client v1.8');
        curl_setopt($ch, CURLOPT_HEADER, FALSE);
        curl_setopt($ch, CURLOPT_HTTPHEADER, array( 'Expect:', 'X-API-Key: '.$config['key']));
        curl_setopt($ch, CURLOPT_FOLLOWLOCATION, FALSE);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, TRUE);
        $result=curl_exec($ch);
        $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        if ($code != 201)
            die('Unable to create ticket: '.$result);
        
        $ticket_id = (int) $result;
        #$toconsole = "Ticket number ".$ticket_id." created.\n";
        #echo $toconsole;
        
        # Continue onward here if necessary. $ticket_id has the ID number of the
        # newly-created ticket
        
        function IsNullOrEmptyString($question){
            return (!isset($question) || trim($question)==='');
        }
        ?>

/usr/local/bin/ostapi-envadjust.sh:
  file.append:
    - text: |
        #!/bin/bash
        #--pull variables from files--
        export ENVIRNAME=$(cat /usr/local/bin/envirname)
        export OSTURL=$(cat /usr/local/bin/osturl)
        export EMAILFROMPWM=$(cat /usr/local/bin/emailfrompwm)
        export OSTAPIKEY=$(cat /usr/local/bin/ostapikey)
        #--envir adjust--
        sed -i.env1bak "s|_ENVIRNAME_|${ENVIRNAME}|g" /usr/local/bin/ostapi-newuserticket.php
        sed -i.emailfrompwmbak "s|_EMAILFROMPWM_|${EMAILFROMPWM}|g" /usr/local/bin/ostapi-newuserticket.php
        sed -i.ostbak "s|_OSTURL_|${OSTURL}|g" /usr/local/bin/ostapi-newuserticket.php
        sed -i.ostbak "s|_OSTAPIKEY_|${OSTAPIKEY}|g" /usr/local/bin/ostapi-newuserticket.php

ostapi-envadjustmode:
  file.managed:
    - name: /usr/local/bin/ostapi-envadjust.sh
    - mode: 700
    - replace: False

run ostapi-envadjust script:
  cmd.run:
    - name: /usr/local/bin/ostapi-envadjust.sh

/usr/local/bin/watchnewuser-api.sh:
  file.append:
    - text: |
        #!/bin/sh
        # Script that will grep a log file and run a php script when a specified pattern is encountered.
        __ScriptName="watchnewuser-api.sh"
        
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
             #json keys differ in pwm18-changed to perpetratorID
             cat /usr/local/bin/cleanjson | jq '.perpetratorID, .timestamp, .sourceAddress' >> /usr/local/bin/prearray
             readarray -t myarray < /usr/local/bin/prearray
             #create html table snippets for email
             v=0
             for (( c=1; c<=$count; c++ ))
             do  
                cp /usr/local/bin/ostapi-newuserticket.php /usr/local/bin/ostapi-newuserticket$c.php
                __username__=${myarray[$v]}
                __time__=${myarray[$v+1]}
                __ip__=${myarray[$v+2]}
                sed -i "s/__username__/$__username__/g" /usr/local/bin/ostapi-newuserticket$c.php
                sed -i "s/__time__/$__time__/g" /usr/local/bin/ostapi-newuserticket$c.php
                sed -i "s/__ip__/$__ip__/g" /usr/local/bin/ostapi-newuserticket$c.php
                /usr/bin/php /usr/local/bin/ostapi-newuserticket$c.php
                v=$[v+3]
             done
             #cleanup for next run
             for (( c=1; c<=$count; c++ ))
             do
                shred -u /usr/local/bin/ostapi-newuserticket$c.php
             done
             shred -u /usr/local/bin/newuserentries
             shred -u /usr/local/bin/onlyjson
             shred -u /usr/local/bin/cleanjson
             shred -u /usr/local/bin/prearray
             echo "$newusers" > /usr/local/bin/prior-newusers.log
             chmod 600 /usr/local/bin/prior-newusers.log
             log "created tickets for list of new users via osticket api script"
        else
             echo nothing > /dev/null
             #log "no new users"
        fi


watchnewuser-apimode:
  file.managed:
    - name: /usr/local/bin/watchnewuser-api.sh
    - mode: 700
    - replace: False

runcrondservice:
  service.running:
    - name: crond
    - enable: True

/etc/crontab:
  file.append:
    - text: |
        */1 * * * * root /usr/local/bin/watchnewuser-api.sh

{% endif %}
{% endif %}