#!/usr/bin/env bash

# Copyright 2022 Balena Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e  # Exit immediately on unhandled errors

BALENARC_DATA_DIRECTORY="${BALENARC_DATA_DIRECTORY:-"${HOME}/.balena"}"

function quit {
	echo "ERROR: $1" >/dev/stderr
	exit 1
}

# Check that the version of bash meets the requirements.
# The 'declare -pf' and 'readarray -t' features require bash v4.4 or later.
function check_bash_version {
	local major="${BASH_VERSINFO[0]:-0}"
	local minor="${BASH_VERSINFO[1]:-0}"
	if (( "${major}" < 4 || ("${major}" == 4 && "${minor}" < 4) )); then
		quit "\
bash v${major}.${minor} detected, but this script requires bash v4.4 or later.
On macOS, it can be updated with 'brew install bash' ( https://brew.sh/ )
Sorry for the inconvenience!
"
	fi
}

check_bash_version

# Escape the arguments in a way compatible with the POSIX 'sh'. Alternative to
# bash's printf '%q' (because bash's printf '%q' may produce bash-specific
# escaping, for example using the $'a\nb' syntax that interprets ASCII control
# characters, which is not supported by POSIX 'sh'). Useful with the '--service'
# flag as we do not assume that balenaOS application containers will have 'bash'
# installed. Based on: https://stackoverflow.com/a/29824428
function escape_sh {
	case $# in 0) return 0; esac
	while :
	do
		printf "'"
		printf %s "$1" | sed "s/'/'\\\\''/g"
		shift
		case $# in 0) break; esac
		printf "' "
	done
	printf "'\n"
}

function print_help_and_quit {
	echo "For ssh or scp options, check the manual pages: 'man ssh' or 'man scp'.
For ssh-uuid or scp-uuid usage, see README at:
https://github.com/pdcastro/ssh-uuid/blob/master/README.md
" >/dev/stderr
	exit
}

# Check whether the BALENA_USERNAME and BALENA_TOKEN environment variables are set, for
# the purpose of balenaCloud proxy authentication, and as the username to use for ssh
# public key authentication. If either variable is not set, attempt to obtain the missing
# value from the balena CLI's ~/.balena/cachedUsername JSON file. That file is created
# by running the `balena login` command followed by the `balena whoami` command. If you
# would rather not depend on the balena CLI, set the environment variables manually with
# the values found in the balenaCloud web dashboard, Preferences page, Account Details and
# Access Tokens tabs.
function get_user_and_token {
	if [[ -n "${BALENA_USERNAME}" && -n "${BALENA_TOKEN}" ]]; then
		return
	fi
	local cached_usr_file="${BALENARC_DATA_DIRECTORY}/cachedUsername"
	if [[ ! -r "${cached_usr_file}" ]]; then
		quit "\
'BALENA_USERNAME' or 'BALENA_TOKEN' env vars not defined, and file
'${cached_usr_file}' not found or not readable.
Set the env vars as per README, or use the balena CLI 'login' and 'whoami'
commands to ensure that file is created.
"
	fi
	check_tool jq
	local cached_username
	local cached_token 
	cached_username="$(jq -r .username "${cached_usr_file}")"
	cached_token="$(jq -r .token "${cached_usr_file}")"
	BALENA_USERNAME="${BALENA_USERNAME:-"${cached_username}"}"
	BALENA_TOKEN="${BALENA_TOKEN:-"${cached_token}"}"
}

# This function will execute on the balenaOS host OS
function remote__get_container_name {
	local service="$1"
	local len="${#service}"
	local -a names
	readarray -t names <<< "$(balena-engine ps --format '{{.Names}}')"
	local result=''
	local name
	for name in "${names[@]}"; do
		if [ "${name:0:len+1}" = "${service}_" ]; then
			result="${name}"
			break
		fi
	done
	echo "${result}"
}

# This function will execute on the balenaOS host OS with bash v5
function remote__main {
	local service="$1"
	shift
	local container_name
	container_name="$(remote__get_container_name "${service}")"
	if [ -z "${container_name}" ]; then
		echo "ERROR: Cannot find a running container for service '${service}'" >/dev/stderr
		exit 1
	fi
	local -a args
	if [ "$#" = 0 ]; then
		args=('sh')
	else
		IFS=' ' args=('sh' '-c' "$*")
	fi
	local tty_flags='-i' # without '-i', STDIN is closed
	[[ "$#" = 0 || -t 0 ]] && tty_flags='-it'
	[ -n "${SSUU_DEBUG}" ] && set -x
	balena-engine exec ${tty_flags} "${container_name}" "${args[@]}"
	{ local status="$?"; [ -n "${SSUU_DEBUG}" ] && set +x; } 2>/dev/null
	return "${status}"
}

# Parse a short flag specification like '-N' or '-CNL', the latter being the
# abbreviated form for '-C' '-N' '-L'. For each short flag, set a global
# variable in the format "SSUU_FLAG_${flag}". Examples:
#   parse_short_flag '-N'
#   -> SSUU_FLAG_N='-N'
#
#   parse_short_flag '-CNL'
#   -> SSUU_FLAG_C='-CNL'
#      SSUU_FLAG_N='-CNL'
#      SSUU_FLAG_L='-CNL'
function parse_short_flag {
	local spec="$1" # flag spec like '-N' or '-CNL'
	local i
	for (( i=1; i<${#spec}; i++ )); do
		local flag="${spec:i:1}"
		if [[ "${flag}" =~ [a-zA-Z] ]]; then
			declare -g SSUU_FLAG_"${flag}"="${spec}"
		else
			break
		fi
	done
}

# Parse the arguments and split them between option arguments and positional
# arguments.
# Note: the split happens at the first UUID.balena occurrence which is always
# correct for `ssh`, but not always correct for `scp`. For the purposes of
# `scp-uuid` however, this potential incorrectness is not important.
function parse_args {
	local args=("$@")
	local nargs=${#args[@]}
	local i
	SSUU_USER=''
	SSUU_OPT_ARGS=()
	SSUU_POS_ARGS=()
	for (( i=0; i<nargs; i++ )); do
		local arg="${args[i]}"
		if [ "${arg}" = '--help' ]; then
			print_help_and_quit
		fi
		if [ "${arg}" = '--service' ]; then
			SSUU_SERVICE="${args[++i]}"
			continue
		fi
		# Is arg a UUID.balena hostname specification?
		# For ssh:
		#   '[user@]UUID.balena'
		#   'ssh://[user@]UUID.balena[:port]'
		# For scp:
		#   '[user@]UUID.balena:'
		#   'scp://[user@]UUID.balena[:port][/path]'
		# where UUID is a hexadecimal number with exactly 32 or 62 characters,
		# where 62 is not typo meant to read 64, it really is 62.
		if [[ "${SSUU_SCP}" = 0 &&
				"${arg}" =~ ^(ssh://)?((.+)@)?([[:xdigit:]]{32}|[[:xdigit:]]{62})\.balena(:[0-9]+)?$
			]]; then
			SSUU_USER="${BASH_REMATCH[3]}"
			SSUU_POS_ARGS=("${args[@]:i}")
			break
		elif [[ "${SSUU_SCP}" = 1 &&
			"${arg}" =~ ^scp://((.+)@)?([[:xdigit:]]{32}|[[:xdigit:]]{62})\.balena(:[0-9]+)?(/.*)?$
			]]; then
			SSUU_USER="${BASH_REMATCH[2]}"
			if [ -z "${SSUU_USER}" ] && [ -n "${BALENA_USERNAME}" ]; then
				SSUU_USER="${BALENA_USERNAME}"
				arg="scp://${BALENA_USERNAME}@${arg#scp://}"
				args[i]="${arg}"
			fi
			SSUU_POS_ARGS=("${args[@]:i}")
			break
		elif [[ "${SSUU_SCP}" = 1 &&
			"${arg}" =~ ^((.+)@)?([[:xdigit:]]{32}|[[:xdigit:]]{62})\.balena:.*$
			]]; then
			SSUU_USER="${BASH_REMATCH[2]}"
			if [ -z "${SSUU_USER}" ] && [ -n "${BALENA_USERNAME}" ]; then
				SSUU_USER="${BALENA_USERNAME}"
				arg="${BALENA_USERNAME}@${arg}"
				args[i]="${arg}"
			fi
			SSUU_POS_ARGS=("${args[@]:i}")
			break
		fi
		if [ "${arg:0:1}" = '-' ] && [ "${arg:1:1}" != '-' ]; then
			parse_short_flag "${arg}"
		fi
		SSUU_OPT_ARGS+=("${arg}")
	done
	if [ "${#SSUU_POS_ARGS[@]}" = 0 ]; then
		if [ "${SSUU_SCP}" = '1' ]; then
			quit "Invalid command line (missing 'UUID.balena:' remote host, including ':' character)"
		else
			quit "Invalid command line (missing 'UUID.balena' hostname)"
		fi
	fi
}

function run_ssh {
	local opt_args=("${SSUU_OPT_ARGS[@]}")  # optional arguments
	local pos_args=("${SSUU_POS_ARGS[@]}")  # positional arguments
	local l_arg=()
	local t_arg=()
	if [ -n "${SSUU_SERVICE}" ]; then
		local host="${pos_args[0]}"
		local remote_cmd=("${pos_args[@]:1}")
		if [ "${#remote_cmd[@]}" = 0 ]; then
			# interactive shell, allocate a tty
			if [ -z "${SSUU_FLAG_N}" ] && [ -z "${SSUU_FLAG_t}" ]; then
				t_arg=('-t')
			fi
		else
			remote_cmd=( "$(escape_sh "${remote_cmd[@]}")" ) # single element array
		fi
		pos_args=(
			"${host}"
			# export some functions for remote execution
			"$(declare -pf remote__get_container_name);"
			"$(declare -pf remote__main);"
			"SSUU_DEBUG=${DEBUG}"
			remote__main
			"${SSUU_SERVICE}"
			"${remote_cmd[@]}"
		)
	fi
	if [ -z "${SSUU_USER}" ] && [ -z "${SSUU_FLAG_l}" ] ; then
		l_arg=('-l' "${BALENA_USERNAME}")
	fi
	opt_args=(
		-o "ProxyCommand='$0' do_proxy %h %p"
		-p 22222
		"${l_arg[@]}"
		"${t_arg[@]}"
		"${opt_args[@]}"
	)
	set +e
	[ -n "${DEBUG}" ] && set -x
	# shellcheck disable=SC2029
	ssh "${opt_args[@]}" "${pos_args[@]}"
	{ local status="$?"; [ -n "${DEBUG}" ] && set +x; } 2>/dev/null
	set -e
	return "${status}"
}

function print_scp_service_msg {
	local service="$1"
	local uuid="$2"
	echo "\
scp-uuid does not support the '--service' flag. However, files and folders
can be copied to a service container with 'ssh-uuid', for example:

# local -> remote
$ cat local.txt | ssh-uuid --service ${service} ${uuid}.balena cat \\> /data/remote.txt

# remote -> local
$ ssh-uuid --service ${service} ${uuid}.balena cat /data/remote.txt > local.txt

Or multiple files and folders with 'tar' on the fly:

# local -> remote
$ tar cz local-folder | ssh-uuid --service ${service} ${uuid}.balena tar xzvC /data/

# remote -> local
$ ssh-uuid --service ${service} ${uuid}.balena tar czC /data remote-folder | tar xvz

Or multiple files and folders with the powerful 'rsync' tool:

# local -> remote
$ rsync -av -e 'ssh-uuid --service ${service}' local-folder ${uuid}.balena:/data/

# remote -> local
$ rsync -av -e 'ssh-uuid --service ${service}' ${uuid}.balena:/data/remote-folder .

In these examples respectively, 'cat' or 'tar' or 'rsync' must be installed both
on the local workstation and on the remote service container:
$ apt-get install -y rsync tar  # Debian, Ubuntu, etc
$ apk add rsync tar  # Alpine

Finally, if you are transferring files to/from a service's named volume (often
named 'data'), note that named volumes are also exposed on the host OS under
folder: '/mnt/data/docker/volumes/<fleet-id>_data/_data/'
As such, it is also possible to scp to/from named volumes without '--service':

# local -> remote
$ scp-uuid -r local-folder ${uuid}.balena:/mnt/data/docker/volumes/<fleet-id>_data/_data/

# remote -> local
$ scp-uuid -r ${uuid}.balena:/mnt/data/docker/volumes/<fleet-id>_data/_data/remote-folder .
" >/dev/stderr
}

function run_scp {
	if [ -n "${SSUU_SERVICE}" ]; then
		if [ -n "${SSUU_FLAG_S}" ]; then
			quit "The '-S' and '--service' options cannot be used together"
		fi
		export SSUU_SERVICE
		set +e
		[ -n "${DEBUG}" ] && set -x
		scp -S ssh-uuid "${SSUU_OPT_ARGS[@]}" "${SSUU_POS_ARGS[@]}"
		{ local status="$?"; [ -n "${DEBUG}" ] && set +x; } 2>/dev/null
		set -e
		return "${status}"
	fi
	args=(
		-P 22222
		-o "ProxyCommand='$0' do_proxy %h %p"
		"${SSUU_OPT_ARGS[@]}"
		"${SSUU_POS_ARGS[@]}"
	)
	set +e
	[ -n "${DEBUG}" ] && set -x
	scp "${args[@]}"
	{ local status="$?"; [ -n "${DEBUG}" ] && set +x; } 2>/dev/null
	set -e
	return "${status}"
}

# Run socat
function do_proxy {
	local TARGET_HOST="$1"
	local TARGET_PORT="$2"
	local PROXY_AUTH_FILE="${BALENARC_DATA_DIRECTORY}/proxy-auth"
	local SOCAT_PORT
	SOCAT_PORT="$(get_rand_port_num)"
	mkdir -p "${BALENARC_DATA_DIRECTORY}" || quit "Cannot write to '${BALENARC_DATA_DIRECTORY}'"
	echo -n "${BALENA_USERNAME}:${BALENA_TOKEN}" > "${PROXY_AUTH_FILE}" || quit "Cannot write to '${PROXY_AUTH_FILE}'"
	[ -n "${DEBUG}" ] && set -x
	socat "TCP-LISTEN:${SOCAT_PORT},bind=127.0.0.1" "OPENSSL:tunnel.balena-cloud.com:443,snihost=tunnel.balena-cloud.com" &
	{ set +x; } 2>/dev/null
	sleep 1 # poor man's wait for the background socat process to be ready
	set +e
	[ -n "${DEBUG}" ] && set -x
	socat - "PROXY:127.0.0.1:${TARGET_HOST}:${TARGET_PORT},proxyport=${SOCAT_PORT},proxy-authorization-file=${PROXY_AUTH_FILE}"
	{ local status="$?"; [ -n "${DEBUG}" ] && set +x; } 2>/dev/null
	set -e
	local pid
	pid="$(jobs -p)"
	[ -n "${pid}" ] && kill "${pid}" && wait # shutdown background tunnel
	return "${status}"
}

# Generate a random, possibly unavailable, TCP port number between
# 10,000 and 65,535 using a shady, questionable algorithm that assumes,
# based on annecodtal evidencce, that port numbers lower than 10,000
# are less likely to be available.
# If the port number is already in use, socat will produce an error.
function get_rand_port_num {
	# In bash, "$RANDOM" produces a random integer between 0 and 32767.
	# RANDOM * 2 produces an even number reasonably evenly distributed
	# over the range from 0 to 65534, and then RANDOM % 2 adds 0 or 1.
	# '% 55536 + 10000' then coerces the range into 10,000 to 65,535.
	# (This spoils the even distribution, yes, but the real problem is
	#  ensuring that the port number is not in use. It does not need
	#  to be random, it needs to be available.)
	echo $(( (RANDOM * 2 + RANDOM % 2) % 55536 + 10000 ))
}

function check_tool {
	which "$1" &>/dev/null || quit "'$1' not found in PATH. Is it installed?"
}

function main {
	get_user_and_token
	if [ "$1" = 'do_proxy' ]; then
		shift
		do_proxy "$@"
	else
		SSUU_SCP='0'
		if [ "$(basename "$0")" = 'scp-uuid' ]; then
			SSUU_SCP='1'
		fi
		parse_args "$@"
		if [ "${SSUU_SCP}" = '1' ]; then
			run_scp "$@"
		else
			run_ssh "$@"
		fi
	fi
}

main "$@"
