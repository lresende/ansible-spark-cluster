
# Requirements

You will need a driver machine with ansible installed and a clone of the current repository:

* If you are running on cloud (public/private network)
** Install ansible on the edge node (with public ip)
* if you are running on private cloud (public network access to all nodes)
** Install ansible on your laptop and drive the deployment from it


# Available Components

* **Common**  Deploys Java
* **HDFS**

* **Spark**

* **Anaconda**

* **IOP 4.25 (IBM Open Platform)**

* **Elyra**

ansible-playbook setup-elyra-cluster.yml -i hosts-elyra-cluster
