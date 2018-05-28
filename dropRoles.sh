#!/bin/bash

if [ $# != 1 ] && [ $# != 3 ];
	then
		echo ""
		echo "Script to drop the sentry roles listed in the passed in .lst file"
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

host="ip-172-31-36-0.eu-west-1.compute.internal"
port="10000"
realm="ANDRZEJ.COM"

beelineConnectionString="beeline -u jdbc:hive2://${host}:${port}/default;principal=hive/${host}@${realm} --outputformat=csv2 --silent=true --showHeader=false"
dropRoleCommands=""

rolesQuery="SHOW ROLES;"
existingRoles=$($beelineConnectionString -e "${rolesQuery}")

sortedExistingRoles=$(sort <(echo "$existingRoles"))

while IFS="," read role
do
	# Only drop role if it already exists
	if [[ $(comm -12 <(echo "$sortedExistingRoles") <(echo "$role") | wc -l) -eq 1 ]]
	then
		dropRoleCommands="${dropRoleCommands}DROP ROLE ${role};"
	fi
done < $roleList

$beelineConnectionString -e "${dropRoleCommands}"

if [[ $? -ne 0 ]];
then
	echo "Failed to successfully drop roles" 1>&2
	exit 1
fi
