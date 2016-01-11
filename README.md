# pwm-formula
Salt formula for deploying PWM

when using with SimpleAD requires unsupported schema extension and dsacls adjustment - details coming

to be used with systemprep

using pwmstrap.sh to:
to add /srv/salt/formulas/pwm-formula to /etc/salt/minion file_roots section and 'service restart salt-minion'
clone this formula to /srv/salt/formulas/

--

# need to work on:

change detection for config file with action to put back to s3 and update hash in local salt state (triggering put of salt state to s3)
-potentially use incrontab or look at salt state = done; validate

securing tomcat

redirects from root to pwm webapp = done; validate

making salt states fully stateful
