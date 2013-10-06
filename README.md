awscripts
=========

A script that will easily perform different common scenarios on aws instance using ec2-tools.<br>

<h2>Installation/Requirements</h2>
- This script depends on ec2-tools, as long as you can run `ec2-describe-instances "AN_INSTANCE_ID"` you should be ok 


<h2>Features :</h2>
<ul>
<li> Start ec2 instance (optional : attach ip after starting) </li>
<li> Stop ec2 instance </li>
<li> Resize ebs volume on instance ( Detach volume, make snapshot, make new volume from snapshot with new size, attach new volume to instance )</li>
<li> Change instance type ( -t t1.micro ,m1.small , etc.. ) </li>
</ul>

<h2>Examples : </h2>
<ul>
<li> resize instance to and  `./awscripts.sh -a resize -s 40 -i i-12345 ` </li>
<li> Change instance type and attach ip  `./awsciprts.sh -a retype -t t1.micro -i i-12345 -e 123.123.123.123` </li>
<li> Start with ip attached `./awscripts.sh -a start -i i-12345 -e 123.123.123.123` </li>

</ul>


<h3>Thanks to :</h3>
<ul>
<li>Eric Hammond for resize commands @  http://alestic.com/2010/02/ec2-resize-running-ebs-root </li>
<li>ADNAM  for script scaffold @ https://github.com/adnam/bash-scaffold</li>
</ul>
