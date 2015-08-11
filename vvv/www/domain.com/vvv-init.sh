# Init script for VVV Auto Bootstrap

# In this example I've used domain for the db, domain.dev for 
# the domain, and admin@email.com for the admin email

# When creating a new local WordPress install, this is the file
# you'll want to modify. You can use wp-cli to do pretty much
# whatever you want.

echo "Commencing vvv-init.sh"

# Make a database, if we don't already have one
echo "Creating database (if it's not already there)"
mysql -u root --password=root -e "CREATE DATABASE IF NOT EXISTS domain"
mysql -u root --password=root -e "GRANT ALL PRIVILEGES ON domain.* TO root@localhost IDENTIFIED BY 'root';"

# Download WordPress
# I like to install WP into a subfolder called wp-core
# This way, WP core doesn't comingle with VVV's auto
# site setup files, and it's easy to delete the core folder

if [ ! -d wp-core ]

then
	echo "Installing WordPress using wp-cli"

	mkdir wp-core
	cd wp-core
	
	echo "Downloading WP Core"
	wp core download 
	
	echo "Creating wp-config.php"
	wp core config --dbname="domain" --dbuser=root --dbpass=root --dbhost="localhost" --dbprefix=wp_
	
	echo "Installing WordPress"
	wp core install --title="Just another VVV install" --url=domain.dev --admin_user=admin --admin_password=password --admin_email=admin@email.com
	
	echo "Installing Plugins"
	# You can install othe rplugins with wp-cli using this command:
	# wp plugin install wp-local-toolbox
	# or
	# wp plugin install wordpress-seo

	# Install WPLT
	# It needs to be run as an mu-plugin for the plugin disabling
	# feature to work. Read more here: https://github.com/joeguilmette/wp-local-toolbox
	mkdir wp-content/mu-plugins
	curl -sS https://downloads.wordpress.org/plugin/wp-local-toolbox.zip > wp-content/mu-plugins/wp-local-toolbox.zip
	unzip -q wp-content/mu-plugins/wp-local-toolbox.zip -d wp-content/mu-plugins/
	rm wp-content/mu-plugins/wp-local-toolbox.zip
	mv wp-content/mu-plugins/wp-local-toolbox/* wp-content/mu-plugins/
	rm -rf wp-content/mu-plugins/wp-local-toolbox/
	mv wp-content/mu-plugins/read* wp-content/mu-plugins/toolbox/
	mv wp-content/mu-plugins/LICENSE wp-content/mu-plugins/toolbox/LICENSE
	# I'm pretty sure we sent a man to the moon with fewer lines of code
	# than it takes me to unpack a zip file. Whatever. It works.

    # WPLT configuration
    sed -i "3i/** WP Local Toolbox config */" wp-config.php
    sed -i "4idefine('WPLT_SERVER','local');" wp-config.php
	sed -i "5idefine('WPLT_ADMINBAR','always');" wp-config.php 
	sed -i "6idefine('WPLT_AIRPLANE','true');" wp-config.php

	echo "Goodbye Dolly"
	wp plugin uninstall hello
	wp plugin uninstall akismet
	cd ..
fi

# The Vagrant site setup script will restart Nginx for us

echo "Finished vvv-init.sh";
