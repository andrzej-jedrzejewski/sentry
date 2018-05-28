#!/bin/bash

if [ $# != 1 ] && [ $# != 3 ];
then
	echo ""
	echo "Script to revoke the privileges on either a URI, database or table(s) from a given role as specified in the .lst file"
	echo "Usage: $0 role_privileges_file [keytab_file] [kerberos_principal]"
	echo "e.g. ./revokePrivilege.sh role_privileges.lst sentry.keytab NPDSVC.Cloudera.Sent"
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

host='ukgs2hmn01.cwglobal.local'
port='10000'
realm='CWGLOBAL.LOCAL'
trustStore="${JAVA_HOME}/jre/lib/security/cacerts"
trustStorePass="changeit"

beelineConnectionString="beeline -u jdbc:hive2://${host}:${port}/default;principal=hive/${host}@${realm};saslQop=auth;ssl=true;sslTrustStore=${trustStore};trustStorePass=${trustStorePass} --outputformat=csv2 --silent=true --showHeader=false"
commands=""

while IFS=' ' read role accessLevel object tablePattern
do
	if [ -z $tablePattern ];
	then
		if [[ $object =~ ^.*://.*$ ]];
		then
			# Object is a URI, so revoke privilege to URI
			commands="${commands}REVOKE ${accessType} ON URI ${object} FROM ROLE ${role};"
		else
			# Object is a database, so revoke privilege to database
			commands="${commands}REVOKE ${accessType} ON DATABASE ${object} FROM ROLE ${role};"
		fi
	else
		# There is a table pattern included, so apply privilege to tables
		tableQuery="USE ${object}; SHOW TABLES LIKE '${tablePattern}'"
		tables=$(${beelineConnectionString} -e "${tableQuery}")
		commands="${commands}USE ${object};"
		for table in ${tables}
		do
			commands="${commands}REVOKE ${accessType} ON TABLE ${table} FROM ROLE ${role};"
		done
	fi
done < $rolePrivilegesFile

${beelineConnectionString} -e "${commands}"

if [[ $? -ne 0 ]];
then
	echo "Failed to successfully revoke privileges" 1>&2
	exit 1
fi
