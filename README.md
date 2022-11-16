![Hyperion](https://github.com/hyperion-project/hyperion.ng/blob/master/doc/logo_dark.png?raw=true#gh-dark-mode-only)
![Hyperion](https://github.com/hyperion-project/hyperion.ng/blob/master/doc/logo_light.png?raw=true#gh-light-mode-only)

This is a simple repository containining some `docker-compose.yml` sample files useful for running [hyperiong.ng](https://github.com/hyperion-project/hyperion.ng/#readme) as a service inside a docker environment, without having to rely on one of the closed sources docker images running wild out there. 
Just copy-paste and `docker-compose up -d` it.

The docker-compose file is quite simple:

1. It's based on the [official Debian 11 (bullseye) docker image](https://hub.docker.com/_/debian)
2. It downloads the hyperion official package from the [official hyperion apt package repository](https://apt.hyperion-project.org/)
3. Maps the `/config` dirctory as an external volume, to keep your settings
4. Runs hyperiond service as non-root user. Default UID:GID are 1000:1000 but they can be easily changed adding a `.env` file

The setup is done on first run. 

Sadly, the resulting image is not exaclty slim at ~500MB, because hyperion has lots of dependencies. Since many of them are for the Desktop/Qt UI, it should be possible to slim the image up by cherry picking the ones not used but the cli service, but that's probably not really worth it.

On the other hand, the running service does not need lots of RAM (on my system takes ~64MB without the cache).

You have different options to run this image, after starting the container you can reach the web ui going either to http://youdockerhost:8090 or https://youdockerhost:8092

### Standard configuration

Simply said: git clone the repo (or directly download the Dockerfile)

```sh
git clone https://github.com/psychowood/hyperion.ng-docker
```
docker build the local image
```sh
docker build -t hyperionng --no-cache .
```
if you want to run a nightly hyperionng build, run this additional build command to update the local image
```sh
docker build -t hyperionng -f Dockerfile.nightly .
```
start the container with `docker compose up -d` with the following `docker-compose.yml` file (included in the repo):
```yaml
version: '3.3'

services:
  hyperionng:
    image: hyperionng:latest
    container_name: hyperionng
    volumes:
      - hyperionng-config:/config
    ports:
      - "19400:19400"
      - "19444:19444"
      - "19445:19445"
      - "8090:8090"
      - "8092:8092"
    restart: unless-stopped
volumes:
  hyperionng-config:
```

### Standalone configuration

This configuration (found in `docker-compose.standalone.yml`) is completely built when upping the container, it runs of debian:bullseye image and installs hyperion and dependencies at first boot.
All the main hyperion ports are mapped on your docker host.

```yaml
version: '3.3'

services:
  hyperionng:
    image: debian:bullseye
    container_name: hyperionng
    command: bash -c "groupadd -f hyperion || true &&
                    adduser -q --uid ${UID:-1000} --gid ${GID:-1000} --disabled-password --no-create-home hyperion || true &&
                    mkdir -p /config &&
                    chown ${UID:-1000}:${GID:-1000} /config &&
                    apt-get update &&
                    apt-get install -y wget gpg sudo &&
                    wget -qO /tmp/hyperion.pub.key https://apt.hyperion-project.org/hyperion.pub.key &&
                    gpg --dearmor -o - /tmp/hyperion.pub.key > /usr/share/keyrings/hyperion.pub.gpg &&
                    echo \"deb [signed-by=/usr/share/keyrings/hyperion.pub.gpg] https://apt.hyperion-project.org/ bullseye main\" > /etc/apt/sources.list.d/hyperion.list &&
                    apt-get update &&
                    apt-get install -y hyperion &&
                    apt-get clean &&
                    sudo -u hyperion /usr/bin/hyperiond -v --service -u /config"
    ports:
      - "19400:19400"
      - "19444:19444"
      - "19445:19445"
      - "8090:8090"
      - "8092:8092"
    volumes:
      - hyperionng-config:/config
    restart: unless-stopped
volumes:
  hyperionng-config:

```

In both cases, you may want to adapt the "ports" section adding other port mappings for specific cases (e.g. "2100:2100/udp" for Philips Hue in Entertainment mode).

An alternative, especially if you need advanced functions like mDNS and SSDP services, could be running the cointainer in a macvlan network bridged to your local one. The following is an example that exposes the hyperionng container with the 192.168.1.17 IP in a local network 192.168.1.0/24 with the gateway 192.168.1.1, please adapt the configuration to your specific case.

```yaml
version: '3.3'

services:
  hyperionng:
    image: hyperionng:latest
    container_name: hyperionng
    volumes:
      - hyperionng-config:/config
    networks:
      mylannet:
         ipv4_address: 192.168.1.17
    restart: unless-stopped
volumes:
  hyperionng-config:
# define networks
networks:
  mylannet:
    name: mylannet
    driver: macvlan
    driver_opts:
      parent: eth0
    ipam:
      config:
        - subnet: 192.168.1.0/24
          gateway: 192.168.1.1
          ip_range: 192.168.1.64/26
```

Moreover, if you want to use some hardware devices (USB. serial, video, and so on), you need to passthrough the correct one adding a devices section in the compose file (the following is jut an example):

```yaml
devices:
      - /dev/ttyACM0:/dev/ttyACM0
      - /dev/video1:/dev/video1
      - /dev/ttyUSB1:/dev/ttyUSB0
      - /dev/spidev0.0:/dev/spidev0.0 
```

If you want to use different UID and GID, you can add a `.env` file in the same folder of your `docker-compose.yml` file:

```properties
UID=1100
GID=1100
```
