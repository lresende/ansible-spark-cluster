
This repository defines multiple ansible roles to help deploying different modes of a Spark cluster and
Data Science Platform based on Anaconda and Jupyter Notebook stack

# Requirements

You will need a driver machine with ansible installed and a clone of the current repository:

* If you are running on cloud (public/private network)
  * Install ansible on the edge node (with public ip)
* if you are running on private cloud (public network access to all nodes)
  * Install ansible on your laptop and drive the deployment from it

### Installing Ansible on RHEL

```
curl -O https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo rpm -i epel-release-latest-7.noarch.rpm
sudo yum update -y
sudo yum install -y  ansible
```

### Installing Ansible on Mac

* Install Annaconda
* Use pip install ansible

```
pip install --upgrade ansible
```

### Updating Ansible configuration

In order to have variable overriding from host inventory, please add the following configuration into your ~/.ansible.cfg file

```
[defaults]
host_key_checking = False
hash_behaviour = merge
```

### Supported/Tested Platform

* RHEL 7.x
* Ansible 2.3.1.0
  * Ansible 2.3.0.0 seems to have a bug with conditional when which is used in some roles


# Defining your cluster deployment metadata (host inventory)

Ansible uses 'host inventory' files to define the cluster configuration, nodes, and groups of nodes
that serves a given purpose (e.g. master node).

Below is a host inventory sample definition:

```
[all:vars]
ansible_connection=ssh
#ansible_user=root
#ansible_ssh_private_key_file=~/.ssh/ibm_rsa
gather_facts=True
gathering=smart
host_key_checking=False
install_java=True
install_temp_dir=/tmp/ansible-install
install_dir=/opt
python_version=2

[master]
lresende-elyra-node-1   ansible_host=IP   ansible_host_id=1

[nodes]
lresende-elyra-node-2   ansible_host=IP   ansible_host_id=2
lresende-elyra-node-3   ansible_host=IP   ansible_host_id=3
lresende-elyra-node-4   ansible_host=IP   ansible_host_id=4
lresende-elyra-node-5   ansible_host=IP   ansible_host_id=5

```

Some specific configurations are:

* install_java=True : install/update java 8
* install_temp_dir=/tmp/ansible-install : temporary folder used for install files
* install_dir=/opt : where packages are installed (e.g. Spark)
* python_version=2 : python version to use, influence which version of Anaconda to download

**Note:** ansible_host_id is only used when deploying a "Spark Standalone" cluster.

# Deploying Spark using Ambari and HDP distribution

In this scenario, a minimal blueprint is used to deploy the required components
to run YARN and Spark.

### Related ansible roles

* **Common**  Deploys Java and common dependencies
* **Ambari** Deploys Ambari cluster with HDP Stack

### Deployment playbook

The sample playbook below can be used to deploy an Spark using an HDP distribution

```
- name: ambari setup
  hosts: all
  remote_user: root
  roles:
    - role: common
    - role: ambari
```

### Deploying

```
ansible-playbook --verbose <deployment playbook.yml> -i <hosts inventory>
```

Example:

```
ansible-playbook --verbose setup-ambari.yml -i hosts-fyre -c paramiko
```

# Deploying Spark standalone

In this scenario, a Standalone Spark cluster will be deployed with a few optional components.

### related ansible roles

* **Common**  Deploys Java and common dependencies
* **HDFS** Deploys HDFS filesystem using slave nodes as data nodes
* **Spark** Deploys Spark in Standalone mode using slave nodes as workers
* **Spark-CLuster-Admin** Utility scripts for managing Spark cluster
* **ElasticSearch** Deploy ElasticSearch nodes on all slave nodes
* **Zookeeper** Depoys Zookeeper on all nodes (required by Kafka)
* **Kafka** Deploy Kafka nodes on all slave nodes

### Deployment playbook

```
- name: spark setup
  hosts: all
  remote_user: root
  roles:
    - role: common
    - role: hdfs
    - role: spark
    - role: spark-cluster-admin

```

**Note:** When deploying Kafka, the Zookeeper role is required

### Deploying


```
ansible-playbook --verbose <deployment playbook.yml> -i <hosts inventory>
```

Example:

```
ansible-playbook --verbose setup-spark-standalone.yml -i hosts-fyre -c paramiko
```

# Deploying Data Science Platform components

In this scenario, an existing Spark cluster is updated with necessary components to build a data science platform
based on Anaconda and Jupyter Notebook stack.

### Related ansible roles

* **Anaconda** Deploys Anaconda Python distribution on all nodes
* **Notebook** Deploys Notebook Platform

### Deployment playbook

```
- name: anaconda
  hosts: all
  vars:
    anaconda:
      update_path: true
  remote_user: root
  roles:
   - role: anaconda

- name: notebook platform dependencies
  hosts: all
  vars:
    notebook:
      use_anaconda: true
      deploy_kernelspecs_to_workers: false
  remote_user: root
  roles:
    - role: notebook
```

**Playbook Configuration**

* **use_anaconda**: Flag to identify if anaconda is available and should be used as python package manager
* **deploy_kernelspecs_to_workers**: optionally deploy kernelspecs for Python, R, and Scala to all nodes
