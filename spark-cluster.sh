#!/bin/bash
#
# Copyright 2016 Luciano Resende
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

ROOT=`dirname $0`
ROOT=`cd $ROOT; pwd`

if [ -z "$1" ]
then
  echo "Usage:"
  echo "  spark-cluster.sh [option]"
  echo " "
  echo "    -uninstall : uninstall an Spark Standalone cluster"
  echo "    -install   : install Hadoop and Spark on a Spark Standalone cluster"
  echo " "
  echo " "
  echo "Pre-requisites: "
  echo " "
  echo "  - Passwordless ssh must be enabled between the cluster nodes"
  exit 1
fi

INSTALL_FOLDER=/home/lresende/opt
JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
HADOOP_VERSION=2.7.2
HADOOP_HOME=$INSTALL_FOLDER/hadoop-$HADOOP_VERSION
SPARK_VERSION=1.6.1
SPARK_HOME=$INSTALL_FOLDER/spark-$SPARK_VERSION-bin-hadoop2.6

LOCALHOST="$(/bin/hostname -f)"
HOSTS=("$LOCALHOST")
#HOSTS=(169.45.103.134 169.45.103.144 169.45.103.145 169.45.103.130 169.45.101.87)
HOSTS=(169.45.103.134)

CLUSTER_MASTER=${HOSTS[0]}
CLUSTER_NODES=${HOSTS[@]:1}
CLUSTER_SIZE=${#HOSTS[@]}
NODES=("${HOSTS[@]:1}") ##Workaround to get node size
CLUSTER_NODE_SIZE=${#NODES[@]}

echo ">>> Cluster Configuration "
echo "Master Node..: $CLUSTER_MASTER"
echo "Data Nodes...: $CLUSTER_NODES"
echo ">>> "

## Cleanup
if [ "$1" = "--all"  -o  "$1" = "--uninstall"  ]
then
  for i in ${HOSTS[@]}; do
    ssh ${i} "cd $HADOOP_HOME && ./sbin/stop-all.sh"
    ssh ${i} "cd $SPARK_HOME && ./sbin/stop-all.sh"
    ssh ${i} "rm  INSTALL_FOLDER/hadoop"
    ssh ${i} "rm -rf $HADOOP_HOME"
    ssh ${i} "rm -rf /tmp/hadoop"
    ssh ${i} "rm  INSTALL_FOLDER/spark"
    ssh ${i} "rm -rf $SPARK_HOME"
    ssh ${i} "rm -rf /tmp/spark"
  done
fi

## Install Hadop
if [ "$1" = "--all"  -o  "$1" = "--install"  ]
then
  for i in ${HOSTS[@]}; do
    ssh ${i} "mkdir -p $INSTALL_FOLDER"
    ssh ${i} "cd $INSTALL_FOLDER && wget https://dist.apache.org/repos/dist/release/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz"
    ssh ${i} "cd $INSTALL_FOLDER && tar -xvf hadoop-$HADOOP_VERSION.tar.gz"
    ssh ${i} "cd $INSTALL_FOLDER && ln -s $HADOOP_HOME hadoop"
    ssh ${i} "cd $INSTALL_FOLDER && rm -rf hadoop-$HADOOP_VERSION.tar.gz"
    
    cat hadoop/etc/core-site.xml | ssh ${i} "cat > $HADOOP_HOME/etc/hadoop/core-site.xml"
    cat hadoop/etc/hadoop-env.sh | ssh ${i} "cat > $HADOOP_HOME/etc/hadoop/hadoop-env.sh"
    cat hadoop/etc/hdfs-site.xml | ssh ${i} "cat > $HADOOP_HOME/etc/hadoop/hdfs-site.xml"
    cat hadoop/etc/mapred-site.xml | ssh ${i} "cat > $HADOOP_HOME/etc/hadoop/mapred-site.xml"
    cat hadoop/etc/yarn-site.xml | ssh ${i} "cat > $HADOOP_HOME/etc/hadoop/yarn-site.xml"
    
    ssh ${i} "sed -i.bak \"s@hdfs://localhost@hdfs://$CLUSTER_MASTER@g\" $HADOOP_HOME/etc/hadoop/core-site.xml"
    
    ssh ${i} "sed -i '/^export JAVA_HOME/ s:.*:export JAVA_HOME=$JAVA_HOME\nexport HADOOP_PREFIX=$HADOOP_HOME\nexport HADOOP_HOME=$HADOOP_HOME\nexport HADOOP_COMMON_HOME=$HADOOP_HOME\nexport HADOOP_HDFS_HOME=$HADOOP_HOME\nexport HADOOP_MAPRED_HOME=$HADOOP_HOME\nexport HADOOP_YARN_HOME=$HADOOP_HOME\nexport HADOOP_CONF_DIR=$HADOOP_HOME\nexport YARN_CONF_DIR=$HADOOP_HOME:'" $HADOOP_HOME/etc/hadoop/hadoop-env.sh
    ssh ${i} "sed -i '/^export HADOOP_CONF_DIR/ s:.*:export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop/:'" $HADOOP_HOME/etc/hadoop/hadoop-env.sh
    ssh ${i} "sed -i '/^export YARN_CONF_DIR/ s:.*:export YARN_CONF_DIR=$HADOOP_HOME/etc/hadoop/:'" $HADOOP_HOME/etc/hadoop/hadoop-env.sh
    
    ssh ${i} "sed -i.bak \"s@localhost:8030@$CLUSTER_MASTER:8030@g\" $HADOOP_HOME/etc/hadoop/yarn-site.xml"
    ssh ${i} "sed -i.bak \"s@localhost:8031@$CLUSTER_MASTER:8031@g\" $HADOOP_HOME/etc/hadoop/yarn-site.xml"
    ssh ${i} "sed -i.bak \"s@localhost:8032@$CLUSTER_MASTER:8032@g\" $HADOOP_HOME/etc/hadoop/yarn-site.xml"
  done  
fi