FROM centos:7

# Install Python 3.8
RUN yum install -y epel-release
RUN yum install -y gcc openssl-devel bzip2-devel libffi-devel wget make yum-utils zlib-devel sqlite-devel mysql-devel python-devel net-snmp-devel zeromq-devel czmq-devel chrony which git gcc-c++ rpm-build policycoreutils-python libjpeg-turbo-devel
RUN cd /tmp/ && wget https://www.python.org/ftp/python/3.8.3/Python-3.8.3.tgz && tar -xvf Python-3.8.3.tgz && rm -f Python-3.8.3.tgz
RUN cd /tmp/Python-3.8.3/ && ./configure --enable-shared LDFLAGS="-Wl,-rpath /usr/local/lib" && make && make install

# Install Repo for LLVM Toolset
RUN yum install -y centos-release-scl
RUN yum-config-manager --enable rhel-server-rhscl-7-rpms

# Add External Required Repos
ADD TimeScaleDB.repo /etc/yum.repos.d/

# Update Yum
RUN yum update -y

# Update PIP
RUN pip3 install --upgrade pip

# Replace Python Executable
RUN ln -s /usr/local/bin/python3 /usr/local/bin/python
RUN rm /usr/bin/python2
RUN rm /usr/bin/python
RUN rm /usr/local/bin/pip
RUN ln -s /usr/local/bin/python3 /usr/bin/python
RUN ln -s /usr/local/bin/python3 /usr/bin/python3
RUN ln -s /usr/local/bin/pip3 /usr/local/bin/pip

# Move Python Path for YUM
RUN sed -i 's/\/usr\/bin\/python/\/usr\/bin\/python2.7/g' /usr/bin/yum
RUN sed -i 's/\/usr\/bin\/python/\/usr\/bin\/python2.7/g' /usr/libexec/urlgrabber-ext-down
RUN sed -i 's/\/usr\/bin\/python\ -Es/\/usr\/bin\/python2.7/g' /usr/sbin/semanage

#### KAFKA INSTALLATION #####

# Install Java
RUN yum install -y java-1.8.0-openjdk.x86_64

# Set Java Paths
RUN echo 'export JAVA_HOME=/usr/lib/jvm/jre-1.8.0-openjdk' >> /etc/profile
RUN echo 'export JRE_HOME=/usr/lib/jvm/jre' >> /etc/profile

# Load Java Paths
RUN source /etc/profile
ENV JAVA_HOME "/usr/lib/jvm/jre-1.8.0-openjdk"
ENV JRE_HOME "/usr/lib/jvm/jre"

# Install Kafka
RUN wget https://downloads.apache.org/kafka/2.7.2/kafka_2.13-2.7.2.tgz
RUN tar -xvf kafka_2.13-2.7.2.tgz
RUN rm -f kafka_2.13-2.7.2.tgz
RUN mv kafka_2.13-2.7.2 /opt/kafka
RUN sed -i "s/\${kafka.logs.dir}/\/var\/log\/neatly\/base\/kafka/g" /opt/kafka/config/log4j.properties

# Add Zookeeper & Kafka Service Files
ADD system/kafka-zookeeper.service /etc/systemd/system/
ADD system/kafka.service /etc/systemd/system/

# Assign Rights to Service Files
RUN chmod 755 /etc/systemd/system/kafka-zookeeper.service
RUN chmod 755 /etc/systemd/system/kafka.service

############################

###### PYTHON MODULES ######

# Install Dependencies of Requirements
RUN yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm

# Install Dependencies of Requirements
RUN yum install -y llvm-toolset-7.0 openldap-devel postgresql12 postgresql12-libs postgresql12-contrib postgresql12-server postgresql12-devel timescaledb-2-postgresql-12 socat

# Add Executable Paths to Profiles
RUN echo 'export PATH="/usr/pgsql-12/bin:$PATH"' > /etc/profile.d/pgsql.sh

# Add Executable Paths to Environment Variables
ENV PATH "/usr/pgsql-12/bin:$PATH"

# Add Requirements to Container
ADD requirements /tmp

# Install Requirements
RUN pip install -r /tmp/requirements

# Remove Requirements
RUN rm -f /tmp/requirements

# Move Python Path for RPM
RUN sed -i 's/\/usr\/bin\/python/\/usr\/bin\/python2.7/g' /usr/lib/rpm/osgi.prov
RUN sed -i 's/\/usr\/bin\/python/\/usr\/bin\/python2.7/g' /usr/lib/rpm/osgi.req

############################

####### DIRS FOR APP #######

# Logging Folders
RUN mkdir /var/log/neatly
RUN mkdir /var/log/neatly/base
RUN mkdir /var/log/neatly/base/nginx
RUN mkdir /var/log/neatly/base/kafka

# Configuration Folders
RUN mkdir /etc/neatly
RUN mkdir /etc/neatly/base

# Lib Folders
RUN mkdir /var/lib/neatly
RUN mkdir /var/lib/neatly/base

# File Folders
RUN mkdir /opt/neatly
RUN mkdir /opt/neatly/base
RUN mkdir /opt/neatly/base/gui

# Temp Folders
RUN mkdir /tmp/neatly
RUN mkdir /tmp/neatly/base
RUN mkdir /tmp/neatly/bin
RUN mkdir /tmp/neatly/system

############################

# WORKAROUND FOR SYSTEMCTL #

# Make Folder to Store systemctl Replacement
RUN mkdir systemctl

# Install 'docker-systemctl-replacement' for Docker
RUN cd /opt && git clone https://github.com/gdraheim/docker-systemctl-replacement.git && cd docker-systemctl-replacement && git checkout 99aa654 && make && rm -f /bin/systemctl && cp files/docker/systemctl3.py /bin/systemctl && rm -rf /opt/docker-systemctl-replacement

############################

## POSTGRESQL INSTALLATION #

# Add PostgreSQL Setup
ADD postgresql-12-setup /usr/pgsql-12/bin/

# Set Rights of PostgreSQL Setup
RUN chmod 755 /usr/pgsql-12/bin/postgresql-12-setup

# Set Ownership of PostgreSQL Setup
RUN chown root:root /usr/pgsql-12/bin/postgresql-12-setup

# Initialise PostgreSQL DB
RUN /usr/pgsql-12/bin/postgresql-12-setup initdb

# Configure TimeScaleDB
RUN timescaledb-tune -yes --pg-config=/usr/pgsql-12/bin/pg_config

###### USEFUL MODULES ######

# Install Modules
RUN yum install -y nano systemd wget curl less mlocate lsof net-tools
RUN updatedb

############################

############################

#### NGINX INSTALLATION ####

# Install Nginx
RUN yum install -y nginx

# Remove Default Nginx Configuration
RUN rm -rf /usr/share/nginx && rm -rf /etc/nginx/default.d && rm -f /etc/nginx/*.default

# Add Custom Nginx Configuration
ADD nginx/nginx.conf /etc/nginx/nginx.conf
ADD nginx/conf.d/* /etc/nginx/conf.d/
RUN mkdir /etc/nginx/templates/
ADD nginx/templates /etc/nginx/templates

# GUI Folders
RUN mkdir /var/www
RUN mkdir /var/www/neatly
RUN mkdir /var/www/neatly/base

############################

### ANGULAR INSTALLATION ###

# Install Node JS
RUN curl -sL https://rpm.nodesource.com/setup_10.x | bash - && yum install -y nodejs

# Install Required Global Packages
RUN npm i -g symbol-observable
RUN npm i -g semver
RUN npm i -g ansi-colors
RUN npm i -g @angular-devkit/core
RUN npm i -g debug
RUN npm i -g rxjs
RUN npm i -g ms
RUN npm i -g @angular-devkit/architect

############################

### INITIALISE POSTGRESQL ##

# Add Default DB Setup SQL File
ADD postgres-init.sql /var/lib/pgsql/

# Add Default DB Setup Script File
ADD postgres-setup.sh /root/

# Assign Sufficient Rights to the DB Setup Script File
RUN chmod 774 /root/postgres-setup.sh

# RUN DB Setup Script
RUN /root/postgres-setup.sh

# Remove Default DB Setup Script File
RUN rm -f /root/postgres-setup.sh

# Remove Default DB Setup SQL File
RUN rm -f /var/lib/pgsql/postgres-init.sql

# Copy PostgreSQL Connections Config
ADD pg_hba.conf /var/lib/pgsql/12/data/

# Set Rights of PostgreSQL Connections Config
RUN chmod 600 /var/lib/pgsql/12/data/pg_hba.conf

# Set Ownership of PostgreSQL Connections Config
RUN chown postgres:postgres /var/lib/pgsql/12/data/pg_hba.conf

############################

########## READY ###########

# Add Ready Script
ADD bin/ready /usr/local/bin/ready
RUN chmod 774 /usr/local/bin/ready

# Add Ready Push Script
ADD bin/readypush /usr/local/bin/readypush
RUN chmod 774 /usr/local/bin/readypush

# Add Ready to BashRC
RUN echo '/usr/local/bin/ready' >> /root/.bashrc

############################

### GUI PRODUCTION BUILD ###

# Add Build Production GUI Script
ADD bin/build-prod-gui /usr/local/bin/build-prod-gui
RUN chmod 774 /usr/local/bin/build-prod-gui

############################

######### DISCOVER #########

RUN updatedb

############################

######### START UP #########

# Add Start Up Script
ADD bin/start /usr/local/bin/start
RUN chmod 774 /usr/local/bin/start

# Start Neatly Base Container
CMD ["/usr/local/bin/start"]
