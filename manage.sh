#!/bin/bash

set -Eeo pipefail

#########################################################
# Globals                                               #
#########################################################

# readonly GITLAB_URI="https://git.pleroma.social"
# readonly PREFIX_API="api/v4/projects/pleroma%2Fpleroma/repository"
# readonly ENDPOINT_REPO="pleroma/pleroma.git"
# readonly ENDPOINT_FILE="pleroma/pleroma/raw"
# readonly ENDPOINT_LIST="pleroma/pleroma/files"
# readonly ENDPOINT_TAG="$PREFIX_API/tags"
# readonly ENDPOINT_BLOB="$PREFIX_API/blobs"
# readonly ENDPOINT_BRANCH="$PREFIX_API/branches"

#########################################################
# Helpers                                               #
#########################################################

has_command() {
    if command -v 1>/dev/null 2>&1 "$1"; then
        return 0
    else
        return 1
    fi
}

require_command() {
    if ! has_command "$1"; then
        printf "\nError: This action requires the command '%s' in your PATH.\n" "$1"
        exit 1
    fi
}

require_file() {
    if [[ ! -f $1 ]]; then
        echo "File missing: '$1' (Example at: '$2')"
        FILE_FAILED=1
    fi
}

throw_file_errors() {
    if [[ -n "$FILE_FAILED" ]]; then
        echo ""
        echo "Please create the missing files first."
        echo "The script will now exit."
        exit 1
    fi
}

docker_compose() {
    require_command docker-compose
    docker-compose "$@"
}

download_file() { # $1: source, $2: target
    if has_command curl; then
        curl -sSL "$1" -o "$2"
    elif has_command wget; then
        wget "$1" -O "$2"
    else
        printf "\nError: This action requires either curl or wget in your PATH.\n"
        exit 1
    fi
}

request_file_content() { # $1: source
    if has_command curl; then
        curl -sSL "$1"
    elif has_command wget; then
        wget "$1" -O- 2>/dev/null
    else
        printf "\nError: This action requires either curl or wget in your PATH.\n"
        exit 1
    fi
}

builds_args=""
load_env() {
    while read -r line; do
        if [[ "$line" == \#* ]] || [[ -z "$line" ]]; then
            continue;
        fi

        builds_args="${builds_args} --build-arg ${line?}"
        export "${line?}"
    done < .env
}

#########################################################
# Subcommands                                           #
#########################################################

action__build() {
    local cacheTag=""

    # Alternative 1: Get tags or branches from git (if installed)
    if [[ -z "$cacheTag" ]] && has_command git && has_command grep && has_command awk; then
        set +o pipefail
        local resolvedHash
        resolvedHash="$(git ls-remote $AKKOMA_GIT_REPO | grep "/$AKKOMA_VERSION" | awk '{ print $1 }')"
        set -o pipefail

        if [[ -n "$resolvedHash" ]]; then
            cacheTag="$resolvedHash"
        fi
    fi

    # Alternative 2: Current time
    if [[ -z "$cacheTag" ]] && has_command date; then
        echo ""
        echo "WARNING WARNING WARNING"
        echo ""
        echo "You don't have git installed, so we cannot know if the cache is up to date."
        echo "We'll use the current unix timestamp as a replacement value,"
        echo "but this means that your cache is always 'stale' and docker wastes your time."
        echo ""
        echo "WARNING WARNING WARNING"
        echo ""
        echo "Waiting 5 seconds to make sure you notice this..."
        sleep 5

        cacheTag="$(date '+%s')"
    fi

    # Alternative 3: Random number with shell
    if [[ -z "$cacheTag" ]] && [[ -n "$RANDOM" ]]; then
        echo ""
        echo "WARNING WARNING WARNING"
        echo ""
        echo "You don't have git installed, so we cannot know if the cache is up to date."
        echo "Additionally you don't have \`date\` available. (What kind of pc is this?!)"
        echo "This means we cannot set any unique value as cache tag."
        echo ""
        echo "We'll generate a random number to try and mark the cache as 'always stale'."
        echo "Hoewever: Depending on your shell this might not always work, or only work a few times."
        echo ""
        echo "You should *really* get this fixed unless you know what you're doing."
        echo ""
        echo "WARNING WARNING WARNING"
        echo ""
        echo "Waiting 5 seconds to make sure you notice this..."
        sleep 5

        cacheTag="$RANDOM"
    fi

    # Last resort: Constant value
    if [[ -z "$cacheTag" ]]; then
        echo ""
        echo "WARNING WARNING WARNING"
        echo ""
        echo "You don't have git installed, so we cannot know if the cache is up to date."
        echo "Additionally you don't have \`date\` available, and your shell refuses to generate random numbers."
        echo "This means we cannot set any unique or random value as cache tag."
        echo "Consequently your cache will always be 'fresh' and you never get updates."
        echo ""
        echo "You can work around this by running \`docker system prune\` to throw away the build cache,"
        echo "but you should *really* get this fixed unless you know what you're doing."
        echo ""
        echo "WARNING WARNING WARNING"
        echo ""
        echo "Waiting 5 seconds to make sure you notice this..."
        sleep 5

        cacheTag="broken-host-env"
    fi

    echo -e "#> (Re-)Building akkoma @$AKKOMA_VERSION with cache tag \`${cacheTag}\`...\n"
    sleep 1

    docker_compose build \
        $builds_args \
        --build-arg __VIA_SCRIPT=1 \
        --build-arg __CACHE_TAG="$cacheTag" \
        server
}

action__enter() {
    docker_compose exec server sh -c 'cd ~/akkoma && ash'
}

action__logs() {
    docker_compose logs "$@"
}

action__mix() {
    docker_compose exec server sh -c "cd ~/akkoma && mix $*"
}

action__restart() {
    action__stop
    action__start
}

action__start() {
    if [[ ! -d ./data/uploads ]] || [[ ! -d ./emoji ]]; then
        if [[ "$(id -u)" != "$DOCKER_UID" ]]; then
            echo "Please create the folders ./data/uploads and ./emoji, and chown them to $DOCKER_UID"
            exit 1
        fi

        mkdir -p ./data/uploads ./emoji
    fi

    docker_compose up --remove-orphans -d
}

action__up() {
    action__start
}

action__stop() {
    docker_compose down
}

action__down() {
    action__stop
}

action__status() {
    docker_compose ps
}

action__ps() {
    action__status
}

### DISABLED FOR THIS SETUP
# For Akkoma, I am not sure how this works yet seeing they don't use GitLab for their git hosting
# That and I have no idea how this function works lol

# action__mod() {
#     require_command dialog
#     require_command jq
#     require_command curl

#     if [[ ! -d ./debug.d ]]; then
#         mkdir ./debug.d
#     fi

#     if [[ ! -f ./debug.d/mod_files.json ]] || [[ -n "$(find ./debug.d/mod_files.json -mmin +5)" ]]; then
#         curl -sSL -# "$GITLAB_URI/$ENDPOINT_LIST/$AKKOMA_VERSION?format=json" > ./debug.d/mod_files.json

#         if [[ -f ./debug.d/mod_files.lst ]]; then
#             rm ./debug.d/mod_files.lst
#         fi

#         jq -r 'map("\(.)\n") | add' <./debug.d/mod_files.json >./debug.d/mod_files.lst
#     fi

#     if [[ -f ./debug.d/mod_files.lst ]] && [[ -r ./debug.d/mod_files.lst ]]; then
#         choices=""

#         while read -r candidate; do
#             choices="$choices $candidate $(echo "$candidate" | rev | cut -d/ -f1 | rev)"
#         done <<< "$(grep -E ".*$1.*" <./debug.d/mod_files.lst)"

#         res=$(mktemp)
#         dialog --menu "Select the file you want to modify:" 35 80 30 $choices 2>"$res"
#         choice=$(cat "$res")

#         install -D <(echo '') "./custom.d/$choice"
#         curl -sSL -# "$GITLAB_URI/$ENDPOINT_FILE/$AKKOMA_VERSION/$choice" > "./custom.d/$choice"
#     else
#         install -D <(echo '') "./custom.d/$1"
#         curl -sSL -# "$GITLAB_URI/$ENDPOINT_FILE/$AKKOMA_VERSION/$1" > "./custom.d/$1"
#     fi
# }

action__cp() {
    container="$(docker_compose ps -q server)"

    echo "$container:$1 -> $2"
    docker cp "$container:$1" "$2"
}

#########################################################
# Help                                                  #
#########################################################

print_help() {
    echo "
akkoma Maintenance Script

Usage:
    $0 [action] [action-args...]

Actions:
    build                        (Re)build the akkoma container.

    enter                        Spawn a shell inside the container for debugging/maintenance.

    logs                         Show the current container logs.

    mix [task] [args...]         Run a mix task without entering the container.

    mod [file]                   Creates the file in custom.d and downloads the content from akkoma.dev.
                                 The download respects your \$AKKOMA_VERSION from .env.
                                 (CURRENTLY BROKEN!)

    restart                      Executes #stop and #start respectively.

    start / up                   Start akkoma and sibling services.

    stop / down                  Stop akkoma and sibling services.

    status / ps                  Show the current container status.

    copy / cp [source] [target]  Copy a file from your pc to the akkoma container.
                                 This operation only works in one direction.
                                 For making permanent changes to the container use custom.d.

    ----------------------------

    You can report bugs or contribute to this project at:
        https://memleak.eu/sn0w/pleroma-docker

    or specificly for this Akkoma downstream, at:
        https://github.com/hyena-network/akkoma-docker
"
}

#########################################################
# Main                                                  #
#########################################################

# Check if there is any command at all
if [[ -z "$1" ]]; then
    print_help
    exit 1
fi

# Check for SHOPTs
if [[ -n "$SHOPT" ]]; then
    for opt in $SHOPT; do
        if [[ $opt =~ ":" ]]; then
            set -o "${opt//-o:/}"
        else
            set "$opt"
        fi
    done
fi

# Check for DEBUG
if [[ -n "$DEBUG" ]]; then
    if [[ $DEBUG == 1 ]]; then
        export DEBUG_COMMANDS=1
    elif [[ $DEBUG == 2 ]]; then
        set -x
    fi
fi

# Check if the option is "help"
case "$1" in
    "help"|"h"|"--help"|"-h"|"-?")
        print_help
        exit 0
    ;;
esac

# Check if the called command exists
func="action__${1}"
if ! type -t "$func" 1>/dev/null 2>&1; then
    echo "Unknown flag or subcommand."
    echo "Try '$0 help'"
    exit 1
fi

# Fail if mandatory files are missing
require_file ".env" ".env.dist"
# No longer required
#require_file "config.exs" "config.dist.exs"
require_file "config.docker.exs"
throw_file_errors

# Parse .env
load_env

# Handle DEBUG=2
[[ $DEBUG != 1 ]] || set -x

# Jump to called function
shift
$func "$@"

# Disable debug mode
{ [[ $DEBUG != 1 ]] || set +x; } 2>/dev/null
