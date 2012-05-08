---
layout: post
title: Kickstarting OpenNebula VM images
categories: 
 systems
---
IaaS cloud environments like OpenNebula allow users to launch VMs starting from a copy of a base image. Since a base image is used to launch several new VM instances it is important to know how the base image itself was created. This can be done by scripting an OS installation step. One of the most common methods to script a CentOS, RHEL or Fedora type distro installation is a [kickstart installation method](http://fedoraproject.org/wiki/Anaconda/Kickstart). There are other options, e.g. [cobbler](http://cobbler.github.com/), however I am not very familiar with those options yet. Following are my notes on creating CentOS 6 VM images for the OpenNebula IaaS cloud. Although these notes will highlight things specific to OpenNebula images, these instructions can be adapted for any other kickstart based VM installation on a KVM-libvirt platform as well. Required tools for the job are: KVM, libvirt, virt-tools, git and OpenNebula.


## Kickstart installation
Kickstart installation method allows system administrators to perform a scripted installation where answers to installation questions or configuration details are provided through a single file. A kickstart file is an installation script which can be used to install multiple systems in a predictable manner. The kickstart file is downloaded and then read by a boot image kernel to kickstart the installation process. The kickstart file can be can be read from a local disk and network location such as NFS, HTTP or FTP as well. Check out following links for more information on kickstart installation method and file's syntax:

 * http://fedoraproject.org/wiki/Anaconda/Kickstart
 * http://www.centos.org/docs/5/html/Installation_Guide-en-US/ch-kickstart2.html


### Main kickstart file
Following is an example kickstart script for creating a generic developer VM image. The kickstart file's syntax is quite self-explanatory however please refer to the [Anaconda Kickstart guide](http://fedoraproject.org/wiki/Anaconda/Kickstart) for additional options and detailed information guide.

{% gist 2628610 one-image-generic.ks %}


An important thing to note in the above kickstart file is that there is no swap disk or swap partition created in the base image. A swap space can be added as a separate disk during actual VM deployment through OpenNebula and hence it's not necessary to configure it in the base image. Also, OpenNebula supports VM's memory (RAM) size changes before deployment and hence in order to keep swap space and memory size in proportion it may help to keep the swap space outside of the base image.

The kickstart method provides an option to run post installation steps after the installation is complete. These post installation steps are added to the '%post' section of the kickstart. In our work environment we have divided post installation scripts into two categories: 

 * Scripts common to all nodes/systems: Configuration steps related to rsyslog, autofs and yum repository URLs
 * Scripts specific to a node/system: Configuration steps such as initial firewall configuration, sudoers file configuration etc. 
 
This post installation pattern with separate namespace for 'common' and 'node' specific scripts was developed by [Mike Hanby](https://github.com/flakrat). It's really useful pattern as it separates out tasks according to their functionality, reusability and execution sequence. Most of the system configuration is later managed by a configuration management tool like Puppet. However some of the basic or pre-Puppet configuration steps get into the post installation section.

Note, that above kickstart script will shutdown (halt) the VM after post-installation steps are completed. This is done intentionally as the base image doesn't need to run after installation process has completed. The base image can be registered in the OpenNebula image repository once the system is turned-off.

### Post install scripts
The above kickstart file shows various post-installation scripts that are run after the installation is complete. I have discussed below some of these scripts which are important from the OpenNebula's base image creation perspective:

#### clear-network-config.sh:
CentOS 6 uses udev rules to keep network interface configuration persistent after reboot and hence it doesn't bring up a network interface if it's MAC address had changed during the reboot process. When a VM is deployed from the base image it won't have the same MAC address as currently configured in the base image. So the udev rule for keeping network configuration persistent should be removed to bring up network interface successfully. Also, the network configuration used during base image creation can be removed as well. Below is an example script that demonstrates these steps.
  {% gist 2628610 clear-network-config.sh %}

#### rc-local-contextualization.sh:
The OpenNebua supports VM contextualization during VM's deployment process. This is typically done by modifying the rc.local script to mount contextualization disk and then run scripts available in it. The contextualization process can be performed in 2-3 different manners with each of them having certain advantages and disadvantages. I will be writing notes on it in a separate blog entry soon. Following is an example where the rc.local script is modified through a post-installation script to mount context ISO disk and then execute scripts available in it during next boot or VM deployment.
 
   {% gist 2628610 rc-local-contextualization.sh %}
   
#### firewall-config.sh:
It's good idea to have a firewall configuration in place even if we have removed network configuration from the base image. Also, we may have plans to configure VM's system firewall during deployment or through external configuration management tool after the deployment, still it's important to have a restricted firewall active in the base image in case any later deployment step fails or partially completes.
  

## Creating a VM using virt-install
We use KVM virtualization platform and libvirt based [virt-tools](http://virt-tools.org/index.html) to interact with it. You can use either [virt-manager](http://virt-manager.org/) or virt-install to start a VM installation process using libvirt/virt-tools. Both of these tools accept extra kernel arguments (-x option) where a kickstart installation method can be specified. Following is an example virt-install command to start VM installation: 

    $ virt-install --connect qemu:///system \
    -n $guestname \
    -r 1024 \
    --vcpus=1 \
    --os-type=linux \
    --os-variant=rhel6 \
    --accelerate \
    --graphics vnc,keymap=en-us \
    -v \
    -w bridge:br2 \
    --disk path=$datastore/$guestname.img,size=40 \
    -l $repo \
    -x "ks=$ksurl/$ksfile ksdevice=eth0 ip=$guestip netmask=$netmask nameserver=$nameserver1 gateway=$gateway"
	
where,

 * guestname: Name of the VM/guest
 * datastore: File system path to the directory or datastore where VM's disk image will be stored.
 * repo: Location/URL of network install tree
 * ksurl: URL of the directory holding kickstart files
 * ksfile: Name of the kickstart file

As mentioned earlier the example kickstart script shown here will shutdown the VM after installation process has completed. The base image ($datastore/$guestname.img) can be registered in the OpenNebula image repository after the system is turned-off. 

## OpenNebula image registration
A disk image can be registered in the OpenNebula image repository using either Sunstone web interface or [CLI](http://opennebula.org/documentation:rel3.4:cli). Following is an image template that can be registered using 'oneimage' command. Please refer to the [OpenNebula's image template guide](http://opennebula.org/documentation:rel3.4:img_template) for detailed information on how to create an image template.

	NAME = "generic-dev"
	PATH = "/lustre/vmimages/generic-dev.img"
	TYPE = "OS"
	PUBLIC = YES
	DESCRIPTION = "generic-dev image. Source: one-image-generic.ks, GirRev: rcs-repo@b860da0"
	IMGTYPE=rcs

Finally, the most important thing is to maintain our kickstart files and scripts in a version control system like Git and record this revision/commit metadata in the image template. This will help us in tracking and knowing the system profile of the base images and VMs deployed using them.
