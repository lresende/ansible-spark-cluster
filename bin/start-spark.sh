#!/bin/bash

clear

### Stop
if [ -z "$1" -o "$1" = "--stop" ]
then
   echo ">>>>>>>>> "
   echo ">>> Stopping HADOOP and SPARK services..."
   cd $SPARK_HOME && ./sbin/stop-all.sh
   sleep 5s
   cd $HADOOP_HOME && ./sbin/stop-dfs.sh
   sleep 5s
fi

## cleanup
if [ -z "$1" -o "$1" = "--clean" ]
then
   echo ">>> "
   echo ">>> Cleaning up temporary folders..."
   rm -rf $HADOOP_HOME/logs
   rm -rf $SPARK_HOME/logs
   rm -rf $SPARK_HOME/work
fi

if [ -z "$1" -o "$1" = "--update-conf" ]
then
  /opt/bin/sync-conf.sh
fi


## start
if [ -z "$1" -o "$1" = "--start" ]
then
   echo ">>> "
   echo ">>> Starting HADOOP and SPARK services..."
   cd $HADOOP_HOME && ./sbin/start-dfs.sh
   sleep 30s
   cd $SPARK_HOME && ./sbin/start-all.sh
fi
