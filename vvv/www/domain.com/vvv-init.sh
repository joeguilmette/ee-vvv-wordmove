# Init script for VVV Auto Bootstrap

# In this example I've used domain for the db, domain.dev for 
# the domain, and admin@email.com for the admin email

echo "Commencing vvv-init.sh"

# Make a database, if we don't already have one
echo "Creating database (if it's not already there)"
mysql -u root --password=root -e "CREATE DATABASE IF NOT EXISTS domain"
mysql -u root --password=root -e "GRANT ALL PRIVILEGES ON domain.* TO root@localhost IDENTIFIED BY 'root';"

# Download WordPress
if [ ! -d wp-core ]

then
	echo "Installing WordPress using WP CLI"
	
	# I like to install WP into a subfolder called wp-core
	# This way, WP core doesn't comingle with VVV's auto
	# site setup files

	mkdir wp-core
	cd wp-core
	
	echo "Downloading WP Core"
	wp core download 
	
	echo "Creating wp-config.php"
	wp core config --dbname="domain" --title="Just another VVV install" --dbuser=root --dbpass=root --dbhost="localhost" --dbprefix=wp_
	
	echo "Installing WordPress"
	wp core install --url=domain.dev --admin_user=admin --admin_password=password --admin_email=admin@email.com
	
	echo "Installing Plugins"
	# EasyEngine plugins
	wp plugin install --activate w3-total-cache
	wp plugin install --activate nginx-helper
	
    wp plugin install --activate wp-local-toolbox
	
	echo "Goodbye Dolly"
	wp plugin uninstall hello
	wp plugin uninstall akismet
	cd ..
fi

# The Vagrant site setup script will restart Nginx for us

echo "Finished vvv-init.sh";
