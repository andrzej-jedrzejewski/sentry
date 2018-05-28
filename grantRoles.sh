#!/bin/bash

if [ $# != 2 ] && [ $# != 4 ];
	then
		echo ""
		echo "Script to grant roles in the .lst file to the specified AD group"
		echo "Usage: $0 role_list_file group [keytab_file] [kerberos_principal]"
		echo ""
		exit 1
fi

roleList=$1
group=$2
keytabfile=$3
principal=$4

if [ $# == 4 ];
then
	kinit -kt $keytabfile $principal
fi

host="ip-172-31-36-0.eu-west-1.compute.internal"
port="10000"
realm="ANDRZEJ.COM"

beelineConnectionString="beeline -u jdbc:hive2://${host}:${port}/default;principal=hive/${host}@${realm}"

grantRoleCommands=""

while IFS="," read role
do
	grantRoleCommands="${grantRoleCommands}GRANT ROLE ${role} TO GROUP ${group};"
done < $roleList

${beelineConnectionString} -e "${grantRoleCommands}"

if [[ $? -ne 0 ]];
then
	echo "Failed to successfully grant roles" 1>&2
	exit 1
fi
