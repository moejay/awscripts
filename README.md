awscripts
=========

A script that will easily perform different common scenarios on aws instance using ec2-tools.<br>

Features :
- Start ec2 instance (optional : attach ip after starting)
- Stop ec2 instance
- Resize ebs volume on instance ( Detach volume, make snapshot, make new volume from snapshot with new size, attach new volume to instance )


Thanks to :
-Eric Hammond for resize commands @  http://alestic.com/2010/02/ec2-resize-running-ebs-root 
-ADNAM  for script scaffold @ https://github.com/adnam/bash-scaffold
