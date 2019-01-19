## Introduction
This repository hosts a setup script that simplies the installation of LEMP stack suitable for Debian Jessie environments. It is a fork of https://github.com/aatishnn/lempstack.

Any questions or issues? Feel free to open an issue or suggest new features.

Read more over at the original author's blog:
http://linuxdo.blogspot.com/2012/08/optimized-lemp-installer-for.html

## What has changed
* modified for Debian 8 Jessie
* updated configuration
* removed unnecessary packages
* changed [php-suhosin](https://suhosin.org/) installation to not use dotdeb.org
* enabled [OPcache](https://secure.php.net/manual/en/intro.opcache.php)
* added IPv6
* added [SPDY](https://developers.google.com/speed/spdy/) (will be changed to [HTTP/2](https://http2.github.io/) as soon as a fitting nginx is available in the stable repo)
* added TLS via [letsencrypt](https://letsencrypt.org/) (installs [certbot](https://certbot.eff.org/), automates renewal, adds new certificate at virtual host creation)
* creation of (bigger) dhparam.pem
* added security related headers

## Quick Install
Run these commands as root:

1. `wget https://github.com/mdPlusPlus/lempstack/raw/master/lemp-debian.sh`
2. `chmod +x lemp-debian.sh`
3. `wget https://github.com/mdPlusPlus/lempstack/raw/master/setup-vhost.sh`
4. `chmod +x setup-vhost.sh`
5. `./lemp-debian.sh`
6. `./setup-vhost.sh`
