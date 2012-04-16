---
layout: post
title: Python development environment using virtualenv and pip
categories:
 programming
---

Following are my notes on creating a Python development environment in $HOME on CentOS 5.8 system. This should work on other CentOS versions and different distro types as well with few changes.

## Required tools
We will be using following tools to setup our Python development environments: 

* [environment modules](http://modules.sourceforge.net/): It is a useful tool for defining shell environment using a configuration file known as 'modulefile'. A modulefile can be used to load or unload defined shell environment using 'module' sub-commands. 
* [easy_install](http://packages.python.org/distribute/easy_install.html): It is a Python module to build, install and manage Python packages.
* [pip](http://pypi.python.org/pypi/pip): It is a tool for installaing Python packages and is mentioned as a replacement for [easy_install](http://packages.python.org/distribute/easy_install.html). We will be using easy_install to install virtualenv (and pip) and then later use pip to install and manage Python packages in my $HOME.
* [virtualenv](http://pypi.python.org/pypi/virtualenv): It is a nice tool for creating isolated Python virtual environments. A Python virtual environment created using virtualenv comes with  a [pip](http://pypi.python.org/pypi/pip) configured for that particular environment. This ensures that packages get installed in a self-contained location within that environment.
* [virtualenvwrapper](http://www.doughellmann.com/projects/virtualenvwrapper): This tool provides extensions to [virtualenv](http://pypi.python.org/pypi/virtualenv) tool to manage Python virtual environments. I haven't used it in my setup however it seems good to try it out.


## Tool installation and configuration (one-time step)

### environment modules
The [environment modules](http://modules.sourceforge.net/) can be installed through a OS distro's package manager.  It should be able possible to install it our $HOME however a core tool like this will be useful for many other use cases. So it is better to install it in a system wide location using the distro's package manager. It is available through [EPEL](http://fedoraproject.org/wiki/EPEL) repository for CentOS.

### virtualenv 
As mentioned eralier we will be using the 'easy_install' tool to install virtualenv tool in $HOME. By default the easy_install tool will try to install packages in a system wide location -  '/usr/lib/python2.4/site-packages/' on CentOS 5.8. This will require sudo privileges which we may not have on every system. Also, it falls outside of $HOME directory (!) so we won't be installing any packages out there.

The 'easy_install' tool provides various options to customize package installation. We can view them using 'easy_install --help'  command. An option we are most inetersted in is 'prefix'. It will allow us to install Python packages in a custom directory location.
I will be installing Python packages in '$HOME/python-packages' directory however feel free to change this according to your conventions. Before we try the easy_install command we need to create a directory structure specific to current Python interpretor version.  On my system the default Python version is 2.4 and hence the directory structure will be as follows:
    
	# mkdir -p $HOME/python-packages/lib/python<major-version>/site-packages
    $ mkdir -p $HOME/python-packages/lib/python2.4/site-packages
    $ mkdir -p $HOME/python-packages/bin


Once the necessary directory structure is in place we can proceed with the virtualenv installation as follows: 

    $ easy_install --prefix ~/python-packages virtualenv

    Creating /home/pavgi/python-packages/lib/python2.4/site-packages/site.py
    Searching for virtualenv
    Reading http://cheeseshop.python.org/pypi/virtualenv/
    Reading http://www.virtualenv.org
    Reading http://cheeseshop.python.org/pypi/virtualenv/1.7.1.2
    Best match: virtualenv 1.7.1.2
    Downloading http://pypi.python.org/packages/source/v/virtualenv/virtualenv-1.7.1.2.tar.gz#md5=3be8a014c27340f48b56465f9109d9fa
    Processing virtualenv-1.7.1.2.tar.gz
    Running virtualenv-1.7.1.2/setup.py -q bdist_egg --dist-dir /tmp/easy_install-z85WcV/virtualenv-1.7.1.2/egg-dist-tmp-CPJ4M-
    warning: no previously-included files matching '*.*' found under directory 'docs/_templates'
    Adding virtualenv 1.7.1.2 to easy-install.pth file
    Installing virtualenv script to /home/pavgi/python-packages/bin
    Installed /home/pavgi/python-packages/lib/python2.4/site-packages/virtualenv-1.7.1.2-py2.4.egg
    Processing dependencies for virtualenv


Now as the virtualenv package is installed in a non-standard location it's binary files won't be available in $PATH by default. Also we will need to set PYTHONPATH variable so that Python interpretor can find the required virtualenv Python libraries. We can set these variables in .bashrc file however I will be using [environment modules](http://modules.sourceforge.net/) to modify shell environment. By default the module command can load modulefiles in '$HOME/.modulefiles' directory and hence I will be placing modulefiles in the same directory:  

    $ cat /home/pavgi/.modulefiles/venv 
    #%Module
    # virtualenv module file
    set home $::env(HOME)
    prepend-path PATH $home/python-packages/bin
    prepend-path PYTHONPATH $home/python-packages/lib/python2.4/site-packages

Now we can load this module file using 'module load' command. 

    $ module load venv

Look up [environment modules](http://modules.sourceforge.net/) documentation to get more information on creating modulefiles. If you don't want to use it then you can set the necesaary values in .bashrc as well:

    export PATH="$HOME/python-packages/bin:$PATH"
    export PYTHONPATH="$HOME/python-packages/lib/python2.4/site-packages"


## Create project environments using virtualenv and pip

### Create a new Python virtual environment
Now we are ready to create a Python virtual environment using virtualenv. First let's make sure that we are using the default system Python version with which virtualenv was installed. Otherwise we will get Python library related errors when virtualenv will try to use some of the core Python libaries/modules. 

    $ python -V
    Python 2.4.3


Next we will need to load the venv module to get virtualenv command in the current shell environment. If you are not using [environment modules](http://modules.sourceforge.net/) then make sure to use appropriate export commands to set your shell environment. 

    $ module load venv 

Now we will run virtualenv command to create a new Python virtual environment. Following example shows virtualenv myproject being created in current working directory.  

    $ virtualenv -p /Library/python/2.7/bin/python myproject
    Running virtualenv with interpreter /Library/python/2.7/bin/python
    New python executable in myproject/bin/python
    Installing setuptools............................done.
    Installing pip...............done.


Note, that in above example we didn't use the default system Python version for our new project environment. We can change our Python interpreter to a different version like 2.6, 2.7, 3.0 etc. as long as it is installed on the system.

Check 'virtualenv --help' for a complete list of options possible virtualenv command. In particular check out '--no-site-packages' option as it will be necessary while creating virtual project environments for some of the Python frameworks out there (usually mentioned in framework installation notes).


### Examine directory structure (optional)

Run find command in the virtual project environment to get familiar with the pristine environment. It will help us understand the structure of installed packages, lib and bin directories. 

    $ cd myproject
    $ find ./

### Activate and use virtualenv project

The virtual project environment will need to be activated before it's usage. This can be done using 'activate' command in the project's bin directory as follows: 

    $ cd myproject/
    $ . ./bin/activate

### Create a module file your project 
The virtualenv command modifies Python package install path however it doesn't modify PYTHONPATH shell environment variable. The PYTHONPATH environment variable determines where Python libraries or packages will be searched during program's 'import' process. You will need to modify PYTHONPATH to make sure your program(s) finds the necessary libraries or packages installed using pip.  This can be done using regular shell export commands or environment modules. I will be creating a modulefile for the 'myproject' Python virtual environment as follows:

    $ cat ~/.modulefules/myproject
    #%Module
    # virtualenv module file
    set home $::env(HOME)
    prepend-path PATH $home/python-projects/myproject/bin
    prepend-path PYTHONPATH $home/python-projects/myproject/lib/python2.7/site-packages


### Package or Library installation
Once a virtual environment is activated we will be able to install Python packages only for that particular environment. For example consider following gitfs package installation:

    $ pip install gitfs
    Downloading/unpacking gitfs
    Downloading gitfs-0.2.tar.gz
    Running setup.py egg_info for package gitfs
    Downloading/unpacking filesystem (from gitfs)
    Downloading filesystem-0.2.tar.gz
    Running setup.py egg_info for package filesystem
    Installing collected packages: gitfs, filesystem
    Running setup.py install for gitfs
    Running setup.py install for filesystem    
    Successfully installed gitfs filesystem
    Cleaning up...
    
    
    $ find . -name gitfs
    ./lib/python2.7/site-packages/gitfs

The gitfs package was installed in the 'myproject' virtual environment specific site-packages directory. So it won't be available outside of this project and will not interfer with rest of the Python packages (assuming we won't monkey with PATH and PYTHONPATH). 

---

I hope I have captured most of the basic details on how to use virtualenv, pip and environment module to created isolated development environments. Following are links to few more related articles: 

 * [Using pip and virtualenv with Django](http://www.saltycrane.com/blog/2009/05/notes-using-pip-and-virtualenv-django): Covers pip requirements file and virtualenv options
 * [Tools of the Modern Python Hacker: Virtualenv, Fabric and Pip](http://www.clemesha.org/blog/modern-python-hacker-tools-virtualenv-fabric-pip): Provides detailed overview of each tool and contains useful links to other sites
 
I don't think there is any 'one size fits all' type solution here. It will vary according to your development system and system  privileges given to you. You may need to experiement with few options and then come up with your own recipe. 