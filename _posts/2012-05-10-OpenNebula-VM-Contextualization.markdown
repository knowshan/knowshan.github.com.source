---
layout: post
title: Notes on OpenNebula VM contextualization 
categories: 
 systems
---
The OpenNebula supports VM 'contextulization' during the VM's start-up process. Typically the contextualization step is used to perform following things:

 * Configure network
 * Configure or refresh services dependent on the network configuration, e.g. ntpd, rpcidmapd, xinetd etc.

The [OpenNebula documention](http://opennebula.org/documentation:rel3.4:cong) has explained this functonality in detail. Following is a high level overview of the steps involved in it for the purpose of this notes. 

* A user needs to define a CONTEXT section in the VM's template file containing configuration variables and scripts to be used during the VM's start-up process.
* The OpenNebula head-node (server) prepares an ISO disk based the CONTEXT section and adds it to the VM's deployment definition file (attaches cd device). All of the context section variables are added to a special file 'context.sh'. The context.sh file and other contextulization files mentioned in the 'FILES' variable are copied into the ISO disk. Refer to the  [OpenNebula documention](http://opennebula.org/documentation:rel3.4:cong) for VM template definition syntax.
* A user needs to prepare the base image used by the VM to mount contextulization ISO disk and run scripts available in it. This is typically done in the rc.local file. 

Following is an overview of steps involved in using contextulizing feature supported by OpenNebula.

## Defining context section
The OpenNebula's VM template follows simple bash-style 'name=value' syntax for defining variables. Below is an example VM template file with the CONTEXT section:
    
	NAME=generic-server-02
	OS=[
	  ARCH=x86_64,
	  BOOT=hd ]
	MEMORY=512
	...
	...
	...
	CONTEXT=[
	  FILES="/home/pavgi/myinit.sh /home/pavgi/network.sh",
	  GATEWAY=192.168.1.2,
	  NAMESERVER1=192.168.1.2,
	  NAMESERVER2=192.168.1.3,
	  netmask=255.255.0.0,
	  VMID=$VMID ]
    

As mentioned earlier all the variables specified in the context section are added the special file named 'context.sh' by OpenNebula. The 'FILES' variable is special as it defines file-system path to other scripts that need to be used for the VM contextualization. These scripts are copied into the context ISO disk by OpenNebula.

### Notes
* The OpenNebula uses 'mkisofs' command to create context disk and hence make sure that it is available on the front-end. Otherwise you will get an error during VM deployment.
* All the variable names are converted to camel case when a VM template is registered (in above example netmask will become NETMASK). This is important to note for writing contextualization scripts.

## Preparing the base VM image
The OpenNebula VM's base disk image needs to be configured to mount contextualization disk and run scripts within it. This is typically done in the rc.local script. Below is an example of rc.local script which mounts the cdrom device (context ISO disk), 'sources' context.sh to evaluate configuration variables and finally runs contextulization script(s) defined in the 'FILES' variable. 

{% gist 2628610 rc-local-contextualization.sh %}
	
The above script 'sources' context.sh script which contains all context variables defined in the CONTEXT section of the VM template. Then it executes 'myinit.sh' and 'network.sh' files which contain contextulization logic. Alternatively we can add the contextualization logic directly inside the rc.local script after sourcing the 'context.sh'. Following two sections describe pros-cons of both approaches. 

### Calling contextulization scripts through a single script
The previous rc.local example shows a pattern where contextulization script names are mentioned in the rc.local file. This places a dependency on the script names defined in the CONTEXT/files section. So if script names change or do not match with those defined in the base image, then the contextulization process will fail. This dependency can be avoided or minimized by specifying only one 'main' script name in the rc.local file which then calls other contextulization scripts. This approach allows modification of contextualization logic outside of the base image.

A disadvatage of this approach is that it will not help us in knowing exact commands that were executed during VM deployment. A deployed VM's system profile depends on following things:

 * Base disk image registered in the OpenNebula
 * Contextulization variables 
 * Contextulization scripts 
 
The first two things are well captured in the VM template file. However, the contextulization scripts are known only by their file-system paths or names. A file-system path or script name does not provide any information about contents of the script and hence VM's exact profile can't be determined based on it. This can be solved by tracking contextulization scripts using an external tool (e.g. git) and including it's tracking metadata (e.g. git commit sha1) in the VM template description. 

Also, note that CONTEXT/files section is restricted to administrator users only. So a VM template containing CONTEXT/files section can't be used by non-administrator users even if they have permissions/ACLs to launch the template (true as of OpenNebula 3.2).

### Putting contextulization logic inside the base VM image
The contextulization files are not mandatory, in fact, as mentioned earlier they can't be used non-administrator users. In such scenario contextulization steps can be defined direcly inside the rc.local script of the base image. An obvious disadvtanage of this approach is that any change in contextulization logic essentialy requires a new base image. On the other hand, it offers an advantage that exact VM profile can be determined based on the VM template and the base image.

{% gist 2628610 rc-local-contextualization-inside-image.sh %}

 
## Summary
I hope I have been able express my thoughts on OpenNebula's contextualization process clearly here. 
I think it will help if OpenNebula adds support for registration and tracking of contextualization scripts. The contextualization scripts contain common steps like network configuration, Puppet registration, which can be abstracted and re-used in many VM templates. Currently OpenNebula doesn't allow non-admnistrator users to use VM templates containing CONTEXT/files section out of security concerns. However, if OpenNebula administrators could curate and publish well-defined contextualization scripts then it would help non-administrator users to take advantage of it. And most importantly, it will keep entire VM profile self-contained in the OpenNebula.
