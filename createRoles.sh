#!/bin/bash

if [ $# != 1 ] && [ $# != 3 ];
	then
		echo ""
		echo "Script to create the sentry roles listed in the passed in .lst file"
		echo "Usage: $0 role_list_file [keytab_file] [kerberos_principal]"
		echo ""
		exit 1
fi

roleList=$1
keytabfile=$2
principal=$3

if [ $# == 3 ];
then
	kinit -kt $keytabfile $principal
fi

host="ukgs2hmn01.cwglobal.local"
port="10000"
realm="CWGLOBAL.LOCAL"
trustStore="${JAVA_HOME}/jre/lib/security/cacerts"
trustStorePass="changeit"

beelineConnectionString="beeline -u jdbc:hive2://${host}:${port}/default;principal=hive/${host}@${realm};saslQop=auth;ssl=true;sslTrustStore=${trustStore};trustStorePass=${trustStorePass} --outputformat=csv2 --silent=true --showHeader=false"
createRoleCommands=""

rolesQuery="SHOW ROLES;"
existingRoles=$($beelineConnectionString -e "${rolesQuery}")

sortedExistingRoles=$(sort <(echo "$existingRoles"))

while IFS=' ' read role
do
	# Only create role if it doesn't already exist
	if [[ $(comm -12 <(echo "$sortedExistingRoles") <(echo "$role") | wc -l) -ne 1 ]]
	then
		createRoleCommands="${createRoleCommands}CREATE ROLE ${role};"
	fi
done < $roleList

$beelineConnectionString -e "${createRoleCommands}"

if [[ $? -ne 0 ]]
then
	echo "Failed to successfully create roles" 1>&2
	exit 1
fi