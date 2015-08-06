 #!/usr/bin/env bash

source /home/vagrant/.rvm/scripts/rvm

if ! rvm list rubies ruby | grep ruby-$1; then
	
	rvm install $1

fi

rvm --default use $1

shift

if (( $# ))
  then gem install $@
fi