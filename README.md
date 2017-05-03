# pwm-formula
## Salt formula for deploying PWM

when using with AD requires schema extension and dsacls adjustment - details coming

to be used with centos6 spel ami and watchmaker

## In order to neutralize the formula for ~any environment certain files and/or variables are expected by the salt states [handled by cfn]:
- `/usr/local/bin/envirname` should contain a single word environment name in all caps (i.e. `EXAMPLE`)
- `/usr/local/bin/resourcedomain` should contain the FQDN of the domain name where helpdesk should be pointed to for other resources such as Guacamole, used in the email notifying helpdesk of creation of new user accounts (i.e. `example.com`)
- `/usr/local/bin/mailfromdomain` should contain the FQDN of the domain name from which emails can originate, used as source for sending email out notification to helpdesk of new user accounts (i.e. `example.com`)
- `/usr/local/bin/mailtodomain` should contain the FQDN of the domain name to which new pwm-notifications emails should be sent, used as destination for sending email out notification to helpdesk of new user accounts (i.e. `example.com`)
- `/usr/local/bin/configbucketname` should contain the shortname of the s3 bucket from which to download and upload the PWM Configuration XML file (i.e. `example-pwmconfig`)

## The following three commands should be run prior to running the pwm salt state in order to populate environment variables used in the state(s) [handled by cfn]:

```bash
export ENVIRNAME=$(cat /usr/local/bin/envirname)
export RESOURCEDOMAIN=$(cat /usr/local/bin/resourcedomain)
export CONFIGBUCKETNAME=$(cat /usr/local/bin/configbucketname)
```

utilizes httpd for proxy from tomcat 8080 to public port

utilizes postfix for receiving email locally from app and script to be sent via AWS SES

current cfn templates assume the existance of a private s3 bucket used for get and put of the PwmConfiguration.xml file which contains the configuration state of the PWM instance
(s3 put operations for the PwmConfiguration.xml file look for changes to the file before executing, file change monitor starts 20min after script execution)
in salt states, the same s3 bucket is used to get the SES username and password as well as a postfix configuration script 
in cfn, the s3 bucket name is used in the creation of an instance role for allowing instance access to files

current cfn templates utilize a variation of https://github.com/widdix/aws-ec2-ssh to grant IAM group members access to the EC2 instance

--

# need to work on:

move to native tomcat

making salt states fully stateful

test and move to centos7
