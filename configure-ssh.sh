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
  echo "  configure-ssh.sh [option]"
  echo " "
  echo "  Configure passwordless SSH between the cluster nodes"
  exit 1
fi

HOSTS=(169.45.103.134 169.45.103.144 169.45.103.145 169.45.103.130 169.45.101.87)

CLUSTER_MASTER=${HOSTS[0]}
CLUSTER_NODES=${HOSTS[@]:1}
CLUSTER_SIZE=${#HOSTS[@]}
NODES=("${HOSTS[@]:1}") ##Workaround to get node size
CLUSTER_NODE_SIZE=${#NODES[@]}

echo ">>> Cluster Configuration "
echo "Master Node..: $CLUSTER_MASTER"
echo "Data Nodes...: $CLUSTER_NODES"
echo ">>> "


## Configure Passwordless SSH
if [ "$1" = "--all"  -o  "$1" = "--ssh"  ]
then
  for i in ${HOSTS[@]}; do
    cat ~/.ssh/ibm_rsa | ssh ${i} "cat > /home/lresende/.ssh/ibm_rsa"
    ssh ${i} 'chown lresende:lresende /home/lresende/.ssh/ibm_rsa'
    ssh ${i} 'chmod 600 /home/lresende/.ssh/ibm_rsa'

    cat ssh/config | ssh ${i} "cat > /home/lresende/.ssh/config"
    ssh ${i} 'chown lresende:lresende /home/lresende/.ssh/config'
    ssh ${i} 'chmod 600 /home/lresende/.ssh/config'

    echo "##### User customizations " | ssh ${i} "cat >> /home/lresende/.bash_profile"
    echo "alias cd..='cd ..'" | ssh ${i} "cat >> /home/lresende/.bash_profile"
    echo "alias ls='ls -la'" | ssh ${i} "cat >> /home/lresende/.bash_profile"
  done
fi
