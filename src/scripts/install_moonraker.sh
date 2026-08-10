#!/bin/bash
# Copyright (C) 2020 - 2023 Dominik Willner <th33xitus@gmail.com>
# Adapted by Jpe230 for a headless install

set -e 

source ./moonraker.config

function clone_moonraker_repo()
{
    local branch="master"
    if git clone "${MOONRAKER_REPO}" "${MOONRAKER_DIR}"; then
        cd "${MOONRAKER_DIR}" && git checkout "${branch}"
    else
        echo "Cloning Moonraker from\n ${MOONRAKER_REPO}\n failed!"
        exit 1
    fi
}

function install_moonraker_packages()
{   
    sudo apt-get update --allow-releaseinfo-change
    sudo apt-get install --yes $MOONRAKER_PKGLIST
}

function create_moonraker_env()
{
    if virtualenv -p "python3" "${MOONRAKER_ENV}"; then
        "${MOONRAKER_ENV}"/bin/pip install -U pip
        "${MOONRAKER_ENV}"/bin/pip install -r "${MOONRAKER_DIR}/scripts/moonraker-requirements.txt"
        # NOTE: tornado was previously pinned to 6.4.2 here to work around
        # websocket connections dying almost instantly with "ping timed
        # out". That turned out to be a symptom, not a real tornado bug:
        # the device's kernel misreports its monotonic clock resolution,
        # which corrupts asyncio's timer scheduling and made Tornado's
        # ping/pong deadlines (and everything else timer-based) fire
        # instantly. See install_clock_resolution_fix() below for the
        # real fix - with it in place, stock/latest tornado is stable
        # (verified with a 15s bare-websocket connection test, 14
        # messages received, zero drops). No pin needed anymore.
    else
        echo "Error creating venv for moonraker"
    fi
}

function create_moonraker_conf()
{
    local port lan printer_data cfg_dir cfg uds

    port=7125
    lan="$(hostname -I | cut -d" " -f1 | cut -d"." -f1-2).0.0/16"

    printer_data="${HOME}/printer_data"
    cfg_dir="${printer_data}/config"
    cfg="${cfg_dir}/moonraker.conf"
    uds="${printer_data}/comms/klippy.sock"

    ### write single instance config
    write_moonraker_conf "${cfg_dir}" "${cfg}" "${port}" "${uds}" "${lan}"
}

function write_moonraker_conf()
{
    local cfg_dir=${1} cfg=${2} port=${3} uds=${4} lan=${5}
    local conf_template="${INSTALLER_DIR}/resources/moonraker.conf"

    echo "Creating moonraker.conf in ${cfg_dir} ..."
    cp "${conf_template}" "${cfg}"
    sed -i "s|%USER%|${USER}|g; s|%PORT%|${port}|; s|%UDS%|${uds}|" "${cfg}"
    # if host ip is not in the default ip ranges replace placeholder,
    # otherwise remove placeholder from config
    if ! grep -q "${lan}" "${cfg}"; then
        sed -i "s|%LAN%|${lan}|" "${cfg}"
    else
        sed -i "/%LAN%/d" "${cfg}"
    fi
    echo "moonraker.conf created!"
}

function write_moonraker_service()
{
    local i=${1} printer_data=${2} service=${3} env_file=${4}
    local service_template="${INSTALLER_DIR}/resources/moonraker.service"
    local env_template="${INSTALLER_DIR}/resources/moonraker.env"

    echo "Creating Moonraker Service ${i} ..."
    sudo cp "${service_template}" "${service}"
    sudo cp "${env_template}" "${env_file}"

    [[ -z ${i} ]] && sudo sed -i "s| %INST%||" "${service}"
    [[ -n ${i} ]] && sudo sed -i "s|%INST%|${i}|" "${service}"

    sudo sed -i "s|%USER%|${USER}|g; s|%ENV%|${MOONRAKER_ENV}|; s|%ENV_FILE%|${env_file}|" "${service}"
    sudo sed -i "s|%USER%|${USER}|; s|%PRINTER_DATA%|${printer_data}|" "${env_file}"
}

function configure_moonraker_service()
{
    local cfg_dir service env_file
   
    printer_data="${HOME}/printer_data"
    cfg_dir="${printer_data}/config"
    service="${SYSTEMD}/moonraker.service"
    env_file="${printer_data}/systemd/moonraker.env"

    ### write single instance service
    write_moonraker_service "" "${printer_data}" "${service}" "${env_file}"
    echo "Moonraker instance created!"
}

function install_moonraker_polkit() {
  "${HOME}"/moonraker/scripts/set-policykit-rules.sh --disable-systemctl
}

function install_clock_resolution_fix()
{
    # Workaround for a broken clock_getres(CLOCK_MONOTONIC) on this
    # device's kernel: it reports a resolution of ~547 seconds instead of
    # nanosecond/microsecond scale. asyncio.BaseEventLoop reads this once
    # at loop creation (base_events.py: self._clock_resolution =
    # time.get_clock_info('monotonic').resolution) and uses it in
    # _run_once() as: end_time = self.time() + self._clock_resolution, to
    # decide which scheduled timers are "due". With a 547s resolution, ANY
    # timer due within the next ~9 minutes (asyncio.wait_for timeouts,
    # Tornado's websocket ping/pong deadlines, etc.) is treated as already
    # expired and fires instantly instead of at its real deadline.
    # Reproduced standalone with zero application code: a call_later(20)
    # timer fires in under 1ms once any other asyncio Task is created.
    # This broke Moonraker's update_manager git checks outright (git
    # status subprocess calls "timed out" in ~1ms every time) and was very
    # likely the true root cause behind websocket "broken pipe"
    # disconnects, for which pinning tornado==6.4.2 above is only a
    # coincidental workaround.
    #
    # Deployed as a PYTHONPATH-injected sitecustomize.py (see
    # moonraker.env) rather than editing moonraker's own source tree, so
    # it survives `git pull` updates to Moonraker without dirtying its repo.
    local pyfix_dir="${HOME}/printer_data/pyfix"
    mkdir -p "${pyfix_dir}"
    cat > "${pyfix_dir}/sitecustomize.py" <<'PYFIX_EOF'
import time

_orig_get_clock_info = time.get_clock_info


def _get_clock_info(name):
    info = _orig_get_clock_info(name)
    if name == "monotonic" and info.resolution > 0.001:
        import types
        info = types.SimpleNamespace(
            implementation=info.implementation,
            monotonic=info.monotonic,
            adjustable=info.adjustable,
            resolution=1e-6,
        )
    return info


time.get_clock_info = _get_clock_info
PYFIX_EOF
}

function install_moonraker()
{
    # 1) Clone Klipper repo
    clone_moonraker_repo

    # 2) Install pkgs
    install_moonraker_packages

    # 3) Create env
    create_moonraker_env

    # 4) Create moonraker conf
    create_moonraker_conf

    # 4) Create moonraker service
    configure_moonraker_service

    # 5) Install moonraker pollkit
    install_moonraker_polkit

    # 6) Install monotonic clock resolution fix (see function for details)
    install_clock_resolution_fix

    # 7) Enable service
    sudo systemctl enable moonraker

    sudo usermod -aG dialout $USER
}