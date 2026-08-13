#!/bin/bash
# Installs a browser-based Klipper web UI (Mainsail, and optionally
# Fluidd) served by nginx, proxying Moonraker's API. Without this, the
# only way to control the printer is the touchscreen - there is no way
# to reach it from a phone/PC browser.

set -e

function install_nginx()
{
    sudo apt-get update --allow-releaseinfo-change
    sudo apt-get install --yes nginx
    # nginx's worker runs as www-data, which by default cannot even
    # traverse into the printer user's home directory (mode 700), so
    # every request 500s until this is granted. Execute-only, no read/
    # write, so it doesn't expose directory listings or file contents
    # beyond what nginx's own config explicitly serves.
    chmod o+x "${HOME}"

    # nginx auto-sizes map_hash_bucket_size from the CPU's cache-line
    # size at startup. Under qemu-user-static aarch64 emulation (how
    # this image is built, since the build host is x86_64) that probe
    # can come back wrong, landing on a default too small to even hold
    # write_webui_nginx_site()'s small $expires map below - confirmed
    # via a real build failure: "could not build map_hash, you should
    # increase map_hash_bucket_size: 32". Setting it explicitly avoids
    # depending on that auto-detection at all.
    sudo tee /etc/nginx/conf.d/map_hash_bucket_size.conf > /dev/null <<'EOF'
map_hash_bucket_size 128;
EOF
}

function write_webui_nginx_site()
{
    local name=${1} webroot=${2} port=${3} is_default=${4}
    local listen_directive="listen ${port};"
    [[ "${is_default}" == "yes" ]] && listen_directive="listen ${port} default_server;\n    listen [::]:${port} default_server;"

    sudo tee "/etc/nginx/sites-available/${name}" > /dev/null <<NGINX_EOF
map \$sent_http_content_type \$expires {
    default                    off;
    text/html                  epoch;
    text/css                   max;
    application/javascript     max;
    ~image/                    max;
}

server {
    $(echo -e "${listen_directive}")

    server_name _;

    access_log off;
    error_log /var/log/nginx/${name}-error.log;

    client_max_body_size 512M;
    proxy_read_timeout 600;

    root ${webroot};
    index index.html;

    server_tokens off;
    expires \$expires;

    gzip on;
    gzip_vary on;
    gzip_comp_level 4;
    gzip_min_length 1000;
    gzip_proxied expired no-cache no-store private auth;
    gzip_types application/javascript application/json application/xml font/eot font/otf font/ttf image/svg+xml text/css text/javascript text/plain text/xml;

    location / {
        try_files \$uri \$uri/ /index.html;
    }
    location /websocket {
        proxy_pass http://apiserver_${name}/websocket;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_read_timeout 86400;
    }
    location ~ ^/(printer|api|access|machine|server)/ {
        proxy_pass http://apiserver_${name}\$request_uri;
    }
    location /webcam/ {
        postpone_output 0;
        proxy_buffering off;
        proxy_ignore_headers X-Accel-Buffering;
        proxy_pass http://mjpg_stream_${name}/;
    }
}

upstream apiserver_${name} {
    ip_hash;
    server 127.0.0.1:7125;
}

upstream mjpg_stream_${name} {
    ip_hash;
    server 127.0.0.1:8080;
}
NGINX_EOF

    sudo rm -f /etc/nginx/sites-enabled/default
    sudo ln -sf "/etc/nginx/sites-available/${name}" "/etc/nginx/sites-enabled/${name}"
}

function patch_webui_update_manager()
{
    local name=${1} repo=${2} webroot=${3}
    local cfg="${HOME}/printer_data/config/moonraker.conf"
    if ! grep -Eq "^\[update_manager ${name}\]\s*$" "${cfg}"; then
        echo "Adding ${name} to update manager in file: ${cfg}"
        {
            echo ""
            echo "[update_manager ${name}]"
            echo "type: web"
            echo "channel: stable"
            echo "repo: ${repo}"
            echo "path: ${webroot}"
        } >> "${cfg}"
    fi
}

function install_mainsail()
{
    echo "Installing Mainsail..."
    local webroot="${HOME}/mainsail"
    mkdir -p "${webroot}"
    wget -q -O "${webroot}/mainsail.zip" https://github.com/mainsail-crew/mainsail/releases/latest/download/mainsail.zip
    unzip -oq "${webroot}/mainsail.zip" -d "${webroot}"
    rm "${webroot}/mainsail.zip"

    # Mainsail is the default UI: served on port 80.
    write_webui_nginx_site "mainsail" "${webroot}" 80 "yes"
    patch_webui_update_manager "mainsail" "mainsail-crew/mainsail" "${webroot}"
}

function install_fluidd()
{
    # NOTE: registering an [update_manager fluidd] entry with an empty
    # webroot, hoping users could "install" it later with one click
    # from the Update Manager panel, does NOT work - verified by
    # reading Moonraker's own source. NetDeploy.update() (which handles
    # type: web entries) unconditionally raises "Invalid install
    # detected, aborting update" if self._is_valid is False, and
    # recover() just calls straight into update() with the same guard.
    # There is no Moonraker action that bootstraps a fresh install of a
    # web client; it can only update one that's already there. So
    # Fluidd has to actually be downloaded here, at install time, same
    # as Mainsail.
    echo "Installing Fluidd..."
    local webroot="${HOME}/fluidd"
    mkdir -p "${webroot}"
    wget -q -O "${webroot}/fluidd.zip" https://github.com/fluidd-core/fluidd/releases/latest/download/fluidd.zip
    unzip -oq "${webroot}/fluidd.zip" -d "${webroot}"
    rm "${webroot}/fluidd.zip"

    # Fluidd is opt-in, so it doesn't compete with Mainsail for port 80.
    write_webui_nginx_site "fluidd" "${webroot}" 4408 "no"
    patch_webui_update_manager "fluidd" "fluidd-core/fluidd" "${webroot}"
    echo "Fluidd installed - reachable on port 4408 (e.g. http://<sonic-pad-ip>:4408)"
}

function install_webui()
{
    install_nginx

    # 1) Mainsail is always installed, as the default UI on port 80.
    install_mainsail

    # 2) Fluidd is optional - ask, rather than installing two full UIs
    #    unconditionally on every build.
    read -rp "Also install Fluidd (alternate web UI, served on port 4408)? [y/N] " reply
    case "${reply}" in
        [yY]|[yY][eE][sS])
            install_fluidd
            ;;
        *)
            echo "Skipping Fluidd."
            ;;
    esac

    sudo nginx -t
    # Enable only, don't start/restart here: install_services.sh runs
    # this from create_rootfs.sh inside a chroot with no running init
    # system, so `systemctl restart` would fail and abort the whole
    # image build under `set -e`. Same reason klipper/moonraker's
    # install scripts only ever `systemctl enable` their services -
    # actually starting happens naturally once the image boots for
    # real. (Caught by codex review - this line never got exercised
    # through a real chroot build after being added, only via live
    # post-boot installs over SSH where a restart is harmless.)
    sudo systemctl enable nginx
}
