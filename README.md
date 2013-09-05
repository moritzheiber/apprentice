# Apprentice

Apprentice is tiny server application that determines the current state of a running [MariaDB Galera master-master cluster setup](https://mariadb.com/kb/en/what-is-mariadb-galera-cluster/) and responds to HTTP requests on a pre-defined port, depending on the state of the server it is checking on.

## How does it work?

You can find out about the syntax by running `apprentice --help`:

    $ apprentice --help
    Usage: apprentice [options]

    Specific options:
        -s, --server SERVER              Connect to SERVER
        -u, --user USER                  USER to connect the server with
        -p, --password PASSWORD          PASSWORD to use
        -i, --ip IP                      Local IP to bind to
            --port PORT                  Local PORT to use
            --sql_port PORT              Port of the MariaDB server to connect to
            --[no-]accept-donor          Accept cluster state "Donor/Desynced" as valid

    Common options:
        -h, --help                       Show this message
        -v, --version                    Show version


## What it does

It determines whether or not the server it is connected to is alive and ready to serve connections to clients. Furthermore, it also determines whether said server is a healthy part of the MariaDB cluster it belongs.

## What it doesn't do

* **Loadbalancing**: In turn, it's ment to supply loadbalancers with data on whether or not to include a certain node into their balancing pool
* **Relay client connections**: Apprentice itself only serves two responses on a pre-determined port:
    * *`200 OK`*: The server Apprentice is checking is healthy and ready to accept connections
    * *`503 Service Unavailable`*: The server is unavailable and not ready for connections

## What's it checking exactly?

Apprentice checks the following variables:

* **wsrep_cluster_size**: A cluster size below 2 is considered an error since there must never be one single server inside a cluster setup.
* **wsrep_ready**: Shows whether or not the replication is actually running or not. This must return `ON` for the server to be considered
* **wsrep_local_state**: This should read `4`, however, you may also use the --donor-allowed flag on the command-line to turn the value `2` into an acceptable value. Whether or not this is a desired state in your environment is at your discretion.
    * *Note*: The value `2` indicates the server in question is currently being used as a donor to another member of the cluster and might be exhibiting slow-downs and/or erratic behaviour due to elevated network traffic and disc IO. For further explanation please [consult the MariaDB documentation](https://mariadb.com/kb/en/what-is-mariadb-galera-cluster/).

## That's great and all, but what gives?
By itself, Apprentice doesn't do aynthing all that useful. However, it accommodates [HAProxy's httpchk method](http://cbonte.github.io/haproxy-dconv/configuration-1.4.html#option%20httpchk) quite nicely, making it possible to let HAProxy not only balance connection among a large pool of MariaDB cluster servers but also check on the cluster members health while doing so. With it you needn't care about a server dropping out of the cluster and clients still connecting to it since HAProxy and Apprentice are going to take care of that failing member by taking him out of the connection pool.

## Goodies

I've included an (untested) init.d script which you may use in order to start Apprentice at boot time.

## TODO

* Write better (r)docs. I'm sorry for the abysmal state they're in right now
* Be a lot more forgiving when it comes to SQL connection errors/reconnects/server going awol.
* Finish the rspec definitions. Sorry for missing out on those as well.
* Write a better init script