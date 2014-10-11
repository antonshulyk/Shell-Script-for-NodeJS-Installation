#!/bin/bash

node_version="0.10.23"

# Get user name 
user_name="$(id -u -n)"

# Get user id
user_id="$(id -u)"

# Get Oses's category
dist=`grep DISTRIB_ID /etc/*-release | awk -F '=' '{print $2}'`

# Get User's home directory ex: /home/nodejs
home_directory=$(eval echo ~${SUDO_USER})

#if [ "$(id -u)" == "0" ]; then
#    echo "Sorry, You can't run this script with root permission."
#    exit 1
#fi


echo "Execution of this script will setup following components:
 ● Basic system tools
  ◦ openjdk-7-jre
  ◦ git
  ◦ curl
  ◦ make
  ◦ build-essential
  ◦ g++
  ◦ libicu-dev
  ◦ imagemagick
 ● Redis
 ● MongoDB
 ● RethinkDB
 ● Nodejs | $node_version
  ◦ nvm
  ◦ npm
  ◦ pm2
  ◦ grunt-cli
  ◦ bower
  ◦ istanbul
  ◦ node-dev
  ◦ node-inspector
  ◦ jshint
"

read -p "Do you want to install this packages? y/N? " result
if [ "$result" == "y" ]; then

    if [ "$dist" == "Ubuntu" ]; then
	echo "Your OS is Ubuntu"
	
	# install base system
	sudo apt-get update
	sudo apt-get install -y openjdk-7-jre git-core curl make build-essential g++ libicu-dev imagemagick python-software-properties

    else
	sudo yum update
	sudo yum install java-1.7.0-openjdk.x86_64 git curl-devel make gcc gcc-c++ kernel-devel
    fi

    
    echo "
#
#
# Generating RSA keys
#
#"
    ssh-keygen -b 2048 -t rsa -q

#####################################################
# This script will install nginx,
# and download a pre-defined config from this repo
#####################################################
    echo "
#
#
# Installing Nginx
#
#"
    if [ "$dist" == "Ubuntu" ]; then
    
	sudo apt-get install nginx
    else
	rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
	sudo yum install nginx
    fi

    echo "
#
#
# Installing NodeJs
#
#"
    # Nodejs install
    
    curl -sL http://raw.github.com/creationix/nvm/master/install.sh | sh

    if [ "$dist" == "Ubuntu" ]; then
	source $home_directory/.profile
    else
	source $home_directory/.bash_profile
    fi

    source $home_directory/.nvm/nvm.sh

    nvm install $node_version

    echo "
#
#
# Installing pm2, jshint, bower, node-inspector, node-dev, instanbul
#
#"
    # PM2 install

    npm install pm2 jshint bower node-inspector node-dev istanbul -g

    if [ "$dist" == "Ubuntu" ]; then

    echo "
#
#
# Installing logrotate
#
#"
	# logrotate

	sudo apt-get install logrotate cron

	read -p "Do you want to install RethinkDB? y/N? " result

	if [ "$result" == "y" ]; then
	    echo "installing RethinkDB"
	    sudo add-apt-repository ppa:rethinkdb/ppa
	    sudo apt-get update
	    sudo apt-get install rethinkdb
	    sudo apt-get install python-virtualenv

	    cd ~
	    mkdir rethink
	    cd rethink
	    virtualenv venv
	    source venv/bin/activate

	    pip install rethinkdb

	    #    rethinkdb --bind all
    
	else
	    echo "Skipped RethinkDB installation"
	fi
	
	read -p "Do you want to install MongoDB? y/N? " result

	if [ "$result" == "y" ]; then
	    echo "installing MongoDB"
	    # mongodb installing
	    
	    # The `apt-key` call registers the public key of the custom 10gen MongoDB aptitude repository
    	    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10
	    
	    # A custom 10gen repository list file is created containing the location of the MongoDB binaries
	    echo "deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen" | sudo tee -a /etc/apt/sources.list.d/10gen.list
	    
	    # Aptitude is updated so that new packages can be registered locally on the Droplet
	    sudo apt-get -y update
	    
	    # Aptitude is told to install MongoDB
	    sudo apt-get -y install mongodb-10gen
	else
	    echo "Skipped MongoDB installation"
	fi
    else
	# install RethinkDB
	read -p "Do you want to install RethinkDB? y/N? " result
	if [ "$result" == "y" ]; then
	    sudo wget http://download.rethinkdb.com/centos/6/`uname -m`/rethinkdb.repo \
	          -O /etc/yum.repos.d/rethinkdb.repo
	    sudo yum install rethinkdb
	else
	    echo "Skipped RethinkEB installation"
	fi
	
	#insatall mongodb
	read -p "Do you want to install MongoDB? y/N? " result
	if [ "$result" == "y" ]; then
	    echo '[10gen]' >> /etc/yum.repos.d/10gen.repo
	    echo 'name=10gen Repository' >> /etc/yum.repos.d/10gen.repo
	    echo 'baseurl=http://downloads-distro.mongodb.org/repo/redhat/os/x86_64' >> /etc/yum.repos.d/10gen.repo
	    echo 'gpgcheck=0' >> /etc/yum.repos.d/10gen.repo
	    echo 'enabled=1' >> /etc/yum.repos.d/10gen.repo
	    
	    yum install mongo-10gen mongo-10gen-server
	else
	    echo "Skippped MongoDB installation."
	fi
	
    fi

#########################################
# This script will install redis,
# and download a pre-configured config
#########################################
    read -p "Do you want to install redis? y/N? " result

    if [ "$result" == "y" ]; then
	    echo "installing redis"

	# Redis Defaults
	REDIS_URL="http://redis.googlecode.com/files/redis-2.6.14.tar.gz"
	REDIS_TGZ="redis-2.6.14.tar.gz"
	REDIS_DIR="redis-2.6.14"

	# Download and unpack Nginx
	wget -q $REDIS_URL
	tar zxf $REDIS_TGZ

	# Move into the directory and build
	cd $REDIS_DIR
	make

	# Copy the executables to the /opt/redis directory
	sudo cp src/redis-benchmark /usr/local/bin
	sudo cp src/redis-cli /usr/local/bin
	sudo cp src/redis-server /usr/local/bin
	sudo cp src/redis-check-aof /usr/local/bin
	sudo cp src/redis-check-dump /usr/local/bin

	# Download the pre-defined config
	curl -sL http://git.io/pu0alA | sudo tee /etc/default/redis

	# Download the init script, and make executable
	curl -sL http://git.io/w4GcUg | sudo tee /etc/init.d/redis
	sudo chmod +x /etc/init.d/redis

	# Start redis
	sudo /etc/init.d/redis start
    else
        echo "Skipped redis installation"
    fi

    # completion message
    echo  "installation has done"
    
else
    # cancel message
    echo  "Installation has cancelled"
fi



