#!/bin/bash
#------------------------------------------------------------------------------------
# What: AWScripts
# Author: Moe
# Licence: Beer licence, if you don't know what that is, buy me a beer and i'll tell you
#
# Features:
#   log "A log message"
#   debug "A debug message only displayed if '-v' option passed"
#   error "A fatal error message and exit with code:" 2
#   usage - print a usage message
#   get_options - parse command-line options, defaults below
#
# Standard command-line options:
#   -v verbose
#   -h help message
#   -V version number
# Long-format options:
#   --version
#   --help
#
#------------------------------------------------------------------------------------
#
# awscriptst.sh - Short description
#
# author:       Author of script
# contact:          Email
# since:        Date
#
#------------------------------------------------------------------------------------

#------------------------------------------------------------------------------------
# SCRIPT CONFIGURATION
#------------------------------------------------------------------------------------

SCRIPT_NAME=`basename $0`

# If debug information should be shown
VERBOSE=

VERSION=0.1.1

# Add your own global variables here
ACTION=
SIZE=
INSTANCE_ID=
INSTANCE_IP=
CREDENTIALS=
NEWTYPE=
K= #The Access key 
S= #The Access secret

#------------------------------------------------------------------------------------
# UTILITY FUNCTIONS
#------------------------------------------------------------------------------------

# print a log a message
log ()
{
    echo "[${SCRIPT_NAME}]: $1" > /dev/stderr
}

# print a debug message - only outputs is VERBOSE flag is set
debug()
{
    [ "$VERBOSE" ] && echo "[${SCRIPT_NAME}]: $1" > /dev/stderr
}

# print an error message and exit()
error()
{
    echo "[${SCRIPT_NAME}] ERROR: $1" > /dev/stderr
    [ $# -gt 1 ] && exit $2
    exit 1
}

# Define your own script functions here

# Print a usage message
usage()
{
cat << USAGE
usage: $0 [-v] [-h] -a action -i instance_id [ -- args ... ]

Short description

REQUIRED OPTIONS:
    -a action    (  resize , retype, stop, start )
    -i instance id 
    -e elsatic ip (You must have this ip allocated )
    -s   size in gb (eg:: 20)
    -t type (used in retype)

OTHER OPTIONS:
    -K	       Access key ( required with -S )
    -S	       Access secret ( required with -K )
    -v         Show debuging messages
    -h         Show this help message
    -V         Show version
USAGE
}

# Get the script options
get_options()
{
    while getopts "a:b:e:i:t:s:K:S:hvV-:" OPTION
    do
        if [ $OPTION == "-" ]; then
            OPTION=$OPTARG
        fi
        case $OPTION in
            a) ACTION=${OPTARG};;
            s) SIZE=${OPTARG};;
            i) INSTANCE_ID=${OPTARG};;
            e) INSTANCE_IP=${OPTARG};;
	    t) NEWTYPE=${OPTARG};;
	    K) K=${OPTARG};;
	    S) S=${OPTARG};;
            h)  usage && exit 0;;
       'help')  usage && exit 0;;
            V)  echo $VERSION && exit 0;;
    'version')  echo $VERSION && exit 0;;
            v)  VERBOSE=1;;
            \?) echo "Invalid option" && usage && exit 1;;
        esac
    done
}

start_instance()
{
        echo "Starting instance"
        instanceid=$INSTANCE_ID
        eip=$INSTANCE_IP

        ec2-start-instances  $CREDENTIALS $instanceid
        while ! ec2-describe-instances $CREDENTIALS $instanceid | grep -q running; do sleep 1; done
        ec2-describe-instances  $CREDENTIALS $instanceid

        if [ ! -z "$eip" ]
        then
       		attach_ip $eip $instanceid
	fi
        echo "Instance started"

}

stop_instance()
{
        echo "Stopping instance"
        instanceid=$INSTANCE_ID
        ec2-stop-instances  $CREDENTIALS $instanceid
        echo "Stopped"
}
#attach ip to instance id
attach_ip()
{
	echo "Attaching ip $1 to instance $2"
	ec2-associate-address  $CREDENTIALS -i $2 $1
	if [ $? == 0 ]
	then
		echo "$2 : $1"
	else
		echo "Failed to attach ip"
	fi
}
resize()
{
        instanceid=$INSTANCE_ID
        size=$SIZE
        echo "Getting old volume id "
        oldvolumeid=$(ec2-describe-instances $CREDENTIALS $instanceid |
                  egrep "^BLOCKDEVICE./dev/sda1" | cut -f3)
                zone=$(ec2-describe-instances $CREDENTIALS $instanceid | egrep ^INSTANCE | cut -f12)
        echo "instance $instanceid in $zone with original volume $oldvolumeid"

        echo "Stopping instance"
        stop_instance
        echo "Instance stoped,detaching volume "
        while ! ec2-detach-volume  $CREDENTIALS $oldvolumeid; do sleep 1; done
        echo "volume detached"
        echo "Creating snapshot "
        snapshotid=$(ec2-create-snapshot  $CREDENTIALS $oldvolumeid | cut -f2)
        while ec2-describe-snapshots  $CREDENTIALS $snapshotid | grep -q pending; do sleep 1; done
        echo "snapshot: $snapshotid"
        echo "Creating new volume from $snapshotid"
        newvolumeid=$(ec2-create-volume  $CREDENTIALS  --availability-zone $zone   --size $size   --snapshot $snapshotid |
  cut -f2)
        echo "new volume: $newvolumeid"
        echo "Attaching the new volume"
        ec2-attach-volume  $CREDENTIALS  --instance $instanceid   --device /dev/sda1   $newvolumeid
        while ! ec2-describe-volumes $CREDENTIALS $newvolumeid | grep -q attached; do sleep 1; done

        echo "Starting the instance with the resized volume"
        start_instance

        echo "All done"
        echo "Now run the following after after SSH'ing into the machine"
        echo '# ext3 root file system (most common)
        sudo resize2fs /dev/sda1
        #(OR)
        sudo resize2fs /dev/xvda1

        # XFS root file system (less common):
        sudo apt-get update && sudo apt-get install -y xfsprogs
        sudo xfs_growfs /'


}
retype()
{
	stop_instance
	change_type  $INSTANCE_ID $NEWTYPE
	start_instance
}	
change_type()
{
	echo "Modifying instance type to $2"
	while ! ec2-modify-instance-attribute $CREDENTIALS --instance-type $2  $1; do sleep 1; done
	echo  "Instance $1 is now $2 "
}
check_credentials()
{
    if [  -z "$K" -o  -z "$S" ] 
    then
	echo "Using global credentials"
    else
	CREDENTIALS="-O $K -W $S"
    fi
		
}

get_status()
{
    ec2-describe-instances $CREDENTIALS $1
}
main()
{
    get_options "$@"
    check_credentials
    # Put the rest of iyour main script here
    case $ACTION in
        'resize')
                resize 
                ;;
	'retype')
		retype
		;;
	'status')
		get_status $INSTANCE_ID
		;;
        'start')
                start_instance
                ;;
        'stop')
                stop_instance
                ;;
        *) echo "Invalid action " && usage && exit 1;;
    esac

    exit 0
}

main "$@"


