#!/usr/bin/env bash

if ! type rvm >/dev/null 2>&1; then

	curl -sSL https://rvm.io/mpapis.asc | gpg --import -
	
	curl -L https://get.rvm.io | bash -s $1

fi