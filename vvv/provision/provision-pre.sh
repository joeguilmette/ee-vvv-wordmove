# Rubygems update

if [ $(gem -v|grep '^2.') ]; then

	echo "gem installed"

else

	apt-get install -y ruby-dev

	echo "ruby-dev installed"

	echo "gem not installed"

	gem install rubygems-update

	update_rubygems

fi

echo 'trying that weird vagrant use command'
bash -l -c "rvm use --default --install 2.0.0"

# wordmove install
wordmove_install="$(gem list wordmove -i)"

if [ "$wordmove_install" = true ]; then

	echo "wordmove installed"

else

	echo "wordmove not installed"

	# once photocopier goes 1.0 we can just install base wordmove
	gem install wordmove --pre

	wordmove_path="$(gem which wordmove | sed -s 's/.rb/\/deployer\/base.rb/')"

	if [ "$(grep yaml $wordmove_path)" ]; then

		echo "can require yaml"

	else

		echo "can't require yaml"

		echo "set require yaml"

		sed -i "7i require\ \'yaml\'" $wordmove_path

		echo "can require yaml"

	fi
fi