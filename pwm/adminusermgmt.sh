#!/bin/bash
#
# Description:
#    This script is intended to manage the lifecycle of user accounts imported 
#    from IAM.
#    If users from the required parameter IAM group don't exist on the system, 
#    the script creates them.  If users exist on the instance from a previous 
#    script run but do not exist in the defined IAM group, the script deletes 
#    them.
#    The use of an attached instance role with proper policy to query the IAM 
#    group members is required.
#    This script is intended to be paired with the use of an SSHd
#    AuthorizedKeysCommand setting to enable SSH key access.
#    This script configures the created users to run any sudo commands anywhere 
#    without password.
#
#################################################################
Type="admin"
__ScriptName="${Type}usermgmt.sh"

log()
{
    logger -i -t "${__ScriptName}" -s -- "$1" 2> /dev/console
    echo "$1"
}  # ----------  end of function log  ----------


die()
{
    [ -n "$1" ] && log "$1"
    log "${__ScriptName} script failed"'!'
    exit 1
}  # ----------  end of function die  ----------

usage()
{
    cat << EOT
  Usage:  ${__ScriptName} [options]

  Note:
  If 

  Options:
  -h  Display this message.
  -G  The IAM group name from which to generate local users.
EOT
}  # ----------  end of function usage  ----------

# Parse command-line parameters
while getopts :hG: opt
do
    case "${opt}" in
        h)
            usage
            exit 0
            ;;
        G)
            GROUP_NAME="${OPTARG}"
            ;;
        \?)
            usage
            echo "ERROR: unknown parameter \"$OPTARG\""
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))

# Validate parameters
if [ -z "${GROUP_NAME}" ]
then
    die "GROUP_NAME was not provided"
fi

# Begin main script
#check if aws cli is installed
if ! [ "$(command -v aws)" ]; then
  die "ERROR: aws cli may not be installed"
fi
# If usermgmt wasn't previously executed to create ${Type}lastimportsshusers.log, create blank file for future comparison
if [ -e "/usr/local/bin/${Type}lastimportsshusers.log" ]
   then echo "${Type}lastimportsshusers.log exists" > /dev/null
else
   touch /usr/local/bin/"${Type}"lastimportsshusers.log 
   echo "" > /usr/local/bin/"${Type}"lastimportsshusers.log
fi
#query IAM and create file of current members of group
aws iam get-group --group-name "${GROUP_NAME}" --query "Users[].[UserName]" --output text > /usr/local/bin/"${Type}"importsshusers.log 2>&1
chmod 600 /usr/local/bin/"${Type}"importsshusers.log
if [ $? -eq 255 ]; then
  die "${__ScriptName} aws cli failure - possible issue; cli configuration or EC2 Instance role not setup with proper credentials or policy"
fi
#create sorted files for use with comm
sort < /usr/local/bin/"${Type}"lastimportsshusers.log > /usr/local/bin/"${Type}"lastimportsshusers.sorted.log
sort < /usr/local/bin/"${Type}"importsshusers.log > /usr/local/bin/"${Type}"importsshusers.sorted.log
#create list of users to be imported that weren't already imported
#create file sshuserstocreate from list of items in ${Type}lastimportsshusers that aren't in ${Type}lastimportsshusers
comm -23 /usr/local/bin/"${Type}"importsshusers.sorted.log /usr/local/bin/"${Type}"lastimportsshusers.sorted.log > /usr/local/bin/"${Type}"sshuserstocreate.log
#create list of users to be deleted that no longer exist in IAM group
#create file sshuserstodelete from list of items in discolastimportsshusers that aren't in discolastimportsshusers
comm -13 /usr/local/bin/"${Type}"importsshusers.sorted.log /usr/local/bin/"${Type}"lastimportsshusers.sorted.log > /usr/local/bin/"${Type}"sshuserstodelete.log
#create new users with locked password for ssh and add to sudoers.d folder
while read User
do
  if id -u "$User" > /dev/null 2>&1; then
    echo "$User exists"
  else
    /usr/sbin/adduser "$User"
    passwd -l "$User"
    if [ $? -ne 3 ]; then
      echo "$User ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$User"
      log "User $User created by ${__ScriptName}"
    fi
  fi
done < /usr/local/bin/"${Type}"sshuserstocreate.log
#delete users not in IAM group
while read User
do
    /usr/sbin/userdel -r "$User"
    if [ $? -ne 6 ]; then
      rm /etc/suoders.d/"$User"
      log "User $User deleted by ${__ScriptName}"
    fi
done < /usr/local/bin/"${Type}"sshuserstodelete.log
shred -u /usr/local/bin/"${Type}"sshuserstodelete.log
shred -u /usr/local/bin/"${Type}"sshuserstocreate.log
shred -u /usr/local/bin/"${Type}"importsshusers.sorted.log
shred -u /usr/local/bin/"${Type}"lastimportsshusers.sorted.log
#get ready for next run
#move current ${Type}lastimportsshusers list to ${Type}lastimportsshusers list
mv /usr/local/bin/"${Type}"importsshusers.log /usr/local/bin/"${Type}"lastimportsshusers.log
chmod 600 /usr/local/bin/"${Type}"lastimportsshusers.log
