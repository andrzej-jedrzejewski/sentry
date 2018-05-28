# sentry

connection to hive:
kinit -kt /run/cloudera-scm-agent/process/109-hive-HIVESERVER2/hive.keytab hive/ip-172-31-36-0.eu-west-1.compute.internal@ANDRZEJ.COM
beeline !connect jdbc:hive2://ip-172-31-36-0.eu-west-1.compute.internal:10000/default;principal=hive/_HOST@ANDRZEJ.COM
