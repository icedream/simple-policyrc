#!/bin/bash -e

# Simple policy-rc.d - makes service policies simply configurable.
# (c) 2019 Carl Kittelberger
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

# TODO - Implement runlevel filters.

config_dir="/etc/policy-rc.d"

filter_comments() {
	sed 's,#.*$,,g'
}

check_policy_for_service() {
	service="$1"
	action="$2"
	service_configuration_path="$config_dir/$service"
	if [ ! -f "$service_configuration_path" ]
	then
		return 0
	fi
	check_policy_from_configuration "$service_configuration_path" "$action"
}

check_policy_from_configuration() {
	service_configuration_path="$1"
	action="$2"
	# Syntax: (allow|deny|<any exit code>) action,action... [fallback,fallback,fallback...]
	while read -r permission defined_actions fallbacks
	do
		while read -d, defined_action
		do
			if [ "$defined_action" = "" ]
			then
				continue
			fi
			if [ "$action" = "$defined_action" ] || [ "$defined_action" = "*" ]
			then
				convert_permission_to_output "$permission" "$fallbacks"
				return
			fi
		done <<< "$defined_actions,"
	done < <(filter_comments "$service_configuration_path")
}

list_policies_from_configuration() {
	service_configuration_path="$1"
	while read -r permission actions fallbacks
	do
		while read -d, action
		do
			if [ -z "$action" ]
			then
				continue
			fi

			set +e
			perm_stdout="$(convert_permission_to_output "$permission" "$fallback")"
			set -e
			perm_code="$(convert_policyrc_code_to_name $?)"
			perm_extra=""

			if [ -n "$perm_stdout" ]
			then
				perm_extra+=" ("
				delimiter=""
				for fallback in "${perm_stdout[@]}"
				do
					perm_extra+="$delimiter$fallback"
					delimiter=", "
				done
				perm_extra+=")"
			fi
			log "$action => $perm_code$perm_extra"
		done <<< "$actions,"
	done < <(filter_comments "$service_configuration_path")
}

convert_policyrc_code_to_name() {
	code="$1"
	name="$1"
	case "$code" in
	0)
		name="allow"
		;;
	1)
		name="undefined"
		;;
	101)
		name="deny"
		;;
	102)
		name="subsystem error"
		;;
	103)
		name="syntax error"
		;;
	104)
		name="<reserved>"
		;;
	105)
		name="uncertain behavior"
		;;
	106)
		name="fallback"
		;;
	esac
	printf "%s" "$name"
}

convert_permission_to_output() {
	permission="$1"
	fallbacks="$2"
	case "$permission" in
	allow|0)
		return 0
		;;
	undefined|1)
		return 1
		;;
	deny|forbid|101)
		return 101
		;;
	uncertain|1-5)
		return 105
		;;
	fallback|106)
		# Convert comma-delimited fallbacks list to space-delimited
		fallback_str=""
		while IFS=, read fallback
		do
			if [ -n "$fallback_str" ]
			then
				fallback_str+=" "
			fi
			fallback_str+="$fallback"
		done <<< "$fallbacks"
		echo "$fallback_str"

		return 106
		;;
	*)
		log_error "Unexpected permission $1 given."
		return 103
		;;
	esac
}

list_all_policies_for_services() {
	service="$1"
	if [ -z "$service" ]
	then
		for service_config in "$config_dir"/*
		do
			if [ ! -f "$service_config" ]
			then
				continue
			fi
			service_name="$(basename "$service_config")"
			log "# $service_name"
			list_policies_from_configuration "$service_config"
		done
	else
		service_config="$config_dir/$service"
		if [ ! -f "$service_config" ]
		then
			log_error "No policies configuration file exists for $service."
		else
			list_policies_from_configuration "$service_config"
		fi
	fi
}

flag_quiet=0

log() {
	if [ "$flag_quiet" -ne 0 ]
	then
		return
	fi
	echo "$1"
}

log_error() {
	log "$@" >&2
}

while [ -n "$1" ]
do
	arg="$1"
	case "$arg" in
	--list)
		list_all_policies_for_services "$@"
		;;
	--quiet)
		flag_quiet=1
		;;
	--help)
		log "Simple policy-rc.d, (c) 2019 Carl Kittelberger"
		log ""
		log "This script comes with ABSOLUTELY NO WARRANTY. This is free software licensed under the terms of the GNU GPL 2.0 or later."
		log ""
		log "Usage:"
		log "  $0 [options] --list [<id>]"
		log "  $0 [options] <id> <action>"
		;;
	*)
		if [ ! -d /etc/policy-rc.d ]
		then
			log_error "No policies have been defined, skipping execution completely."
			break
		fi
		check_policy_for_service "$@"
		break
		;;
	esac
	shift 1
done
