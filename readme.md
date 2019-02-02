# Vagrant for RKW projects
## Requirements

- Virtualbox, Version >= 5
- Vagrant, Version >=2

## Note
This readme-file assumes that you use a proper operating system as host, like Mac OS or Linux.

If you intend to use Windows as operating system for your host, you are totally on your own.
Windows is not a proper operating system for web-development. **Use Windows at your own risk.**

## About the folders

### Folder `vagrant`
This folder contains the Vagrantfile and a configuration-folder which is used to setup the Vagrant-VM on provisioning.

### Folder `www`
This is the folder where you put your projects. It is used as mountpoint for Vagrant and thus can be reached via your host machine. 
The content of this folder (except for `www/default` and `www/hmtl`) is NOT versioned.


## Before you start

### Using a proxy

During provisioning software will be installed using `apt-get`. 
So if you are using an internal proxy, please start the Vagrant-VM **WITHOUT** provision-flag first and configure your connection via proxy by editing the `/etc/environment` in the Vagrant-VM.
```
host$ cd vagrant
host$ vagrant up
host$ vagrant ssh
vm$ sudo nano /etc/environment
```
Here you insert the following (replace your proxy-settings accordingly):
```
http_proxy="http://[YOUR-PROXY]:[YOUR-PORT]/"
https_proxy="http://[YOUR-PROXY]:[YOUR-PORT]/"
ftp_proxy="http://[YOUR-PROXY]:[YOUR-PORT]/"
HTTP_PROXY="http://[YOUR-PROXY]:[YOUR-PORT]/"
HTTPS_PROXY="http://[YOUR-PROXY]:[YOUR-PORT]/"
FTP_PROXY="http://[YOUR-PROXY]:[YOUR-PORT]/"
```
Then halt the Vagrant VM... 
```
vm$ exit
vm$ exit
host$ vagrant halt
```
...and start it again with provision-flag (see below).

### NFS
For performance reasons this Vagrantfile uses NFS for mounting your working directory.

On mounting Vagrant maps the user and group of the guest (default for user and group: `vagrant` with UID 1000) to the same UIDs on the host. 
In most cases this works fine. But if you have more than one user on the host it may happen that the UIDs do not match. 
This causes problems with read and write permissions. 

You can check your user's UIDs with this commands:
```
host$ id -u <USER_NAME>
host$ id -u <GROUP_NAME>
```

Let's assume your host-user has the UID 501 and it's group has the UID 20.
Then you have to set this values in the following lines to the Vagrantfile:
```
config.nfs.map_uid = 501
config.nfs.map_gid = 20
```
 
Now we set the www-folder on the host to this user and group (if not already set)
```
host$ sudo chown -R my-user:my-group www
```

This way the permissions should be set correctly.

**Please see also the troubleshooting section below for further help**

## Provisioning and initial setup
You can do the provisioning of this Vagrant-VM by
```
host$ cd vagrant
host$ vagrant up --provision
```

Provisioning will install (and update the configuration of):
* Apache 2
* PHP (as PHP-FPM with versions 5.6, 7.0 and 7.2)
* MySQL
* PHPMyAdmin
* Varnish-Cache
* Postfix
* Mailcatcher


## Passwords
* Root-password for Mysql on the VM is set to `rkw`

## Getting started with projects

### Introduction
Place your own projects in `www/[YOUR_PROJECT]`. 

Do this e.g. by cloning your project GIT into your project-folder.

The folder `www` is used as a mountpoint for Vagrant and thus can be reached via your host machine.
This way you can work on your project with your favorite editors and programms on your host machine, while the Vagrant VM brings a fully configured webserver to you for development and testing.  

The content of the folder `www` is NOT versioned (except for `www/default` and `www/hmtl`, which are defaults that shouldn't be touched by you) .

### Step-by-step
#### Step 1
Place your own project in `www/[YOUR-PROJECT]`. 
```
host$ cd www
host$ mkdir my-project
host$ cd my-project
host$ git init
...
```
#### Step 2
Now you have to tell Apache
a) were the DocumentRoot of your project is and
b) which PHP Version you want to use.

Login into you Vagrant VM and add a new vHost configuration for your project by copying the defaults-file.
```
host$ cd vagrant
host$ vagrant ssh
vm$ sudo -i
vm$ cd /etc/apache2/sites-available
vm$ cp 000-default.conf my-project.conf
```

Then we edit the new file with
```
vm$ nano my-project.conf
```

Let's take a closer look at the configuration:
```
<VirtualHost *:8080>

    ServerAdmin webmaster@vagrant.local
    # ServerName example.com
    # ServerAlias www.example.com

    # Set basic configuration
    Use vHostPhpFcgi 5.6 default

    # Add PhpMyAdmin
    Use vHostExtPhpmyadminFcgi 

</VirtualHost>
```
* The first line `<VirtualHost *:8080>` sets the port. We use 8080 here, because we have a varnish installed. Nothing to do here
* `ServerAdmin webmaster@vagrant.local` is an obligatory line. You can leave it as it is.
* The next two lines are commented out in the default file, because the default file is meant to be a fallback. **For your own projects you have to define at least a `ServerName`**, so that Apache knows which configuration should be used for which domain. **IMPORTANT: If you want to use this Vagrant VM for an existing RKW project use the domain that is configured in your project's repository. Take a look into your project's `dev/etc-hosts` file to find out which domain to use!**
* `ServerAlias` is optional and contains further domains that are to be handled by this configuration. You can use as many ServerAlias entries as you like, one for each domain. You can also use wildcards, e.g. `*.example.com` to indicate that this configuration is to be used for all subdomains of example.com. **IMPORTANT: If you want to use this Vagrant VM for an existing RKW project use the domains that are configured in your project's repository. Take a look into your project's `dev/etc-hosts` file to find out which domains to use!**
* **Now there comes the important stuff:** `Use vHostPhpFcgi 5.6 default`. Here `vHostPhpFcgi` refers to the configuration macro in `/etc/apache/conf-available` that is to be used - dont't mind, just keep it as it is :-) The second param defines the PHP-Version you want to use. Valid values are: `5.6, 7.0, 7.2`. The third param defines the path to the public DocumentRoot of your project, relative to `www`, e.g. `my-project/web`.  
* vHostExtPhpmyadminFcgi simple activates PHPMyadmin for your project - just leave it as it is.

Taken this together a configuration for you project could look like this:
```
<VirtualHost *:8080>

    ServerAdmin webmaster@vagrant.local
    ServerName my-project.local
    ServerAlias www.my-project.local
    ServerAlias www.landingpage-for-my-project.local

    # Set basic configuration - using PHP 7.2 and using (www/)my-project/web as DocumentRoot
    Use vHostPhpFcgi 7.2 my-project/web

    # Add PhpMyAdmin
    Use vHostExtPhpmyadminFcgi 

</VirtualHost>
```

#### Step 3

Now we have to activate the new configuration and reload apache 
```
vm$ a2ensite my-project
vm$ service apache2 restart
```

#### Step 4
Use the `etc/hosts` on your host to route your project's local domains from your host to the IP of your Vagrant VM.
ou can find out which IP your VM is using by calling 
```
host$ netstat -rn
```
on your host and locking for the IP in `vboxnet`.

```
host$ sudo nano /etc/host
```

Set the IPs accordingly in your etc/hosts

```
172.28.128.3	your-project.local
172.28.128.3	www.your-project.local
172.28.128.3	www.landingpage-for-my-project.local
``` 

#### Step 5
Your are ready :-)

* Go to `http://your-project.local` to reach your project's DocumentRoot via Apache
* Go to `http://your-project.local/phpmadmin` to call PhpMyAdmin in your project
* Go to `http://your-project.local:1080` to look into all e-mails that have been sent by your VM"


 # Troubleshooting (to be continued)
 ## NFS 

 ### On Mac
 Sometimes the NFS-directories simply don't mount.
 If you do a
 ```
 host$ vagrant up --debug
```
 you probably get the following messages:
 ```
 DEBUG ssh: stderr: ttyname failed
 DEBUG ssh: stderr: Inappropriate ioctl for device
 ```
 
 This may be the case because of wrong entries in `/etc/export` on your host, especially when you use more than one VM on your host.
 Just move the `/etc/export` to `/etc/export.bak` and start your VM again. 
 
 Also make sure you have the following entries in your host's `/etc/host`:
 ```
 127.0.0.1	localhost
 255.255.255.255	broadcasthost
 ::1 localhost
 fe80::1%lo0	localhost
  ```
See also: https://github.com/hashicorp/vagrant/issues/7646
   

### If nothing helps at all
You will find an alternative but not recommended way for mounting your working directory without NFS commented out in this Vagrantfile.
```
config.vm.synced_folder "../www", "/var/www", mount_options: ["dmode=777", "fmode=776"]
```

Other users recommend SSHFS as solution. **Be careful: we can offer no experience with this solution:** https://github.com/dustymabe/vagrant-sshfs
