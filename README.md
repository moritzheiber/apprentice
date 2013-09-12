# Apprentice

Apprentice is tiny server application (under 300 lines of ruby code) that determines the integrity of a running [MariaDB/MySQL slave](https://mariadb.com/kb/en/replication-overview/) or [MariaDB Galera master-master cluster member](https://mariadb.com/kb/en/what-is-mariadb-galera-cluster/) and responds to HTTP requests on a pre-defined port, depending on the state of the server it is checking on.

## How does it work?

You can find out about the syntax by running `apprentice --help`:

    $ apprentice --help
    Usage: apprentice [options]

    Specific options:
        -s, --server SERVER              SERVER to connect to
        -u, --user USER                  USER to connect to the server with
        -p, --password PASSWORD          PASSWORD to use
        -t, --type TYPE                  TYPE of server. Must either by "galera" or "mysql".
        -i, --ip IP                      Local IP to bind to
                                         (default: 0.0.0.0)
            --port PORT                  Local PORT to use
                                         (default: 3307)
            --sql_port PORT              Port of MariaDB/MySQL server to connect to
                                         (default: 3306)
            --[no-]accept-donor          Accept galera cluster state "Donor/Desynced" as valid
                                         (default: false)
            --threshold SECONDS          MariaDB/MySQL slave lag threshold
                                         (default: 120)

    Common options:
        -h, --help                       Show this message
        -v, --version                    Show version


## What it does

It determines whether or not the server it is connected to is alive and ready to serve connections to clients. Furthermore, it also determines whether said server is a healthy enough to serve connections, i.e. doesn't suffer from slave lag or has separated from the cluster.

## What it doesn't do

* **Loadbalancing**: In turn, it's ment to supply loadbalancers with data on whether or not to include a certain node into their balancing pool
* **Relay client connections**: Apprentice itself only serves two responses on a pre-determined port:
    * *`200 OK`*: The server Apprentice is checking is healthy and ready to accept connections
    * *`503 Service Unavailable`*: The server is unavailable and not ready for connections

## What's it checking exactly?
###MariaDB/MySQL
Apprentice checks the following variables:

* **Slave_IO_Running**: Indicates whether a slave is actually replicating from its master. If this is set to "No" or even "nil" the server is considered unfit for serving client connections.
* **Seconds_Behind_Master**: Indicates how far (in seconds) the slave is behind its master's state. A threshold above 120 is widely considered to be unsuitable for serving valid data. The lower the value the higher the risk of Apprentice returning a negative result.
    * *Note*: Generally, MariaDB/MySQL slaves are lagging a little (even if it is just fractions to few seconds). A threshold value below 30 - 60 (depending on your setup) would probably be too conservative. However, YMMV.

For Apprentice to be able to check on the mentioned variables the user you specify on the command line needs [the 'REPLICATION CLIENT' privileges](http://dev.mysql.com/doc/refman/5.0/en/privileges-provided.html#priv_replication-client) granted within the given server. Otherwise Apprentice is going to return a negative result.

###Galera
Apprentice checks the following variables:

* **wsrep_cluster_size**: A cluster size below 2 is considered an error since there must never be one single server inside a cluster setup.
* **wsrep_ready**: Shows whether or not the replication is actually running or not. This must return `ON` for the server to be considered
* **wsrep_local_state**: This should read `4`, however, you may also use the --donor-allowed flag on the command-line to turn the value `2` into an acceptable value. Whether or not this is a desired state in your environment is at your discretion.
    * *Note*: The value `2` indicates the server in question is currently being used as a donor to another member of the cluster and might be exhibiting slow-downs and/or erratic behaviour due to elevated network traffic and disc IO. For further explanation please [consult the MariaDB documentation](https://mariadb.com/kb/en/what-is-mariadb-galera-cluster/).

## That's great and all, but what gives?
By itself, Apprentice doesn't do anything all that useful. However, it accommodates [HAProxy's httpchk method](http://cbonte.github.io/haproxy-dconv/configuration-1.4.html#option%20httpchk) quite nicely, making it possible to let HAProxy not only balance connection among a large pool of MariaDB/MySQL slave nodes or cluster members but also check on their respected "health" while doing so.
Usually, HAProxy would only be able to establish a connection to a server without checking on its consistency. Apprentice does that job for you and helps HAProxy make the right decision on which servers to let a client gain access to.

## Goodies

### Init-script
I've included an init.d script, `ruby-apprentice.init` which you may use in order to start Apprentice at boot time. The init-script needs a file named `ruby-apprentice` inside the directory `/etc/defaults/`. An example file is included with the repository, aptly named `ruby-apprentice.default`.

    $ mv ruby-apprentice.init /etc/init.d/ruby-apprentice
    $ chmod +x /etc/init.d/ruby-apprentice
    $ mv ruby-apprentice.defaults /etc/defaults/ruby-apprentice

Now you just need to add the relevant information for starting Apprentice. The defaults file is pretty self explanatory.

## TODO

* Finish the rspec definitions. Sorry for missing out on those as well.
* Maybe integrate a logger
* Write a better init script