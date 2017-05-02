# pwm-formula
Salt formula for deploying PWM

when using with SimpleAD requires unsupported schema extension and dsacls adjustment - details coming

to be used with watchmaker

In order to neutralize the formula for ~any environment certain files and/or variables are expected by the salt states:
- /usr/local/bin/envirname should contain a single word environment name in all caps (i.e. EXAMPLE)
- /usr/local/bin/resourcedomain should contain the FQDN of the domain name where users should be pointed to for other resources such as Guacamole, used in the new user email (i.e. example.com)
- /usr/local/bin/mailfromdomain should contain the FQDN of the domain name from which emails can originate, used in the new user email (i.e. example.com)
- /usr/local/bin/mailtodomain should contain the FQDN of the domain name to which new pwm-notifications emails should be sent, used in the new user email (i.e. example.com)
- /usr/local/bin/configbucketname should contain the shortname of the s3 bucket from which to download and upload the PWM Configuration XML file (i.e. example-pwmconfig)
The following three commands should be run prior to running the pwm salt state in order to populate environment variables used in the state(s):

```bash
export ENVIRNAME=`cat /usr/local/bin/envirname`
export RESOURCEDOMAIN=`cat /usr/local/bin/resourcedomain`
export CONFIGBUCKETNAME=`cat /usr/local/bin/configbucketname`
```

utilizes httpd for proxy from tomcat to public port

utilizes postfix for receiving email locally from app to be sent via SES config

--

# need to work on:

customization of pwm itself to format cn and sAMAccountName based on entries provided = done; validate

send email whenever new user account created = done; validate (sending to personal email address; checking log every 5min; need to send to alias)

securing tomcat

making salt states fully stateful
