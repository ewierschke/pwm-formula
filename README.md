# pwm-formula
Salt formula for deploying PWM

when using with SimpleAD requires unsupported schema extension and dsacls adjustment - details coming

to be used with systemprep

using pwmstrap.sh to:
to add /srv/salt/formulas/pwm-formula to /etc/salt/minion file_roots section and 'service restart salt-minion'
clone this formula to /srv/salt/formulas/

utilizes httpd for proxy from tomcat to public port

utilizes postfix for receiving email locally from app to be sent via SES config

--

# need to work on:

customization of pwm itself to format cn and sAMAccountName based on entries provided = done; validate

send email whenever new user account created = done; validate (sending to personal email address; checking log every 5min; need to send to alias)

securing tomcat

making salt states fully stateful
