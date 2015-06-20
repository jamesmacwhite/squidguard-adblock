#!/bin/bash
#########################################################################################
## get-easylist.sh
## Author: James White (james@jmwhite.co.uk)
## Description: Gets Adblock lists and converts them for use with SquidGuard
## Version: 0.2
##
## Notes:
## A specific sed pattern file is required for the conversion
## Due to changes in the EasyList formats, older sed patterns will cause problems
## The pattern this script uses is tested regularly for any issues
##

SCRIPT_NAME=${0##*/}
SCRIPT_VERSION="0.2"

echo "Starting ${SCRIPT_NAME} Version: ${SCRIPT_VERSION}"

if ! [ "$(id -u)" = 0 ]; then
   echo "Please run this script as root"
   exit 1
fi

get_squid_build_flag() { 
	# $1: Build flag used during compile
	squid -v | tr " " "\n" | grep -- "$1" | tail -n1 | cut -f2 -d '=' | sed "s/'//g"
}

get_squid_conf_value() { 
	# $1: Squid config value
	# $2: Squid config filename
	grep -i "$1" "$2" | awk '{ print $2 }'
}

echo "Scanning Squid and SquidGuard setup please wait..."

# Squid/SquidGuard Configuration
SQUID_BIN=$(command -v squid squid2 squid3)
SQUID_USER=$(get_squid_build_flag "--with-default-user")
SQUID_CONF_DIR=$(get_squid_build_flag "--sysconfdir")
SQUID_CONF_FILE=$(find "${SQUID_CONF_DIR}" -name squid.conf)
SQUID_LOG_FILE=$(get_squid_conf_value "access_log" "${SQUID_CONF_FILE}")
SQUIDGUARD_BIN=$(command -v squidguard squidGuard)
SQUIDGUARD_CONF_FILE=$(find / -iname squidGuard.conf)
SQUIDGUARD_DB_DIR=$(get_squid_conf_value "dbhome" "${SQUIDGUARD_CONF_FILE}")
SQUIDGUARD_ADBLOCK_DIR="${SQUIDGUARD_DB_DIR}/adblock"

show_message() {
	echo ""
	echo "###########################################"
	echo "$1"
	echo "###########################################"
	echo ""
}

show_message "The following paths have been detected"
echo "Squid Bin Path: ${SQUID_BIN}"
echo "Squid User: ${SQUID_USER}"
echo "Squid Config Folder: ${SQUID_CONF_DIR}"
echo "Squid Config File: ${SQUID_CONF_FILE}"
echo "SquidGuard Config File: ${SQUIDGUARD_CONF_FILE}"
echo "SquidGuard Database Folder: ${SQUIDGUARD_DB_DIR}"
echo "SquidGuard Adblock Folder ${SQUIDGUARD_ADBLOCK_DIR}"
echo ""


if [ ! "$*" == "bypass_check" ] ; then
	read -r -p "Does everything look OK? [Y/N] " SQUID_CONF_OK
	case ${SQUID_CONF_OK} in
    	[yY][eE][sS]|[yY]) 
        	echo "Great, will continue executing script"
		;;
    	*)
			echo "Exiting..."
        	exit 1
        ;;
	esac
fi

# Pattern and URL files
SED_PATTERN_FILE="patterns.sed"
URL_LIST_FILE="urls.txt"

if [ ! -e "${SED_PATTERN_FILE}" ] || [ ! -e "${URL_LIST_FILE}" ] ; then
	echo "URL or Patterns file is missing. Script cannot continue"
	exit 1
fi

# Removes the header and modifies the format for use with this script
strip_file_header() { 
	grep -v '^$\|^#' "$1" | sed 's/$/ /' | tr -d '\n'
}

ADBLOCK_PATTERNS=$(strip_file_header "${SED_PATTERN_FILE}")
URL_LIST=$(strip_file_header "${URL_LIST_FILE}")

# EasyList Configuration
EASYLIST_TMP_DIR="/tmp/adblock"
EASYLIST_URL_LIST=(${URL_LIST}) # URL list as array to loop

mkdir -p "${SQUIDGUARD_ADBLOCK_DIR}"
mkdir -p ${EASYLIST_TMP_DIR}

show_message "Downloading Adblock lists"

for URL in "${EASYLIST_URL_LIST[@]}"
do
	wget -q --no-check-certificate -P ${EASYLIST_TMP_DIR} "${URL}"
	
	LIST_FILE_PATH="${EASYLIST_TMP_DIR}/$(basename "${URL}")"
	LIST_FILE_NAME="$(basename "${LIST_FILE_PATH}" .txt)"
	
	grep -q -E '^\[Adblock.*\]$' "${LIST_FILE_PATH}"
	
	if [ ! $? -eq 0 ] ; then
		echo "An non-adblock list was detected."
		exit 1
	fi
	
	echo "Converting ${LIST_FILE_NAME} to an expressions list for SquidGuard"
	sed -e "${ADBLOCK_PATTERNS}" "${LIST_FILE_PATH}" > "${SQUIDGUARD_ADBLOCK_DIR}/${LIST_FILE_NAME}"
	
done

show_message "Rebuilding SquidGuard Database"
${SQUIDGUARD_BIN} -b -d -C all

# Make sure permissions are good, otherwise SquidGuard will go into emergency mode
# https://help.ubuntu.com/community/SquidGuard

chmod 644 "${SQUIDGUARD_CONF_FILE}"
chmod -R 640 "${SQUIDGUARD_DB_DIR}"
chmod -R 644 "$(dirname "${SQUID_LOG_FILE}")"
chown "${SQUID_USER}":"${SQUID_USER}" "${SQUIDGUARD_CONF_FILE}"
chown -R "${SQUID_USER}":"${SQUID_USER}" "${SQUIDGUARD_DB_DIR}"
find "${SQUIDGUARD_DB_DIR}" -type d -exec chmod 755 \{\} \; -print > /dev/null 2>&1
chmod 755 "$(dirname "${SQUID_LOG_FILE}")"

show_message "Reloading squid"
${SQUID_BIN} -k reconfigure

# Remove adblock folder in tmp
rm -rf ${EASYLIST_TMP_DIR} > /dev/null 2>&1

echo "Adblock expressions lists are now installed!"
