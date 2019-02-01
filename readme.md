# Vagrant for RKW projects
## Requirements

- Virtualbox, Version >= 5
- Vagrant, Version >=2

## Before you start
If you use NFS, Vagrant maps the user of the guest (`vagrant` with the UID 1000) to the same UID of the host. 
In most cases this works fine. But if you have more than one user on the host it may happen that the UIDs do not match. 
This causes problems with read and write permissions. 



Let's assume the UID 1000 is still free on your host (if not, you have to set the UID in step 2 accordingly!)

1.) Create the new user on host 
```
useradd -u 1000 vagrant
```

2.) Then we uncomment the following lines to the Vagrantfile, so that NFS is mapped to the UID 1000 
(and so that the vHost user also grabs the vagrant-user) 
```
config.nfs.map_uid = 1000
config.nfs.map_gid = 1000
```
 
3.) Now we set the www-folder in this repository on the host to the matching user 
```
sudo -i
chown -R vagrant:vagrant www
```

4.) Now restart the vHost 







- Before provising your vagrant VM, make sure `/www` is owned by your local vagrant user
```

```

1. Create a folder for the project, e.g. /var/projects/rkw-kompetenzzentrum.de
2. Copy "www" and "vagrant" from this ZIP-file into it, so that you get the following folder structure - DO NOT RENAME ANYTHING INCLUDED IN THIS ZIP-FILE!
  /var/projects/
  --> rkw-kompetenzzentrum.de
  ----> vagrant
  ----> www
3. Make sure the folder vagrant/ssh contains the required RSA-Keys 
4. Make sure the folder vagrant contains der Vagrantfile
5. Do "cd vagrant" in vagrant
6. Enter "vagrant up" - NOTE: Per default NFS for shared folders is used (see vagrantfile). This requires administration privileges (see: https://www.vagrantup.com/docs/synced-folders/nfs.html), so stay tuned until Vagrant asks for your password!
7. Go get some coffee when the provisioning-script starts - it may take some time to download everything at the first time
8. Use the etc-host.txt and copy it into your /etc/hosts to let your host know which domains should be looked up against your VM. Don’t forget to change the IP to the one used by your VM.  

Notes
========
- If you are using an local vagrant-box, download it and add it with: "vagrant box add INTERNAL-NAME-OF-BOX PATH/FILE"
- If you are using an internal proxy you need to exit the provising-script at the begining and setup the proxy in your VM. You can do this by editing /etc/environment.
Please note that you need both, lower- and uppercase versions of the variables. Then do "vagrant up --provision".
	http_proxy="http://myproxy.server.com:8080/"
	https_proxy="http://myproxy.server.com:8080/"
	ftp_proxy="http://myproxy.server.com:8080/"
	HTTP_PROXY="http://myproxy.server.com:8080/"
	HTTPS_PROXY="http://myproxy.server.com:8080/"
	FTP_PROXY="http://myproxy.server.com:8080/"

- You can use the etc-host.txt and copy it into your /etc/hosts to let your host know which domains should be looked up against your VM. Don’t forget to change the IP to the one used by your VM. 
- You can find out which IP your VM is using by calling 'netstat -rn' on your host and locking for the IP in 'vboxnet' after your VM has booted.
- If you are using an internal proxy you need to exclude the IP of you guest maschine from the lookup via proxy in your browser  
  