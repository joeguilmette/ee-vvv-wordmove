#!/usr/bin/env bash

curl -#LO https://rvm.io/mpapis.asc

gpg --import mpapis.asc

curl -sSL https://get.rvm.io | bash -s $1