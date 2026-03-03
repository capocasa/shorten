# nimshort

A minimal, secure URL shortener written in Nim.

## Server

nimshort is a headless HTTP server backed by an embedded LMDB database.
Write operations require bearer token authentication.

### Build

```
NIMBLE_DIR=/opt/nimble nimble build
```

Add `/opt/nimble/bin` to PATH if building remotely.

### Token Setup

Generate a hash for your secret token:

```
$ export NIMSHORT_TOKEN=mysecrettoken
$ nimshort
a1b2c3d4...
```

The hash is printed to stderr and the program exits. Use it in the systemd config below.

### Systemd

```ini
# /etc/systemd/system/nimshort.service
[Unit]
Description=nimshort
After=network.target
Wants=network-online.target

[Service]
DynamicUser=True
ExecStart=nimshort
Restart=always
NoNewPrivileges=yes
PrivateDevices=yes
PrivateTmp=yes
ProtectHome=yes
ProtectSystem=full
Environment=NIMSHORT_HASH=<your-hash> NIMSHORT_PORT=7071
StateDirectory=nimshort
WorkingDirectory=%S/nimshort

[Install]
WantedBy=multi-user.target
```

```
systemctl enable --now nimshort
```

### Nginx

Proxy all requests to nimshort, serving static files first if they exist:

```nginx
server {
  server_name short.url;
  listen 443 ssl;
  listen [::]:443 ssl;
  ssl_certificate /etc/letsencrypt/live/short.url/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/short.url/privkey.pem;
  include /etc/letsencrypt/options-ssl-nginx.conf;

  root /var/www/short.url;
  location / {
    try_files $uri @nimshort;
  }
  location @nimshort {
    proxy_pass http://127.0.0.1:7071;
    proxy_buffering off;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-Port $server_port;
  }
}
```

### API

```
PUT    /<key>   Auth: Bearer <token>   Body: <url>   → 201
GET    /<key>                                         → 301 redirect
HEAD   /<key>                                         → 200 / 404
DELETE /<key>   Auth: Bearer <token>                   → 201 / 404
```

## CLI

The `shorten` command is a companion CLI tool included in the same package.

### Setup

Add to `~/.bashrc`:

```bash
export SHORTEN_KEY=mysecrettoken
export SHORTEN_URL=https://short.url
```

### Usage

```bash
# Shorten a URL
shorten https://example.com/very/long/url
# https://short.url/abcdef

# Pipe from stdin
echo https://example.com/long | shorten

# Look up a short URL
shorten get abcdef
# https://example.com/very/long/url

# Delete a short URL
shorten delete abcdef
```

## Changelog

```
0.2.0   Add shorten CLI tool and rewrite README
0.1.0   Minimal secure headless URL shortener
```

## License

MIT
