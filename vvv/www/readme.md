# Auto Site Setup

The domain.com folder contains everything you need to make a shiny new local WordPress install. It also has a sample Movefile for you to check out.

## Creating New Local Installs

If you want to create another local install, simply make a copy of the domain.com directory and then edit the vvv-hosts, vvv-init.sh, and vvv-nginx.conf files.


Be careful with `vvv-init.sh` and make sure you read it over and edit all the little details. The good news is you can use wp-cli in there to do whatever the fuck you want. You can even do some fun bash stuff, like clone in a theme, or whatever.