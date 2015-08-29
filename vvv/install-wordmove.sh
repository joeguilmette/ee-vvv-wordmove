 #!/usr/bin/env bash

echo '===============START==============='
echo '|         install-wordmove.sh         |'
echo '==================================='

if ! type rvm >/dev/null 2>&1; then

	echo 'rvm not installed - installing'

	curl -sSL https://rvm.io/mpapis.asc | gpg --import -
	
	curl -L https://get.rvm.io | bash -s stable

	source /home/vagrant/.rvm/scripts/rvm

else

	echo 'rvm already installed'

	source /home/vagrant/.rvm/scripts/rvm

fi

if ! rvm list rubies ruby | grep ruby-$1; then
	
	echo 'ruby-'.$1.' not installed - installing'
	rvm install $1

fi

echo 'trying to use ruby-'.$1
rvm --default use $1

if [ $(gem -v | grep '^2.') ]; then

	echo "ruby-gem installed"

else

	echo "ruby-gem not installed - installing"

	gemdir 2.0.0

	gem install rubygems-update --no-rdoc --no-ri

	update_rubygems

	echo 'gem: --no-rdoc --no-ri' > ~/.gemrc

fi

wordmove_install="$(gem list wordmove -i)"

if [ "$wordmove_install" = true ]; then

	echo "wordmove installed"

else

	echo "wordmove not installed"

	# once photocopier goes 1.0 we can just install base wordmove
	gem install wordmove --pre

	wordmove_path="$(gem which wordmove | sed -s 's/.rb/\/deployer\/base.rb/')"

	if [ "$(grep yaml $wordmove_path)" ]; then

		echo "can require YAML"

	else

		echo "can't require YAML"

		echo "Set require YAML"

		sed -i "7i require\ \'YAML\'" $wordmove_path

		echo "Can require YAML"

	fi
fi

echo '==================================='
echo '|         install-wordmove.sh         |'
echo '================END================'