# Ubiquiti software on resin

## Description

This project unifies the `ubiquiti` software tools into a stand alone solution which provides many other nice features:
1. Support for UNIFI controller
2. Support for UISP
3. Support for updating dynamic IP using `dhclient` with cloudflare's DNS records
4. Configurable domain that would result in serving `uisp.{{DOMAIN}}` and `unifi.{{DOMAIN}}` using `nginx`
5. `nginx` reverse proxy for serving `uisp` and `unifi` with support for self-signed or `letsencrypt` certificates (using DNS-01 challenge)

## Components / services

### UISP

Provides full support for [UISP](https://uisp.com/). It persists configuration in a docker volume.

### UniFi Controller

Provides full support for [UniFi Controller](https://www.ubnt.com/download/unifi/) software. It persists configuration in a docker volume.

### nginx

This runs as a reverse proxy forwarding requests from `unifi.{{DOMAIN}}`/`uisp.{{DOMAIN}}` to their respective container. Stores certificates as docker volumes for persistence and takes advantage of a set of variables to tweak its configuration and/or behaviour:

```
LETSENCRYPT - by default the container will generate self-signed vertificates and configure nginx to use them. Setting this variable to any value (for example 1) will change this behaviour and make the container generate letsencrypt certificates and configure nginx to use them.
CLOUDFLARE_LOGIN - cloudflare username (required if using letsencrypt certificates as DNS-01 is used for challenge)
CLOUDFLARE_APIKEY - cloudflare API key (required if using letsencrypt certificates as DNS-01 is used for challenge)
DOMAIN - domain (required)

```

### ddclient

The purpose of this container is to update the DNS records in cloudflare with the current public IP. It uses a ddclient fork available [here](https://github.com/ddclient/ddclient) which includes the needed support for cloudflare.

For ease of use, this container takes advantage of a set of variables to configure ddclient before running the service:

```
CLOUDFLARE_LOGIN - cloudflare username (required)
CLOUDFLARE_APIKEY - cloudflare API key (required)
DOMAIN - domain (required)
DDCLIENT_UPDATE_SECONDS - how often to check for IP updates (default to 300)
DDCLIENT_EXTRAARGS - additional arguments to run ddclient with (optional)
```

Configuring `DOMAIN` will instruct the service to update `uisp.{{DOMAIN}}` and `unifi.{DOMAIN}}` using the current public IP.

###

## License

Copyright 2018 Resinio Ltd.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
