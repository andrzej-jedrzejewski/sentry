#!/bin/bash

if [ $# != 1 ] && [ $# != 3 ];
then
	echo ""
	echo "Script to grant the privileges on either a URI, database or table(s) to a given role as specified in the .lst file"
	echo "Usage: $0 role_privileges_file [keytab_file] [kerberos_principal]"
	echo "e.g. ./grantPrivilege.sh role_privileges.lst sentry.keytab NPDSVC.Cloudera.Sent"
	echo ""
	exit 1
fi

rolePrivilegesFile=$1
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
commands=""

while IFS=' ' read role accessType object tablePattern
do

	if [ -z $tablePattern ];
	then
		if [[ $object =~ ^.*://.*$ ]];
		then
			# Object is a URI, so apply privilege to URI
			commands="${commands}GRANT ${accessType} ON URI ${object} TO ROLE ${role};"
		else
			# Object is a database, so apply privilege to database
			commands="${commands}GRANT ${accessType} ON DATABASE ${object} TO ROLE ${role};"
		fi
	else
		# There is a table pattern included, so apply privilege to tables
		tableQuery="USE ${object}; SHOW TABLES LIKE '${tablePattern}'"
		tables=$(${beelineConnectionString} -e "${tableQuery}")
		commands="${commands}USE ${object};"
		for table in ${tables}
		do
			commands="${commands}GRANT ${accessType} ON TABLE ${table} TO ROLE ${role};"
		done
	fi

done < $rolePrivilegesFile

${beelineConnectionString} -e "${commands}"

if [[ $? -ne 0 ]];
then
	echo "Failed to successfully grant privileges" 1>&2
	exit 1
fi
