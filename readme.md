#How to run the optimal WordPress local, staging and production stack
Using VVV for local development and EasyEngine (Nginx, HHVM and Percona) in staging and production.

#VVV and OSX
Use VVV and auto-site-setup to create a new WordPress installation (**TO DO**)

- Use [HHVVVM](https://github.com/johnjamesjacoby/hhvvvm) with VVV for HHVM support
- Use [auto-site-setup](https://github.com/joeguilmette/auto-site-setup) to create new local WordPress installs and to provision your Vagrant box with Wordmove and other useful tools not included in VVV
	- Create a folder `vvv/www/domain.com/` and add the three files, `vvv-hosts`, `vvv-init.sh` and `vvv-nginx.conf`.
	- Modify each of them to fit your project.
		- Be careful with `vvv-init.sh` and make sure you read it over and edit all the little details. The good news is you can use wp-cli in there to do whatever the fuck you want. You can even do some fun bash stuff, like clone in a theme, or whatever.
		- In `vvv-nginx.conf` I've defaulted to use HHVM. You can comment that line out and switch to php5-fpm if you like.
	- If vagrant is up, run `$ vagrant reload --provision`, or just `$ vagrant up --provision` and let it run and it'll create all the sites you've configured.
	- It takes 5-10 mins, longer if it's your first time running the script. It'll have to download a few gigs of files.
	- Once it's up, you can go to whatever domain you've set in the auto-site-setup files and get going.
	- **Congrats on getting your local environment going.**


#Setting up and securing Ubuntu 14.04 on DigitalOcean with EasyEngine
- Create a 14.04 Droplet
	- I use two one for staging, another for production. My clients are US based, but I am based in Asia. The US regions have high lag times and I deal more with my staging than production server.
- Follow the [initai server setup guide](https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-14-04).
- [Configure ufw](https://www.digitalocean.com/community/tutorials/how-to-setup-a-firewall-with-ufw-on-an-ubuntu-and-debian-cloud-server).
- [Configure fail2ban](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-fail2ban-on-ubuntu-14-04).
- Install EasyEngine `$ wget -qO ee rt.cx/ee && sudo bash ee` and maybe even [RTFM](https://github.com/rtCamp/easyengine).


#Using EasyEngine in staging/production
- Create a new site with `$ sudo ee site create domain.com --wpfc`
- Configure DNS
	- One A record to link domain.com to your server: `A @ 1.1.1.1`
	- One wildcard CNAME for magical reasons I don't understand: `CNAME * domain.com`
	- One CNAME per subdomain: `CNAME subdomain domain.com` will link subdomain.domain.com to the server IP listed in your A record.


#Migrating WordPress from one of your local Varying Vagrant Vagrants to your remote Digital Ocean server
Wordmove is the easiest way to automate this process.

##Using Wordmove
So this is kind of a pain with EasyEngine because it locks down /var/www pretty well. Nginx is run with the user www-data which can't do much. It does not have a shell, and in fact it should not have one. But in order to use Wordmove, the easiest way is to just give it one.

My solution is to open up www-data, use Wordmove, and then lock down www-data and everything in /var/www.

###Installing Wordmove
My [auto-site-setup](https://github.com/joeguilmette/auto-site-setup) fork has a `pre-provision.sh` file. If you dump it into `vvv/provision` it'll get installed next time you provision vvv.

###Configuring www-data to be Wordmove compatible
- Add an alias to give www-data a shell with `$ alias openitup='sudo usermod -s /bin/bash www-data'`. Now by running `$ openitup`, www-data has shell access. Run this now.
- Give www-data a password with `$ sudo passwd www-data`
- Create some ssh keys for www-data with `$ su - www-data ssh-keygen -t rsa -C "your_email@example.com"`. This is a huge pain in the ass, but it's just permissions. In the end, you should have `/var/www/.ssh` with three files, `authorized_keys`, `id_rsa` and `id_rsa.pub`. Permissions for these files after creation is important, but [my lockdown script](https://github.com/joeguilmette/lockdown) will take care of it.
- Next, run `$ vagrant ssh` from your vvv folder. This will ssh you into the vvv vm you've set up.
- Create some ssh keys in your vagrant box with `$ ssh-keygen -t rsa -C "your_email@example.com"`
- Now you need to send your ssh key from Vagrant to the remote www-data user via `$ cat ~/.ssh/id_rsa.pub | ssh www-data@1.1.1.1 'cat >> .ssh/authorized_keys'`.
- At this point your vagrant box should be able to ssh into www-data@1.1.1.1 without being asked for a password. Give it a shot by running `$ ssh www-data@1.1.1.1` and see if it lets you in without prompting you for a password. If it asks your for a password, exercise that google muscle.


###Configuring Wordmove
- Run `$ wordmove init` in your local WordPress root
- `$ vim Movefile` and edit the local and remote sections appropriately.
- **For SSH, make sure to set user to www-data and keep the password line commented out.**
- Make sure the local absolute path matches the OS that Wordmove is being run from, i.e.:
	- `/var/www/domain.com/wp-core` in Vagrant (locally, I run from here rather than OS X)
	- `~/vvv/www/domain.com/wp-core` in OSX
	- `/srv/www/domain.com/wordpress` in EasyEngine (if you're migrating from staging to production)

###Actually using Wordmove
This assumes that www-data has shell access, your local Movefile is properly configured, you've sent your ssh keys from your local machine to your server at www-data@1.1.1.1 and that the local Wordpress install you're using works.

- Run `$ openitup` on your server to give www-data shell access
- Navigate to the local folder that has your Movefile
- Run `$ wordmove push --all -e=server`. Change `-e=server` to whatever server you've set in your Movefile.
	- If you're getting password prompts from Wordmove while things are pushing **then you need to send your sshkey to your server via `$ cat ~/.ssh/id_rsa.pub | ssh www-data@1.1.1.1 'cat >> .ssh/authorized_keys'`**. If that isn't working, then something is wrong with `/var/www/.ssh/authorized_keys` on your server. Fix it. Otherwise you won't be able to push/pull the db.
- Verify that everything worked
- After Wordmove is done, use [my lockdown script](https://github.com/joeguilmette/lockdown) to close everything up.
 
###Troubleshooting a borked migration

- If you see no changes: 
	- The old site is probably cached, try `$ sudo ee clean all`
	- Maybe you set the wrong root folder. Did you set your Movefile to dump everything in `/var/www/domain.com` instead of `/var/www/domain.com/htdocs`? Dummy. I get to say so because I bork that every. single. time.
	- Maybe the database didn't migrate.
	- Maybe you're using the wrong table prefix. Check wp-config.php
	- Maybe WordPress is looking for a wp-content folder and you moved it
- White screen of death?
	- Could be a database issue.
	- Could also be a table prefix issue.
	- Is wp-content set right?
	- Maybe WordPress doesn't know you changed the domain? See below.
	- Are your DNS settings are properly configured
	- Using HHVM? Maybe it's shitting itself. **Check the HHVM error logs.** HHVM doesn't give you in-browser errors.
		- Not sure if you're using HHVM or not? `$ curl -I domain.com`
	- Maybe Nginx is shitting itself, although if it is, Nginx will give you error message in the browser. But make sure it's happy with your config settings with `$ sudo nginx -t`. Maybe even restart it with `$ sudo service nginx restart`

-Still can't figure it out?
	- Maybe you PEBKAC'd something simple, dummy

##Telling WP the new site url via wp-cli
Sometimes WordPress freaks out when you move it. It stops freaking out after you tell it everything is ok. Only try this stuff if things are broken and you've tried everything else.

```
$ wp option update home 'http://domain.com'
$ wp option update siteurl 'http://domain.com'
```

Or add the following to wp-config.php. I don't like this method as much.

```
define('WP_HOME','http://domain.com');
define('WP_SITEURL','http://domain.com');
```

##Importing a remote database manually
Sometimes you gotta do it...

- Dump the remote db  `$ mysqldump -u username -p remote_db_name > remote_dump.sql`
- Get the remote db `$ scp remote_dump.sql sshuser@host:/path/`
- Import the remote db `$ mysql -u username -p local_db_name < remote_dump.sql`

#Hardening WordPress

##Move wp-config.php back a dir out of the site root
- EasyEngine does this automagically (sorry Adam)...

##Change db prefix
- Easily done via vvv-auto-site-setup and wp-cli during site creation
- Manually specified in wp-config.php

##Change wp-content folder
- Add the following to the top of wp-config.php

```
 define( 'WP_CONTENT_DIR', dirname(__FILE__) . '/wp-content' ); // sometimes this doesn't work
 define( 'WP_CONTENT_DIR', '/var/www/domain.com/htdocs/wp-content'); // and I have to use this
 define( 'WP_CONTENT_URL', 'http://domain.com/wp-content' );
```

##Permissions
The lockdown script should prevent these issues, but just in case... Make sure that all folders in `www/` are set to 755, and all files are set to 644.

`$ find /path/to/www/ -type d -exec chmod 755 {} \;` to 755 all folders

`$ find /path/to/www/ -type f -exec chmod 644 {} \;` to 644 all files.

##Configure ufw, fail2ban and rkhunter
These are important in securing any publicly facing server.

- In `/etc/passwd`, make sure www-data has `/usr/sbin/nologin`, preventing shell access.
- Make sure Nginx, mosh, ssh, ftp and postfix are enabled in `$ sudo vim /etc/fail2ban/jail.local` and `$ sudo ufw status`, and that ufw is in fact enabled along with fail2ban.
- [Configure RKHunter once everything is up and running](https://www.digitalocean.com/community/tutorials/how-to-use-rkhunter-to-guard-against-rootkits-on-an-ubuntu-vps
).

#Optimizing WordPress
There are [some cool resources](https://github.com/davidsonfellipe/awesome-wpo) for getting optimization in Wordpress right. EasyEngine is a great start. If you create sites with the `--wpfc` flag you'll get fast-cgi caching out of the box. And EasyEngine offers some other nifty caching tools to get things going.

Caching aside, you're going to have to execute some PHP eventually. HHVM is crazy good for doing that fast.

##Installing HHVM alongside EasyEngine

- Install HHVM (**TO DO**)
	- [This guide is pretty solid](https://rtcamp.com/tutorials/php/hhvm-with-fpm-fallback/).
	- Throws an error on `$ sudo /usr/share/hhvm/install_fastcgi.sh`
	- Need to create a symlink for hhvm.conf in /etc/nginx/conf.d and run `$ sudo nginx -t` to make sure the confs work
	- [This was useful](https://github.com/rtCamp/easyengine/issues/199).

##Enabling a swap file
EasyEngine should handle this for you. If you run into memory issues later, this is a good way out aside from just buying more RAM.

- Create the swapfile `$ fallocate -l 1024M /swapfile`.

- Set those perms `$ sudo chmod 600 /swapfile && mkswap /swapfile`.

- Start the swap `$ swapon /swapfile`.

- Make sure it gets mounted on startup by adding `/swapfile none swap defaults 0 0` on a new line in `$ sudo vim /etc/fstab`