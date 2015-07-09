##!/bin/bash
###############################################################################################
## get-easylist.sh
## Author: James White (james@jmwhite.co.uk)
## Description: Gets Adblock lists and converts them to squidGuard/ufdbGuard expression lists
## Version: 0.3 BETA
##
## Notes:
## A specific sed pattern file is required for the conversion
## Due to changes in the EasyList formats, older sed patterns will cause problems
## The pattern this script uses is tested regularly for any issues
##

SCRIPT_NAME=${0##*/}
SCRIPT_VERSION="0.3 BETA"
GITHUB_REPO="https://github.com/jamesmacwhite/squidguard-adblock"

if ! [ "$(id -u)" = 0 ] ; then
   echo "Please run this script as root"
   exit 1
fi

usage() { 

	printf "%s\n" " " \
	"-------------------------------------------------------------------------" \
	"${SCRIPT_NAME} (Version ${SCRIPT_VERSION})" \
	"${GITHUB_REPO}" \
	"Gets Adblock lists and converts them for use with squidGuard/ufdbGuard" \
	"Developed by James White" \
	"-------------------------------------------------------------------------" \
	"" \
	"USAGE:" \
	"${SCRIPT_NAME} [squidGuard/ufdbGuard] [autoconfirm]" \
	"Note: The autoconfirm parameter is for running the script without user prompts" \
	""
	
}

# If no parameters are specified, show help guide
if [ $# -eq 0 ] ; then
	usage
	exit 0
fi

show_message() {
	
	printf "\n%s\n" "INFO: $1"
}

report_issue() { 
	# If anything fails with detection, prompt to submit a bug report
	GITHUB_NEW_ISSUE_URL="${GITHUB_REPO}/issues/new/?title=$1"
	
	printf "%s\n" "ERROR: $1" \
	"Please report a bug via this URL:" \
	"${GITHUB_NEW_ISSUE_URL}" \
	" " \
 	"Providing additional information in your report such as your OS and setup will help" \
	exit 1
}

# Try and catch all the variants used on different Linux distros 
SQUID_BIN=$(command -v squid squid2 squid3)

if [ -z "${SQUID_BIN}" ] ; then
	report_issue "Squid was not detected in PATH"
	exit 1
fi

get_squid_build_flag() { 
	# $1: Squid build flag value
	${SQUID_BIN} -v | tr " " "\n" | grep -- "$1" | tail -n1 | cut -f2 -d '=' | tr -d "'"
}

get_squid_conf_value() { 
	# $1: Squid config value
	# $2: Squid config filename
	grep -i "$1" "$2" | awk '{ print $2 }'
}

UFDBGUARD_SYSCONF_FILE="/etc/sysconfig/ufdbguard"

# If ufdbGuard has this file present use that for config values
if [ -e "${UFDBGUARD_SYSCONF_FILE}" ] ; then
	UFDBGUARD_SYSCONF=1
else
	UFDBGUARD_SYSCONF=0
fi

get_ufdb_sysconf_value() { 
	grep "^$1" ${UFDBGUARD_SYSCONF_FILE} | cut -f2 -d '=' | tr -d '"'
}

get_ufdb_conf_value() { 
	# $1: ufdbGuard config value
	# $2: ufdbGuard filename path
	grep -i "$1" "$2" | awk '{ print $2 }' | sed 's/\"//g'
}

show_message "Scanning your setup please wait..."

# Squid configuration values, we can mostly use ./configure parameters
SQUID_USER=$(get_squid_build_flag "--with-default-user")
SQUID_CONF_DIR=$(get_squid_build_flag "--sysconfdir")
SQUID_CONF_FILE=$(find "${SQUID_CONF_DIR}" -iname squid.conf)
SQUID_LOG_FILE=$(get_squid_conf_value "access_log" "${SQUID_CONF_FILE}")

# If any of these are blank, better stop what were doing, because the script will fail
# Log file is not critical as its checked differently later
if [ -z "${SQUID_USER}" ] ||
[ -z "${SQUID_CONF_FILE}" ] ||
[ -z "${SQUID_CONF_DIR}" ] ; then
	report_issue "Squid configuration could not be properly detected"
	exit 1
fi

# Depending on filter type passed to the script, set the values accordingly
case "$1" in
	[sS][qQ][uU][iI][dD][gG][uU][aA][rR][dD])
	
		FILTER_TYPE="squidGuard"
		SQUIDGUARD_BIN=$(command -v squidguard squidGuard)
		FILTER_CONF_FILE=$(find "${SQUID_CONF_DIR}" -iname ${FILTER_TYPE}.conf)
		FILTER_DB_DIR=$(get_squid_conf_value "dbhome" "${FILTER_CONF_FILE}")
		FILTER_LOG_DIR=$(get_squid_conf_value "logdir" "${FILTER_CONF_FILE}")
		
	;;
	
	[uU][fF][dD][bB][gG][uU][aA][rR][dD])
		
		FILTER_TYPE="ufdbGuard"
		UFDBGUARD_BIN=$(command -v ufdbgclient)
		FILTER_CONF_FILE=$(find / -iname ${FILTER_TYPE}.conf)
		FILTER_DB_DIR=$(get_ufdb_conf_value "dbhome" "${FILTER_CONF_FILE}")
		FILTER_LOG_DIR=$(get_ufdb_conf_value "logdir" "${FILTER_CONF_FILE}")
		
		# if sysconfig file exists use this to pull values instead
		if [ "${UFDBGUARD_SYSCONF}" -eq 1 ] ; then
			FILTER_DB_DIR=$(get_ufdb_sysconf_value "BLACKLIST_DIR" "${UFDBGUARD_SYSCONF}")
			UFDBGUARD_USER=$(get_ufdb_sysconf_value "RUNAS" "${UFDBGUARD_SYSCONF}")
			SQUID_USER=${UFDBGUARD_USER}
		fi
		
	;;
	
	*)
		echo "$1 is not a valid filter value"
		exit 1
;;
	
esac

FILTER_ADBLOCK_DIR="${FILTER_DB_DIR}/adblock"

# Again if any these are blank the script will fail
# FILTER_ADBLOCK_DIR would never be blank so it doesn't get checked
if [ -z "${FILTER_CONF_FILE}" ] ||
[ -z "${FILTER_DB_DIR}" ] ; then
	report_issue "Unable to detect ${FILTER_TYPE} setup"
	exit 1
fi

if [ "${FILTER_TYPE}" == "squidGuard" ] ; then
	FILTER_BIN=${SQUIDGUARD_BIN}
fi

if [ "${FILTER_TYPE}" == "ufdbGuard" ] ; then
	FILTER_BIN=${UFDBGUARD_BIN}
fi

if [ -z "${FILTER_BIN}" ] ; then
	report_issue "Cannot detect ${FILTER_TYPE} in PATH"
	exit 1
fi


show_message "The following setup has been detected"

printf "%s\n" "Squid Bin Path: ${SQUID_BIN}" \
"Squid User: ${SQUID_USER}" \
"Squid Config Folder: ${SQUID_CONF_DIR}" \
"Squid Config File: ${SQUID_CONF_FILE}" \
"${FILTER_TYPE} Bin Path ${FILTER_BIN}" \
"${FILTER_TYPE} Config File: ${FILTER_CONF_FILE}" \
"${FILTER_TYPE} Database Folder: ${FILTER_DB_DIR}" \
"${FILTER_TYPE} Folder ${FILTER_ADBLOCK_DIR}"

if [ ! "$2" == "autoconfirm" ] ; then

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
	echo "One or more helper files are missing"
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

mkdir -p "${FILTER_ADBLOCK_DIR}"
mkdir -p ${EASYLIST_TMP_DIR}

show_message "Preparing expressions lists"

for URL in "${EASYLIST_URL_LIST[@]}"
do
	echo "Downloading list from: ${URL}"
	wget -q --no-check-certificate -P ${EASYLIST_TMP_DIR} "${URL}"
	
	LIST_FILE_PATH="${EASYLIST_TMP_DIR}/$(basename "${URL}")"
	LIST_FILE_NAME="$(basename "${LIST_FILE_PATH}" .txt)"
	
	grep -q -E '^\[Adblock.*\]$' "${LIST_FILE_PATH}"
	
	if [ ! $? -eq 0 ] ; then
		echo "An non-Adblock list was detected"
		exit 1
	fi
	
	echo "Converting ${LIST_FILE_NAME} to an expressions list for ${FILTER_TYPE}"
	sed -e "${ADBLOCK_PATTERNS}" "${LIST_FILE_PATH}" > "${FILTER_ADBLOCK_DIR}/${LIST_FILE_NAME}"
	
done

show_message "Rebuilding Database"

if [ "${FILTER_TYPE}" == "squidGuard" ] ; then
	${SQUIDGUARD_BIN} -b -d -C all
fi

if [ "${FILTER_TYPE}" == "ufdbGuard" ] ; then
	/etc/init.d/ufdb restart
fi

# Make sure permissions are good, to prevent problems with lauching any processes
chmod 644 "${FILTER_CONF_FILE}"
chmod -R 640 "${FILTER_DB_DIR}"
chmod -R 640 "${FILTER_LOG_DIR}"
chmod -R 644 "$(dirname "${FILTER_LOG_FILE}")"
chown "${SQUID_USER}":"${SQUID_USER}" "${FILTER_CONF_FILE}"
chown -R "${SQUID_USER}":"${SQUID_USER}" "${FILTER_DB_DIR}"
find "${FILTER_DB_DIR}" -type d -exec chmod 755 \{\} \; > /dev/null 2>&1

# access_log may not be defined or set to none, so we need to check before using chmod
if [ ! "${SQUID_LOG_FILE}" == "none" ] || [ ! -z "${SQUID_LOG_FILE}" ] ; then
	chmod 755 "$(dirname "${SQUID_LOG_FILE}")"
fi

show_message "Reloading squid"
${SQUID_BIN} -k reconfigure

# Remove adblock folder in /tmp
rm -rf ${EASYLIST_TMP_DIR} > /dev/null 2>&1

show_message "Adblock expressions lists are now installed!"
