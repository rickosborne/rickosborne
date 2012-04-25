#!/bin/bash

HOTFIX_URL1='http://helpx.adobe.com/content/dam/kb/en/918/cpsid_91836/attachments/CF901.zip'
HOTFIX_FILE1='CF901.zip'
HOTFIX_URL2='http://helpx.adobe.com/content/dam/kb/en/918/cpsid_91836/attachments/CFIDE-901.zip'
HOTFIX_FILE2='CFIDE-901.zip'
HOTFIX_DIR='cf9hf2'
CF_DIR='/opt/coldfusion9'
CF_OWNER='www-data:www-data'
CF_CONTROL='/etc/init.d/coldfusion'
WEB_ROOT='/var/www'
WEB_OWNER='git:git'
CFIDE_DIR="${WEB_ROOT}/CFIDE"

if [ -f "${HOTFIX_FILE1}" ] ; then
	echo "Removing existing hotfix file ${HOTFIX_FILE1}"
	rm "${HOTFIX_FILE1}"
fi
if [ -f "${HOTFIX_FILE2}" ] ; then
	echo "Removing existing hotfix file ${HOTFIX_FILE2}"
	rm "${HOTFIX_FILE2}"
fi
if [ -d "${HOTFIX_DIR}" ] ; then
	echo "Removing existing hotfix directory ${HOTFIX_DIR}"
	rm -r "${HOTFIX_DIR}"
fi

wget -O "${HOTFIX_FILE1}" "${HOTFIX_URL1}"
wget -O "${HOTFIX_FILE2}" "${HOTFIX_URL2}"
mkdir -p "${HOTFIX_DIR}"
mkdir -p "${HOTFIX_DIR}-backup"
unzip -d "${HOTFIX_DIR}" "${HOTFIX_FILE1}"

echo "Stopping CF9.  You may be prompted for your sudo password."
sudo "${CF_CONTROL}" stop

echo "Updating files."
sudo cp "${HOTFIX_DIR}/CF901/lib/updates/chf9010002.jar" "${CF_DIR}/lib/updates/chf9010002.jar"
function remove_update {
	if [ -f "${CF_DIR}/lib/updates/$1" ] ; then
		sudo rm "${CF_DIR}/lib/updates/$1"
	fi
}
remove_update 'hf901-00001.jar'
remove_update 'hf901-00002.jar'
remove_update 'chf9010001.jar'

function backup_zip {
	if [ ! -f "${HOTFIX_DIR}-backup/$1.zip" ] ; then
		echo "Backing up $1"
		zip -r "${HOTFIX_DIR}-backup/$1.zip" "$2"
	fi
}
backup_zip 'CFIDE' "${CFIDE_DIR}"
echo "Extracting ${HOTFIX_FILE2}"
sudo unzip -d "${WEB_ROOT}" "${HOTFIX_FILE2}"
sudo chown -R "${WEB_OWNER}" "${CFIDE_DIR}"

backup_zip 'WEB-INF' "${CF_DIR}/wwwroot/WEB-INF"
echo "Extracting WEB-INF"
sudo unzip -d "${CF_DIR}/wwwroot" "${HOTFIX_DIR}/CF901/WEB-INF.zip"
sudo chown -R "${CF_OWNER}" "${CF_DIR}"

function backup_file {
	if [ ! -f "${HOTFIX_DIR}-backup/$2" ] ; then
		echo "Making a backup copy of $2"
		cp "$1/$2" "${HOTFIX_DIR}-backup"
	fi
}
backup_file "${CF_DIR}/lib" 'commons-fileupload-1.2.jar'
backup_file "${CF_DIR}/lib" 'ESAPI.properties'
backup_file "${CF_DIR}/lib" 'esapi-2.0_rc10.jar'
backup_file "${CF_DIR}/lib" 'log4j.properties'
backup_file "${CF_DIR}/lib" 'validation.properties'
backup_file "${CF_DIR}/lib" 'flex-messaging-common.jar'
backup_file "${CF_DIR}/lib" 'flex-messaging-core.jar'
backup_file "${CF_DIR}/lib" 'jpedal.jar'

sudo cp -r "${HOTFIX_DIR}/CF901/lib" "${CF_DIR}/"

echo "Starting CF9."
sudo "${CF_CONTROL}" start

