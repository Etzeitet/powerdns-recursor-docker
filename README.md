# powerdns-recursor-docker

A powerdns-recursor docker image based on tcely/powerdns-recursor image.

This new container is designed for acting as a DNS recursor between an authoritative DNS server and a Pi-Hole instance.

In my DNS setup I have a PowerDNS Authorative Server, serving DNS for my private domains. 
I also have a Pi-Hole instance used for blocking unsavoury domains when requesting DNS for public domains. This container
updates the `forward-zones` and `forward-zones-recurse` options in `/etc/pdns-recursor/recursor.conf` to achieve this.

This container supports creating DNS server IPs from Docker Swarm Services.

Note: This image is **not** for you if you just need basic recursive DNS lookups.

## Running


```
docker run -d -p 53:53 -p 53:53/tcp \
    --name powerdns-recursor
    -e DNS_AUTH_ZONES=myprivatedomain.co.uk,private2.com \
    -e DNS_AUTH_IPS=10.10.100.1;10.20.100.2 \
    -e DNS_PIHOLE_IPS=10.30.100.3 \
    oakmoss/powerdns-recursor
```

Example Docker Compose for a Stack:

```
version: '3.5'
services:
  powerdns_recursor:
    image: oakmoss/powerdns-recursor
    networks:
      - default
    environment:
      - DNS_AUTH_ZONES=myprivatedomain.co.uk,private2.com \
      - DNS_AUTH_SERVICE=pdns_auth \
      - DNS_PIHOLE_IPS=10.30.100.3 \
    deploy:
      mode: replicated
      replicas: 1
      
  powerdns_auth:
    image: psitrax/powerdns:4
    networks:
      - default
    environment:
      - MYSQL_USER=root
      - MYSQL_PASS=password
      - MYSQL_HOST=10.10.10.10
      - MYSQL_DB=pdns
    deploy:
      mode: replicated
      replicas: 1

  # mysql setup omitted
  
```

## Environment Variables

This container needs to be configured with the Zones/Domains to forward and the IPs
of the DNS servers to forward to.

**Authoritative Zones to Forward**

* `DNS_AUTH_ZONES`: A space or comma separated list of domains that should be forwarded to an Authoritative server.

**Authoritative Server Forwarding**

* `DNS_AUTH_IPS`: A `;` separated list of IP address of your desired Authoritative DNS Servers, e.g., `10.10.100.1;10.20.100.2`. This syntax also supports specifying a port if different from the default, e.g., `10.10.100.2:5300` 
* `DNS_AUTH_SERVICE`: The name of a Docker Swarm service running in your cluster. The container will query Swarm's DNS in order to fetch all found IP addresses of containers in that service.

Note: One of the DNS_AUTH_* variables must be set. `DNS_AUTH_IPS` is ignored if both are configured.


**Pi-Hole Recursive Forwarding**

* `DNS_PIHOLE_IPS`: The IP address(es) of your Pi-Hole server to forward to. See `DNS_AUTH_IPS` for syntax.
* `DNS_PIHOLE_SERVICE`: The name of a Docker Swarm service running Pi-Hole in your cluster.

Note: One of the `DNS_PIHOLE_*` variables must be set. `DNS_PIHOLE_IPS` is ignored if both are configured.


## Default PowerDNS Recursor Configuration

All PowerDNS Recursor configuration in `/etc/pdns-recursor/recursor.conf` is the same as found
in the original image from `tcely/powerdns-recursor`, with the following exceptions:

* `disable-syslog=yes`
* `log-timestamp=no`
* `local-address=0.0.0.0`
* `setuid=pdns-recursor`
* `setgid=pdns-recursor`

Other configuration can be overridden by passing in options at the CLI or using the `command` directive in Docker Compose:

```
docker run -d -p 53:53 -p 53:53/tcp \
    --name powerdns-recursor
    -e DNS_AUTH_ZONES=myprivatedomain.co.uk,private2.com \
    -e DNS_AUTH_IPS=10.10.100.1;10.20.100.2 \
    -e DNS_PIHOLE_IPS=10.30.100.3 \
    oakmoss/powerdns-recursor \
    --local-address=10.100.100.1  # override local-address
```

```
services:
  powerdns_recursor:
    image: oakmoss/powerdns-recursor
    networks:
      - default
    environment:
      - DNS_AUTH_ZONES=myprivatedomain.co.uk,private2.com \
      - DNS_AUTH_SERVICE=pdns_auth \
      - DNS_PIHOLE_IPS=10.30.100.3 \
    command: --local-address=10.100.100.1  # override local-address
    deploy:
      mode: replicated
      replicas: 1
```

For a full list of available options that can be passed to PowerDNS Recursor, run:

```
docker run --rm tcely/powerdns-recursor --help
```



