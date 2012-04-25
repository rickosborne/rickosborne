#!/bin/sh

HOTFIX_URL='http://helpx.adobe.com/content/dam/kb/en/862/cpsid_86263/attachments/chf9010001.zip'
HOTFIX_FILE='chf901001.zip'
HOTFIX_DIR='cf9hf1'
CF_DIR='/opt/coldfusion9'
CF_OWNER='www-data:www-data'
CF_CONTROL='/etc/init.d/coldfusion'
WEB_ROOT='/var/www'
WEB_OWNER='git:git'
CFIDE_DIR="${WEB_ROOT}/CFIDE"

if [ -f "${HOTFIX_FILE}" ] ; then
	echo "Removing existing hotfix file ${HOTFIX_FILE}"
	rm "${HOTFIX_FILE}"
fi
if [ -d "${HOTFIX_DIR}" ] ; then
	echo "Removing existing hotfix directory ${HOTFIX_DIR}"
	rm -r "${HOTFIX_DIR}"
fi

wget -O "${HOTFIX_FILE}" "${HOTFIX_URL}"
mkdir -p "${HOTFIX_DIR}"
mkdir -p "${HOTFIX_DIR}-backup"
unzip -d "${HOTFIX_DIR}" "${HOTFIX_FILE}"

echo "Stopping CF9.  You may be prompted for your sudo password."
sudo "${CF_CONTROL}" stop

echo "Updating files."
sudo cp "${HOTFIX_DIR}/chf9010001.jar" "${CF_DIR}/lib/updates/chf9010001.jar"
if [ ! -f "${HOTFIX_DIR}-backup/dump.cfm" ] ; then
	echo "Making a backup copy of dump.cfm"
	cp "${CF_DIR}/wwwroot/WEB-INF/cftags/dump.cfm" "${HOTFIX_DIR}-backup"
fi
echo "Copying cfdump"
sudo unzip -d "${CF_DIR}/wwwroot" "${HOTFIX_DIR}/WEB-INF-901.zip"
sudo chown -R "${CF_OWNER}" "${CF_DIR}"

if [ ! -f "${HOTFIX_DIR}-backup/scheduletasks.cfm" ] ; then
	echo "Making a backup copy of scheduletasks.cfm"
	cp "${CFIDE_DIR}/administrator/scheduler/scheduletasks.cfm" "${HOTFIX_DIR}-backup"
fi
if [ ! -f "${HOTFIX_DIR}-backup/cfwindow.js" ] ; then
	echo "Making a backup copy of cfwindow.js"
	cp "${CFIDE_DIR}/scripts/ajax/package/cfwindow.js" "${HOTFIX_DIR}-backup"
fi
if [ ! -f "${HOTFIX_DIR}-backup/l10n.cfm" ] ; then
	echo "Making a backup copy of l10n.cfm"
	cp "${CFIDE_DIR}/administrator/cftags/l10n.cfm" "${HOTFIX_DIR}-backup"
fi
if [ ! -f "${HOTFIX_DIR}-backup/l10n_testing.cfm" ] ; then
	echo "Making a backup copy of l10n_testing.cfm"
	cp "${CFIDE_DIR}/administrator/cftags/l10n_testing.cfm" "${HOTFIX_DIR}-backup"
fi
sudo unzip -d "${WEB_ROOT}" "${HOTFIX_DIR}/CFIDE-901.zip"
sudo chown -R "${WEB_OWNER}" "${CFIDE_DIR}"

echo "Starting CF9."
sudo "${CF_CONTROL}" start

