 #!/usr/bin/env bash

curl -#LO https://rvm.io/mpapis.asc

gpg --import mpapis.asc

curl -sSL https://get.rvm.io | bash -s $1

# add RVM to PATH for scripting
PATH="$GEM_HOME/bin:$HOME/.rvm/bin:$PATH"
[ -s ${HOME}/.rvm/scripts/rvm ] && source ${HOME}/.rvm/scripts/rvm