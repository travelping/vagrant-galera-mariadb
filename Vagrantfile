# -*- mode: ruby -*-
# vi: set ft=ruby : 

#cluster configuration
CLUSTER_SIZE = 3
START_CLUSTER_ID = 1
FROM_IP = "192.168.100.101"
ALL_NODES_IN_CLUSTER = ["192.168.100.101","192.168.100.102","192.168.100.103","192.168.100.104","192.168.100.105","192.168.100.106"]

#spetial NW settings
INTERFACE_PREFFIX = "eth"
START_INTERFACE_ID = 1
HOSTNAME_PREF = 'h'

def get_nodes (count, from_ip, hostname_pref)
    nodes = []
    ip_arr = from_ip.split('.')
    first_ip_part = "#{ip_arr[0]}.#{ip_arr[1]}.#{ip_arr[2]}"
    count.times do |i|
        hostname = "%s%01d" % [hostname_pref, (i+START_INTERFACE_ID)]
        nodes.push([i+START_CLUSTER_ID, hostname, "#{first_ip_part}.#{ip_arr.last.to_i+i}", "#{INTERFACE_PREFFIX}#{i+START_INTERFACE_ID}"])
    end
    nodes
end

def provision_node(hostaddr, node_addresses)
    setup = <<-SCRIPT
sudo apt-get  -q -y update
sudo apt-get  -q -y install python-software-properties vim curl wget rsync tmux
sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
sudo add-apt-repository 'deb http://mirror.jmu.edu/pub/mariadb/repo/5.5/ubuntu precise main'
sudo apt-get  -q -y update
echo mariadb-galera-server-5.5 mysql-server/root_password password root | debconf-set-selections
echo mariadb-galera-server-5.5 mysql-server/root_password_again password root | debconf-set-selections
LC_ALL=en_US.utf8 DEBIAN_FRONTEND=noninteractive sudo apt-get -o Dpkg::Options::='--force-confnew' -qqy install mariadb-galera-server galera mariadb-client

echo "[mysqld]
wsrep_provider=/usr/lib/galera/libgalera_smm.so
wsrep_cluster_name=ma_cluster
wsrep_cluster_address="gcomm://#{node_addresses.join(',')}"
wsrep_slave_threads=8
wsrep_sst_method=rsync
wsrep_sst_auth=galera:galera
wsrep_node_address=#{hostaddr}" > /etc/mysql/conf.d/galera.cnf

echo "[client]
port        = 3306
socket      = /var/run/mysqld/mysqld.sock
[mysqld_safe]
socket      = /var/run/mysqld/mysqld.sock
nice        = 0
[mysqld]
user        = mysql
pid-file    = /var/run/mysqld/mysqld.pid
socket      = /var/run/mysqld/mysqld.sock
port        = 3306
basedir     = /usr
datadir     = /var/lib/mysql
tmpdir      = /tmp
lc_messages_dir = /usr/share/mysql
lc_messages = en_US
binlog_format=ROW
default-storage-engine=InnoDB
innodb_autoinc_lock_mode=2
query_cache_size=0
query_cache_type=OFF
bind-address        = 0.0.0.0
max_connections     = 10000
connect_timeout     = 5
wait_timeout        = 600
max_allowed_packet  = 16M
thread_cache_size       = 128
sort_buffer_size    = 4M
bulk_insert_buffer_size = 16M
tmp_table_size      = 32M
max_heap_table_size = 32M
key_buffer_size     = 128M
table_open_cache    = 400
concurrent_insert   = 2
read_buffer_size    = 2M
read_rnd_buffer_size    = 1M
# * Query Cache Configuration
query_cache_limit       = 128K
log_warnings        = 2
#log_error	= /var/log/mysql/error.log
slow_query_log_file = /var/log/mysql/mariadb-slow.log
long_query_time = 10
#log_slow_rate_limit    = 1000
log_slow_verbosity  = query_plan
log_bin         = /var/log/mysql/mariadb-bin
log_bin_index       = /var/log/mysql/mariadb-bin.index
expire_logs_days    = 10
max_binlog_size         = 100M
default_storage_engine  = InnoDB
#innodb_log_file_size   = 50M
innodb_buffer_pool_size = 2G
innodb_log_buffer_size  = 8M
innodb_file_per_table   = 1
innodb_open_files   = 1000
innodb_io_capacity  = 1000
innodb_flush_method = O_DIRECT
[mysqldump]
quick
quote-names
max_allowed_packet  = 16M
[isamchk]
key_buffer      = 16M
!includedir /etc/mysql/conf.d/" > /etc/mysql/my.cnf

echo "# Automatically generated for Debian scripts. DO NOT TOUCH!
[client]
host     = localhost
user     = debian-sys-maint
password = some_pwd
socket   = /var/run/mysqld/mysqld.sock
[mysql_upgrade]
host     = localhost
user     = debian-sys-maint
password = some_pwd
socket   = /var/run/mysqld/mysqld.sock
basedir  = /usr" > /etc/mysql/debian.cnf

mysql -u root -proot -e 'GRANT ALL PRIVILEGES on *.* TO "debian-sys-maint"@'localhost' IDENTIFIED BY "some_pwd" WITH GRANT OPTION; FLUSH PRIVILEGES;'

sudo service mysql stop
sleep 5
    SCRIPT
end

def start_cluster()
    ret = <<-SCRIPT
sudo service mysql start --wsrep-new-cluster
sleep 10
mysql -u root -proot -e 'GRANT ALL ON *.* TO 'galera'@'localhost' IDENTIFIED BY "galera"'
mysql -u root -proot -e 'GRANT ALL ON *.* TO 'galera'@"%" IDENTIFIED BY "galera"'
    SCRIPT
end

def attachnode()
    ret = <<-SCRIPT
nohup bash -c 'sleep 30;sudo service mysql start' > /home/vagrant/nohup.out &
    SCRIPT
end

Vagrant.configure("2") do |config|
    config.vm.box = "hashicorp/precise64"
    config.ssh.username = "vagrant"
    config.ssh.password = "vagrant"
    config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"
    config.vm.provider "virtualbox" do |v|
      v.memory = 4096
      v.cpus = 4
    end
    if Vagrant.has_plugin?("vagrant-cachier")
        config.cache.scope = :box
        config.cache.enable :apt
    end

    cluster_nodes = get_nodes(CLUSTER_SIZE, FROM_IP, HOSTNAME_PREF)

    cluster_nodes.each do |in_cluster_position, hostname, hostaddr, interface|
        config.vm.define hostname do |box|
            box.vm.hostname = "#{hostname}"
            #box.vm.network :private_network, ip: "#{hostaddr}", :netmask => "255.255.0.0"
            #box.vm.network :private_network, ip: "#{hostaddr}", :netmask => "255.255.0.0",  virtualbox__intnet: true
            box.vm.network :public_network, ip: "#{hostaddr}", bridge: "#{interface}"
            box.vm.provision :shell, :inline => provision_node(hostaddr, ALL_NODES_IN_CLUSTER)
            if in_cluster_position == 1
                box.vm.provision :shell, :inline => start_cluster()
            else
                box.vm.provision :shell, :inline => attachnode()
            end
        end
    end
end
