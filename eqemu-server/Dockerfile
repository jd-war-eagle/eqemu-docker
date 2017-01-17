FROM ubuntu:trusty

# Installs build essentials
RUN apt-get update && apt-get -y install \
  gcc \
  g++ \
  make \
  cmake \
  libio-stringy-perl \
  libperl-dev \
  subversion \
  unzip \
  git \
  libmysqlclient-dev \
  libboost-dev \
  liblua5.1-dev && \
rm -rf /var/lib/apt/lists/*

# Install eqemu server essentials
RUN apt-get update && apt-get -y install \
  apache2 \
  php5 \
  php5-mysql \
  mysql-server \
  mysql-client && \
rm -rf /var/lib/apt/lists/*

# Install CLI tools
RUN apt-get update && apt-get -y install \
  supervisor \
  curl \
  vim \
  wget \
  htop && \
rm -rf /var/lib/apt/lists/*

# Add files
ADD files /

# Clone eqemu source
RUN \
  cd /root && \
  mkdir peq server && \
  git clone https://github.com/EQEmu/Server.git eqemu

# Downlaod loginserver dependencies
RUN \
  cd /root/eqemu && \
  wget -q https://eqemu.github.io/downloads/ubuntu_LoginServerCrypto_x64.zip && \
  unzip -d dependencies ubuntu_LoginServerCrypto_*.zip && \
  rm ubuntu_LoginServerCrypto_*.zip

# Build eqemu with loginserver enabled
RUN \
  cd /root/eqemu && \
  cmake -DEQEMU_BUILD_LOGIN=TRUE -DEQEMU_ENABLE_BOTS=TRUE . && \
  make

# Download assets
RUN \
  cd /root/server && \
  cp /root/eqemu/utils/scripts/eqemu_server.pl .
RUN \
  cd /root/server && \
  perl eqemu_server.pl maps
RUN \
  cd /root/server && \
  perl eqemu_server.pl opcodes
RUN \
  cd /root/server && \
  perl eqemu_server.pl quests
RUN \
  cd /root/server && \
  perl eqemu_server.pl plugins
RUN \
  cd /root/server && \
  perl eqemu_server.pl lua_modules
RUN \
  cd /root/server && \
  perl eqemu_server.pl utility_scripts

# Downlaod PEQ files
RUN \
  cd /root/ && \
  curl -OL http://edit.peqtgc.com/weekly/peq_beta.zip && \
  unzip peq_beta.zip -d peq && \
  rm peq_beta.zip

# Prepare server directory
RUN \
  cd /root/server && \
  mkdir logs && \
  cp /root/eqemu/bin/* . && \
  cp /root/eqemu/utils/defaults/log.ini . && \
  cp /root/peq/eqtime.cfg .

#loginserver opcodes
RUN \
  cd /root/server && \
  ln -s /root/eqemu/loginserver/login_util/login_opcodes.conf . && \
  ln -s /root/eqemu/loginserver/login_util/login_opcodes_sod.conf .

RUN \
  cp /eqemu-files/eqemu_config.xml.full /root/server/eqemu_config.xml

# Copy over spell file
RUN \
  cp /eqemu-files/spells_us.txt /root/server/spells_us.txt

# Install peqphpeditor
RUN \
  cd /var/www && \
  git clone https://github.com/ProjectEQ/peqphpeditor.git && \
  sed -i -r "s/short_open_tag = Off/short_open_tag = On/gI" /etc/php5/apache2/php.ini && \
  mkdir /var/www/peqphpeditor/logs && \
  chmod -R 755 /var/www

ADD entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
