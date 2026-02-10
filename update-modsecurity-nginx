#!/usr/bin/env bash

MODSECURITY_REPO="https://github.com/owasp-modsecurity/ModSecurity"
MODSECURITY_NGINX_CON_REPO="https://github.com/owasp-modsecurity/ModSecurity-nginx"
CRS_REPO="https://github.com/coreruleset/coreruleset.git"
CRS_DIR="/etc/coreruleset/coreruleset"
CRS_PLUGIN_DIR="/etc/coreruleset/plugins/"


SRC_DIR="/usr/local/src"

# 0 = ERROR
# 1 = INFO
# 2 = DEBUG
# 3 = TRACE
LOG_LEVEL=3

log() {
    local level="${1^^}"
    if [[ "$LOG_LEVEL" < 3 && "$level" == "TRACE" ]]; then
        return
    elif [[ "$LOG_LEVEL" < 2 && "$level" == "DEBUG" ]]; then
        return
    elif [[ "$LOG_LEVEL" < 1 && "$level" == "INFO" ]]; then
        return
    fi
    echo "[$(date)] $level: $2"
}

detect_threads() {

    # Find out how many threads we have to work with, so we can multi-thread the 
    # compilation
    local threads=$(grep -c ^processor /proc/cpuinfo)
    if [[ -z "$threads" ]]; then
        threads=1
    fi
    threads=$(( threads > 1 ? threads - 1 : threads ))

    echo "$threads"

    return 0
}

update_modsecurity() {
    local threads="${1:-1}"

    log "info" "Starting ModSecurity update!"

    local previous_dir=$(pwd)

    local modsecurity_src_dir="${SRC_DIR%/}/ModSecurity"

    # If the source has already be downloaded, then make sure we're safe to run git
    # and pull the latest sources, otherwise freshly clone the repo and submodules
    if [[ -d "$modsecurity_src_dir" ]]; then
        cd "$modsecurity_src_dir"
        if ! git config --global --get-all safe.directory | grep -Fxq "$modsecurity_src_dir"; then
            git config --global --add safe.directory "$modsecurity_src_dir" > /dev/null \
                || { log "error" "Failed to mark the directory as safe for git!"; return 1; }
        fi
        log "info" "Pulling latest updates from $MODSECURITY_REPO"
        git pull --quiet --recurse-submodules > /dev/null \
            || { log "error" "git pull --recurse-submodules failed!"; return 1; }
    else
        log "info" "ModSecurity sources missing. Cloning from $MODSECURITY_REPO"
        cd "${modsecurity_src_dir%/*}"
        git clone --quiet --recursive "$MODSECURITY_REPO" ModSecurity > /dev/null \
            || { log "error" "Unable to clone repo!"; return 1; }
        cd "$modsecurity_src_dir"
    fi

    # Make sure we have the full list of tags
    git fetch --tags > /dev/null || { log "error" "git fetch --tags failed!"; return 1; }

    # Grab the latest tag from the list. This should be the latest release
    local latest_tag=$(git tag --list --sort=-v:refname | head -n 1)
    if [[ -z "$latest_tag" ]]; then
        log "error" "No ModSecurity tags were detected!"
        return 1
    fi

    # Set the head to the latest tag
    log "info" "Setting tag to $latest_tag"
    git reset --hard "$latest_tag" > /dev/null \
        || { log "error" "git reset --hard \"${latest_tag}\" failed!"; return 1; }
    
    # Install dependancies
    local old_dbf="$DEBIAN_FRONTEND"
    export DEBIAN_FRONTEND=noninteractive
    apt-get update > /dev/null\
        || { log "error" "Failed to update apt repo cache"; return 1; }
    apt-get install -y autoconf automake build-essential git libcurl4-gnutls-dev \
        libgeoip-dev liblmdb-dev libpcre2-dev libtool libxml2-dev libyajl-dev \
        pkgconf zlib1g-dev > /dev/null \
        || { log "error" "Failed to update ModSecurity dependancies"; return 1; }
    export DEBIAN_FRONTEND="$old_dbf"

    # Start the build process with build.sh and ./configure
    log "debug" "Running build.sh"
    ./build.sh > /dev/null || { log "error" "build.sh failed to run!"; return 1; }
    log "debug" "Running ./configure"
    ./configure --with-pcre2 --with-lmdb > /dev/null \
        || { log "error" "./configure --with-pcre2 --with-lmdb failed to run!"; return 1; }

    log "debug" "making with $threads thread(s)"
    make -j "$threads" > /dev/null || { log "error" "Failed to compile!"; return 1; }
    log "debug" "installing"
    make install > /dev/null || { log "error" "Failed to install!"; return 1; }

    mkdir -p /etc/nginx/modsecurity.d
    cp -f ./unicode.mapping /etc/nginx/modsecurity.d/unicode.mapping
    cp -f ./modsecurity.conf-recommended /etc/nginx/modsecurity.d/modsecurity.conf

    cd "$previous_dir"

    log "info" "Successfully updated ModSecurity!"

    return 0
}

update_modsecurity_nginx_connector() {
    log "info" "Starting ModSecurity-nginx connector module update"

    local previous_dir=$(pwd)

    local modsecurity_nginx_con_dir="${SRC_DIR%/}/ModSecurity-nginx"

    # If the source has already be downloaded, then make sure we're safe to run git
    # and pull the latest sources, otherwise freshly clone the repo and submodules
    if [[ -d "$modsecurity_nginx_con_dir" ]]; then
        cd "$modsecurity_nginx_con_dir"
        if ! git config --global --get-all safe.directory | grep -Fxq "$modsecurity_nginx_con_dir"; then
            git config --global --add safe.directory "$modsecurity_nginx_con_dir" > /dev/null || { log "error" "Failed to mark the directory as safe for git!"; return 1; }
        fi
        log "debug" "Pulling latest updates from $MODSECURITY_NGINX_CON_REPO"
        git pull --recurse-submodules > /dev/null || { log "error" "git pull --recurse-submodules failed!"; return 1; }
    else
        log "debug" "ModSecurity sources missing. Cloning from $MODSECURITY_NGINX_CON_REPO"
        cd "${modsecurity_nginx_con_dir%/*}"
        git clone --recursive "$MODSECURITY_NGINX_CON_REPO" ModSecurity-nginx > /dev/null || { log "error" "Unable to clone repo!"; return 1; }
        cd "$modsecurity_nginx_con_dir"
    fi

    # Make sure we have the full list of tags
    git fetch --tags > /dev/null || { log "error" "git fetch --tags failed!"; return 1; }

    # Grab the latest tag from the list. This should be the latest release
    latest_tag=$(git tag --list --sort=-v:refname | head -n 1)
    if [[ -z "$latest_tag" ]]; then
        log "error" "No ModSecurity-nginx tags were detected!"
        return 1
    fi

    # Set the head to the latest tag
    log "debug" "Setting tag to $latest_tag"
    git reset --hard "$latest_tag" > /dev/null \
        || { log "error" "git reset --hard \"${latest_tag}\" failed!"; return 1; }

    cd "$SRC_DIR"

    log "debug" "Removing old nginx sources"
    rm -Rf nginx-*
    rm -f nginx_*

    log "debug" "Pulling new nginx sources"
    apt-get update > /dev/null || { log "error" "apt update failed!"; return 1; }
    apt-get source nginx > /dev/null || { log "error" "apt source nginx failed!"; return 1; }

    local nginx_src_dir=$(ls -d nginx-*/ | sort -V | tail -n1)
    if [[ ! -z "$nginx_src_dir" && -d "$nginx_src_dir" ]]; then
        nginx_src_dir="${SRC_DIR%/}/${nginx_src_dir%/}"
        cd "$nginx_src_dir"
    else
        log "error" "Unable to find nginx sources!"
        return 1
    fi

    ./configure --with-compat --add-dynamic-module="${modsecurity_nginx_con_dir}" > /dev/null \
        || { log "error" "Failed to run ./configure --with-compat --add-dynamic-module=${modsecurity_nginx_con_dir}"; return 1; }

    make modules > /dev/null \
        || { log "error" "Failed to compile ModSecurity-nginx module!"; return 1; }

    cp -f ./objs/ngx_http_modsecurity_module.so /usr/lib/nginx/modules/ngx_http_modsecurity_module.so > /dev/null \
        || { log "error" "Failed to install ModSecurity-nginx module!"; return 1; }

    cd "$previous_dir"

    log "info" "Successfully updated ModSecurity-nginx connector module!"

    return 0
}

update_coreruleset() {
    log "info" "Starting CoreRuleset update!"

    local previous_dir=$(pwd)

    # If the source has already be downloaded, then make sure we're safe to run git
    # and pull the latest sources, otherwise freshly clone the repo and submodules
    if [[ -d "$CRS_DIR" ]]; then
        cd "$CRS_DIR"
        if ! git config --global --get-all safe.directory | grep -Fxq "$CRS_DIR"; then
            git config --global --add safe.directory "$CRS_DIR" > /dev/null \
                || { log "error" "Failed to mark the directory as safe for git!"; return 1; }
        fi
        log "info" "Pulling latest updates from $CRS_REPO"
        git pull --quiet --recurse-submodules > /dev/null \
            || { log "error" "git pull --recurse-submodules failed!"; return 1; }
    else
        log "info" "CoreRuleset sources missing. Cloning from $CRS_REPO"
        local parent_dir="${CRS_DIR%/*}"
        mkdir -p "$parent_dir" \
            || { log "error" "Unable to create directory!"; return 1; }
        cd "$parent_dir"
        git clone --quiet --recursive "$CRS_REPO" coreruleset > /dev/null \
            || { log "error" "Unable to clone repo!"; return 1; }
        cd "$CRS_DIR"
    fi

    # Make sure we have the full list of tags
    git fetch --tags > /dev/null || { log "error" "git fetch --tags failed!"; return 1; }

    # Grab the latest tag from the list. This should be the latest release
    local latest_tag=$(git tag --list --sort=-v:refname | head -n 1)
    if [[ -z "$latest_tag" ]]; then
        log "error" "No coreruleset tags were detected!"
        return 1
    fi

    # Set the head to the latest tag
    log "info" "Setting tag to $latest_tag"
    git reset --hard "$latest_tag" > /dev/null \
        || { log "error" "git reset --hard \"${latest_tag}\" failed!"; return 1; }

    cp -f crs-setup.conf.example ../crs-setup.conf
    [[ -d "$CRS_PLUGIN_DIR" ]] || mkdir -p "$CRS_PLUGIN_DIR" \
        || { log "error" "Failed to make plugin directory!"; return 1; }

    log "info" "New CRS configuration available at $CRS_DIR/crs-setup.conf"

    cd "$previous_dir"

    log "info" "Successfully updated CoreRulest!"

    return 0
}

update_crs_plugin() {
    local plugin_name="$1"
    local plugin_repo="$2"
    local plugin_dir="${plugin_repo%.git}"
    plugin_dir="${plugin_dir##*/}"
    log "info" "Starting CoreRuleset $plugin_name plugin update!"

    local previous_dir=$(pwd)

    # If the source has already be downloaded, then make sure we're safe to run git
    # and pull the latest sources, otherwise freshly clone the repo and submodules
    if [[ -d "${CRS_PLUGIN_DIR%/}/${plugin_dir}" ]]; then
        cd "${CRS_PLUGIN_DIR%/}/${plugin_dir}"
        if ! git config --global --get-all safe.directory | grep -Fxq "${CRS_PLUGIN_DIR%/}/${plugin_dir}"; then
            git config --global --add safe.directory "${CRS_PLUGIN_DIR%/}/${plugin_dir}" > /dev/null \
                || { log "error" "Failed to mark the directory as safe for git!"; return 1; }
        fi
        log "info" "Pulling latest updates from $plugin_repo"
        git pull --quiet --recurse-submodules > /dev/null \
            || { log "error" "git pull --recurse-submodules failed!"; return 1; }
    else
        log "info" "CoreRuleset $plugin_name plugin sources missing. Cloning from $plugin_repo"
        [[ -d "$CRS_PLUGIN_DIR" ]] || mkdir -p "$CRS_PLUGIN_DIR" \
            || { log "error" "Failed to make plugin directory!"; return 1; }
        cd "$CRS_PLUGIN_DIR"
        git clone --quiet --recursive "$plugin_repo" "$plugin_dir" > /dev/null \
            || { log "error" "Unable to clone repo!"; return 1; }
        cd "${CRS_PLUGIN_DIR%/}/${plugin_dir}"
    fi

    # Make sure we have the full list of tags
    #git fetch --tags > /dev/null || { log "error" "git fetch --tags failed!"; return 1; }

    # Grab the latest tag from the list. This should be the latest release
    #local latest_tag=$(git tag --list --sort=-v:refname | head -n 1)
    #if [[ -z "$latest_tag" ]]; then
    #    log "error" "No coreruleset tags were detected!"
    #    return 1
    #fi

    # Set the head to the latest tag
    #log "info" "Setting tag to $latest_tag"
    #git reset --hard "$latest_tag" > /dev/null \
    #    || { log "error" "git reset --hard \"${latest_tag}\" failed!"; return 1; }

    cd "$previous_dir"

    log "info" "Successfully updated CoreRuleset $plugin_name plugin!"

    return 0
}

main() {
    log "info" "Rebuilding libmodsecurity and ModSecurity-nginx module, and CoreRuleset rules and plugins"

    local threads=$(detect_threads)

    update_modsecurity "$threads" || exit 1
    update_modsecurity_nginx_connector || exit 1

    update_coreruleset || exit 1
    #update_crs_plugin "Wordpress" "https://github.com/coreruleset/wordpress-rule-exclusions-plugin.git" || exit 1
    #update_crs_plugin "Nextcloud" "https://github.com/coreruleset/nextcloud-rule-exclusions-plugin.git" || exit 1
    #update_crs_plugin "PHPMyAdmin" "https://github.com/coreruleset/phpmyadmin-rule-exclusions-plugin.git" || exit 1

    log "info" "Reloading nginx"
    systemctl reload nginx
}

main