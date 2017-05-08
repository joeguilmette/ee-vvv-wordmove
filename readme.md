# VVV, EasyEngine, and Wordmove: A WordPress development stack
A step by step guide to:

- Configure a local development environment with easy to set up WordPress installations. 
- Quickly provision staging and production servers, complete with one-line WordPress installation and configuration.
- Push and pull WordPress installations, database and all, between local, staging and production environments.
- Optimize and harden WordPress with very little configuration.

# Table of Contents

- [Local development with VVV and OSX](#local-development-with-vvv-and-osx)
- [Staging and production servers with Ubuntu and EasyEngine](#staging-and-productions-servers-with-ubuntu-and-easyengine)
    - [Setting up and securing Ubuntu 14.04x64 on DigitalOcean](#setting-up-and-securing-ubuntu-1404x64-on-digitalocean)
        - [Conifiguring Monit](#conifiguring-monit)
- [EasyEngine Monit settings](#easyengine-monit-settings)
    - [DigitalOcean Snapshots](#digitalocean-snapshots)
        - [Create Snapshot](#create-snapshot)
        - [Deploy a Snapshot](#deploy-a-snapshot)
    - [Installing and configuring EasyEngine](#installing-and-configuring-easyengine)
    - [Creating new WordPress installations in production](#creating-new-wordpress-installations-in-production)
- [Migrating WordPress from one of your local Varying Vagrant Vagrants to your remote Digital Ocean server](#migrating-wordpress-from-one-of-your-local-varying-vagrant-vagrants-to-your-remote-digital-ocean-server)
    - [Installing Wordmove](#installing-wordmove)
    - [Configuring Wordmove](#configuring-wordmove)
    - [This part is really important](#this-part-is-really-important)
    - [Actually using Wordmove](#actually-using-wordmove)
- [Troubleshooting a borked migration](#troubleshooting-a-borked-migration)
    - [Telling WP the new site url via wp-cli](#telling-wp-the-new-site-url-via-wp-cli)
    - [Importing a remote database manually](#importing-a-remote-database-manually)
- [Hardening WordPress](#hardening-wordpress)
    - [Move wp-config.php back a dir out of the site root](#move-wp-configphp-back-a-dir-out-of-the-site-root)
    - [Change db prefix](#change-db-prefix)
    - [Change wp-content folder](#change-wp-content-folder)
    - [Permissions](#permissions)
    - [Configure ufw, fail2ban and rkhunter](#configure-ufw-fail2ban-and-rkhunter)
- [Optimizing WordPress](#optimizing-wordpress)
    - [Solving memory issues with a swap file](#solving-memory-issues-with-a-swap-file)

# Local development with VVV and OSX
Use [VVV](https://github.com/Varying-Vagrant-Vagrants/VVV) and [these provision scripts](https://github.com/joeguilmette/ee-vvv-wordmove/tree/master/vvv) to create an easily replicated local development environment with multiple WordPress installs.

- Follow the instructions over at [VVV](https://github.com/Varying-Vagrant-Vagrants/VVV) to get VirtualBox, Vagrant and VVV going. But come back here before running `$ vagrant up`, we want to add some some stuff to VVV's provisioning scripts.
- Copy over everything from [VVV folder](https://github.com/joeguilmette/ee-vvv-wordmove/tree/master/vvv) to your VVV root folder.
- I've included an example in the www directory that uses some dummy data. If you need a rundown of how auto site setup works with VVV, check out the [readme](https://github.com/joeguilmette/ee-vvv-wordmove/blob/master/vvv/www/readme.md).
- Run `$ vagrant reload --provision` and let it run and it'll set up your create all the sites you've configured with auto site setup.
- **Congrats on getting your local environment going.**

# Staging and production servers with Ubuntu and EasyEngine
EasyEngine provides a full WordPress stack along with one line WordPress installation and configuration. This guide was written using Ubuntu 14.04x64, so your mileage may vary with other versions.

## Setting up and securing Ubuntu 14.04x64 on DigitalOcean
- Create a **14.04x64** Droplet.
- Follow the [initial server setup guide](https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-14-04).
- [Configure ufw](https://www.digitalocean.com/community/tutorials/how-to-setup-a-firewall-with-ufw-on-an-ubuntu-and-debian-cloud-server). Make sure to allow www, ssh, smtp and anything else you may use.
- [Configure fail2ban](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-fail2ban-on-ubuntu-14-04). This should be completed after you install EasyEngine and create a WordPress site (or at least a test site). If you don't then when you turn on filters for smtp, nginx, mysql and php it will throw errors. Also, you're going to need to rejigger the log file paths in the jail.local filters so they match EasyEngine's defaults.

### Configuring Monit
Monit will monitor system resources and services, do complicated things (like perform complicated tests, restart services, etc), and then send you an email.

- [Install Monit.](https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-monit)
- This should be done after EasyEngine is installed, otherwise there won't be any services to monitor or any way to send alerts.
- I use the following in conjunction with EasyEngine:

```
check system 1.1.1.1  
  if loadavg (1min) > 6 then alert  
  if loadavg (5min) > 4 then alert  
  if memory usage > 85% then alert  
  if swap usage > 75% then alert  
  if cpu usage (user) > 80% then alert  
  if cpu usage (system) > 70% then alert  
  if cpu usage (wait) > 60% then alert   
      
# EasyEngine Monit settings  
check process nginx with pidfile /var/run/nginx.pid  
        start program = "/etc/init.d/nginx start"  
        stop program = "/etc/init.d/nginx stop"  
  
check process mysql with pidfile /var/run/mysqld/mysqld.pid  
        start program = "/etc/init.d/mysql start"  
        stop program = "/etc/init.d/mysql stop"  
  
check process php with pidfile /var/run/php5-fpm.pid  
        start program = "/etc/init.d/php5-fpm start"  
        stop program = "/etc/init.d/php5-fpm stop"  
  
check process fail2ban with pidfile /var/run/fail2ban/fail2ban.pid  
        start program = "/etc/init.d/fail2ban start"  
        stop program = "/etc/init.d/fail2ban stop"  
  
check filesystem rootfs with path /dev/vda1  
        if space usage > 85% for 3 cycles then alert
```

- And then this to set my email settings:

```
set mailserver smtp.gmail.com port 587
        username "gmail_username" password "password" # this is the gmail account that will send the alert
        using tlsv1 with timeout 30 seconds
set alert email@address.com with reminder on 15 cycles # this address will receive the alert

set mail-format {
        from: gmail_username@gmail.com
        reply-to: gmail_username@gmail.com
        subject: DOMAIN.COM ALERT: $SERVICE $EVENT at $DATE
        message: Monit $ACTION $SERVICE at $DATE on $HOST: $DESCRIPTION.
        Sincerely,
                Your MonitRobot
}
```

## DigitalOcean Snapshots
Once the above is complete, I like to create a snapshot. This makes deploying new production servers a breeze

### Create Snapshot

- Run `$ sudo poweroff` and create a Snapshot on Digital Ocean.

### Deploy a Snapshot

- Create a Droplet on DigitalOcean, selecting an appropriate Snapshot
- Change your user password
- Reset keys in ~/.ssh/id_rsa.pub, check ~/.ssh/authorized_keys
- Change relevant, host specific settings (for me, that's just the monit email template)
- Test everything (fail2ban, check that monit can send email)

## Installing and configuring EasyEngine
- Install EasyEngine `$ wget -qO ee rt.cx/ee && sudo bash ee` and maybe even [RTFM](https://github.com/rtCamp/easyengine).
- Provision your server with`$ sudo ee stack install`.
- Configure the EasyEngine WordPress defaults in `$ sudo vim /etc/easyengine/ee.conf`. A default username, password, and valid email address are important.

## Creating new WordPress installations in production
- Create a new site with `$ sudo ee site create domain.com --wpfc`
- Configure DNS over at Digital Ocean.
    - One A record to link domain.com to your server: `A @ 1.1.1.1`.
    - One wildcard CNAME for magical reasons I don't understand: `CNAME * domain.com`.
    - One CNAME per subdomain: `CNAME subdomain domain.com` will link subdomain.domain.com to the server IP listed in your A record.



# Migrating WordPress from one of your local Varying Vagrant Vagrants to your remote Digital Ocean server
Wordmove is the easiest way to automate this process. It is based on Capistrano, and uses rsync to push or pull complete WordPress installs between two environments with simple commands like `$ wordmove pull --database --environment=staging` or `$ wordmove push --theme --environment=production`. Good stuff. And the devs are amazing.

### Installing Wordmove
If you've properly provisioned VVV with [these provisioning scripts](https://github.com/joeguilmette/ee-vvv-wordmove/tree/master/vvv) then you'll get a fancypants prerelease or Wordmove that will allow us to pass multiple rsync flags, which we really want to do.

### Configuring Wordmove
- Run `$ wordmove init` in your local WordPress root
- `$ vim Movefile` and edit the local and remote sections appropriately.
- **For SSH, make sure to set user to www-data and keep the password line commented out.**
- Make sure the local absolute path matches the OS that Wordmove is being run from, i.e.:
    - `/var/www/domain.com/wp-core` in Vagrant (locally, I run from here rather than OS X)
    - `~/vvv/www/domain.com/wp-core` in OSX
    - `/srv/www/domain.com/wordpress` in EasyEngine (if you're migrating from staging to production)

### This part is really important
For VVV to push up to a server using EasyEngine, you'll need to add this to the `ssh` block in your Movefile:
```  
rsync_options: "-og --chown=www-data:www-data --no-perms --chmod=ugo=rwX"
```

That's going to make sure the files we push up into EasyEngine have the proper ownership and permissions. I would be lying if I told you that I came up with them myself.

### Actually using Wordmove

- Navigate to the local folder that has your Movefile
- Run `$ wordmove push --all -e=server`. Change `-e=server` to whatever server you've set in your Movefile. Or change the flag from `--all` to `-t` or whatever.
    - If you're getting password prompts from Wordmove while things are pushing **then you need to send your sshkey to your server via `$ cat ~/.ssh/id_rsa.pub | ssh www-data@1.1.1.1 'cat >> .ssh/authorized_keys'`**. If that isn't working, then something is wrong with `/var/www/.ssh/authorized_keys` on your server. Fix it. Otherwise you won't be able to push/pull the db.
- Verify that everything worked.
 
### Troubleshooting a borked migration

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
    - Maybe Nginx is shitting itself, although if it is, Nginx will give you error message in the browser. But make sure it's happy with your config settings with `$ sudo nginx -t`. Maybe even restart it with `$ sudo service nginx restart`

-Still can't figure it out?
    - You probably PEBKAC'd something simple, dummy.

## Telling WP the new site url via wp-cli
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

## Importing a remote database manually
Sometimes you gotta do it...

- Dump the remote db  `$ mysqldump -u username -p remote_db_name > remote_dump.sql`
- Get the remote db `$ scp remote_dump.sql sshuser@host:/path/`
- Import the remote db `$ mysql -u username -p local_db_name < remote_dump.sql`

# Hardening WordPress

## Move wp-config.php back a dir out of the site root
- EasyEngine does this automagically (sorry Adam)...

## Change db prefix
- Easily done via vvv-init.sh and wp-cli during site creation.
- Manually specified in wp-config.php.

## Change wp-content folder
- Manually change the name of your wp-content folder.
- Add the following to the top of wp-config.php:

```
define( 'WP_CONTENT_URL', 'http://domain.com/new-content-folder' );  
define( 'WP_CONTENT_DIR', '/var/www/domain.com/htdocs/new-content-folder' );  
```

- Edit your Movefile to add:

```
  paths: # you can customize wordpress internal paths
    wp_content: "new-content-folder"
    uploads: "new-content-folder/uploads"
    plugins: "new-content-folder/plugins"
    themes: "new-content-folder/themes"
    languages: "new-content-folder/languages"
```

## Permissions
Using Wordmove should prevent these issues, but just in case... Make sure that all folders in `www/` are set to 755, and all files are set to 644.

`$ find /path/to/www/ -type d -exec chmod 755 {} \;` to 755 all folders

`$ find /path/to/www/ -type f -exec chmod 644 {} \;` to 644 all files.

## Configure ufw, fail2ban and rkhunter
These are important in securing any publicly facing server.

- Make sure Nginx, mosh, ssh, ftp and postfix are enabled in `$ sudo vim /etc/fail2ban/jail.local` and `$ sudo ufw status`, and that ufw is in fact enabled along with fail2ban.
- [Configure RKHunter once everything is up and running](https://www.digitalocean.com/community/tutorials/how-to-use-rkhunter-to-guard-against-rootkits-on-an-ubuntu-vps
).

# Optimizing WordPress
There are [some cool resources](https://github.com/davidsonfellipe/awesome-wpo) for getting optimization in WordPress right. EasyEngine is a great start. If you create sites with the `--wpfc` flag you'll get fast-cgi caching out of the box. And EasyEngine offers some other nifty caching tools to get things going.

## Solving memory issues with a swap file
EasyEngine says they handle this for you. However, even with 1gb of ram, I've run into issues with MySQL like this `[ERROR] InnoDB: Cannot allocate memory for the buffer pool` which will crash MySQL and throw `Database connection errors` on page load. Funny enough, if the error still renders in the browser after MySQL is back up, refresh your cache with `sudo ee clean all`.

Anyway, if you run into memory issues, try creating a swap file before just buying for RAM.

- Create the swapfile `$ sudo fallocate -l 1024M /swapfile`.

- Set those perms `$ sudo chmod 600 /swapfile && sudo mkswap /swapfile`.

- Start the swap `$ sudo swapon /swapfile`.

- Make sure it gets mounted on startup by adding `/swapfile none swap defaults 0 0` on a new line in `$ sudo vim /etc/fstab`

- If you run in to issues specific to InnoDB, you can also increase the cache size to see if that helps.
