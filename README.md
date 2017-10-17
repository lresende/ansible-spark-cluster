
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

# Available Components

* **Common**  Deploys Java
* **HDFS** Deploys HDFS filesystem using slave nodes as data nodes
* **Spark** Deploys Spark in Standalone mode using slave nodes for workers
* **ElasticSearch** Deploy ElasticSearch nodes on all slave nodes
* **Anaconda** Deploys Anaconda Python distribution on all nodes
* **IOP** Deploys IBM Open Platform (IOP) 4.2.5
* **Notebook** Deploys Notebook Platform

# Deploying Components

### Create host inventory file

```
[all:vars]
ansible_connection=ssh
#ansible_user=root
#ansible_ssh_private_key_file=~/.ssh/ibm_rsa
gather_facts=True
gathering=smart
host_key_checking=False
install_java=False
install_temp_dir=/tmp/ansible-install
install_dir=/opt
python_version=2

[master]
FQDN   ansible_host=IP

[nodes]
FQDN   ansible_host=IP
FQDN   ansible_host=IP
FQDN   ansible_host=IP
FQDN   ansible_host=IP

```

### Create your playbook

```
- name: ambari setup
  hosts: all
  remote_user: root
  roles:
    - role: common
    - role: iop

- name: anaconda
  hosts: all
  vars:
    anaconda:
      update_path: false
  remote_user: root
  roles:
   - role: anaconda

- name: notebook platform dependencies
  hosts: all
  remote_user: root
  roles:
    - role: notebook

```

### Automatic Deployment of KernelSpecs on Cluster/Worker Nodes
You can optionally deploy kernelspecs for Python, R, and Scala
automatically on the cluster nodes by editing
`spark-cluster-install/roles/notebook/default/main.yml` file such
that `deploy_kernelspecs_to_workers` is set to `true` as shown
below:

```
  deploy_kernelspecs_to_workers: true
```

### Deploy

```
ansible-playbook --verbose <deployment playbook.yml> -i <hosts inventory>
```

Example:

```
ansible-playbook --verbose setup-spark-cluster.yml -i hosts-fyre
```
