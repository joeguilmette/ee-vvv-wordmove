 #!/usr/bin/env bash

 source /usr/local/rvm/scripts/rvm

 su vagrant rvm --default use --install $1

 shift

 if (( $# ))
	 then su vagrant gem install $@
 fi