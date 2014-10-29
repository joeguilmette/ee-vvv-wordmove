#How to run the optimal WordPress local, staging and production stack
Using VVV for local development and EasyEngine (Nginx, HHVM and Percona) in staging and production.

##VVV and OSX
Use VVV and auto-site-setup to create a new WordPress installation (**TO DO**)

##EasyEngine and Ubuntu 14.04 on DigitalOcean
- Create a 14.04 Droplet
	- I use two one for staging, another for production. My clients are US based, but I am based in Asia. The US regions have high lag times and I deal more with my staging than production server.
- Follow the [initai server setup guide](https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-14-04)
- [Configure ufw](https://www.digitalocean.com/community/tutorials/how-to-setup-a-firewall-with-ufw-on-an-ubuntu-and-debian-cloud-server)
- [Configure fail2ban](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-fail2ban-on-ubuntu-14-04)

- Use Wordmove to push from VVV to staging/production (**TO DO**)

###Nginx

####Enabling a swap file

- create the swapfile `$ fallocate -l 1024M /swapfile`

- set those perms `$ sudo chmod 600 /swapfile && mkswap /swapfile`

- start the swap `$ swapon /swapfile`

- make sure it gets mounted on startup by adding `/swapfile none swap defaults 0 0` on a new line in `$ sudo vim /etc/fstab`

###Migrating WordPress
####Telling WP the new site url via wp-cli
- `$ wp option update home 'http://example.com'`

- `$ wp option update siteurl 'http://example.com'`

####Importing a remote database
- dump the remote db  `$ mysqldump -u [username] -p [remote_db_name] > [remote_dump.sql]`
- get the remote db `$ scp [remote_dump.sql] #sshuser@#host:/path/`
- import the remote db `$ mysql -u [username] -p [local_db_name] < [remote_dump.sql]`

###Hardening WordPress

####Move wp-config.php back a dir out of the site root
- ee does this automagically

####Change db prefix
- Easily done via vvv-auto-site-setup
- Manually specific in wp-config.php

####Change wp-content folder
- add the following to the top of wp-config.php

```
define( 'WP_CONTENT_URL', 'http://domain.com/contentpath' ); 
define( 'WP_CONTENT_DIR', '/var/www/domain.com/wordpress/contentpath' );
```

####Permissions garbage
- Shit fucked?
- `$ find /path/to/your/wordpress/install/ -type d -exec chmod 755 {} \;` to 755 all folders
- `$ find /path/to/your/wordpress/install/ -type f -exec chmod 644 {} \;` to 644 all files.

####Configure ufw, fail2ban and rkhunter
- Make sure Nginx, mosh, ssh, ftp and postfix are enabled in `$ sudo vim /etc/fail2ban/jail.local` and `$ sudo ufw status`
- [Configure RKHunter once everything is up and running](https://www.digitalocean.com/community/tutorials/how-to-use-rkhunter-to-guard-against-rootkits-on-an-ubuntu-vps
)