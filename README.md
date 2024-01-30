# Marauder Data Platform Infrastructure

This repository contains the infrastructure for the Marauder Data Platform. Essentially this consists of a Hadoop - Ambari - Spark - HBase Cluster that can be spun up easily in 
azure. Some useful resources are provided as well such as an easy to use make file for deploying / destroying / managing the platform.

### 1: Cloning the repo.

```
git clone git@gitlab.marauder.net:awb/marauder/infrastructure.git
```

### 2: Setting up the Dependencies

In order to set up the dependencies for the infrastructure one can simply run the following command from the root of the repo.

```
make setup
```

This should install the OS specific dependencies the repo will need.

## 3: Configuring Terraform

In order to login to the azure cli first configure azure to point to the US gov cloud:

```
az cloud set --name AzureUSGovernment
```

Next login like normal and authenticate with two factor

```
az login
```
This will take you through the login steps but at the end it will try to navigate to localhost:XXXXX. Make sure to port forward whatever it is trying to get to from the machine in order to finish the login process. After this we will set the environment variables so that terraform can access what is needed. Make sure to use whatever is found within the "id" field for this. An example is shown below:

```
az account set --subscription 72e52578-1690-4216-a0a4-b062a6713c29
```

Normally here is where we would set a system account that terraform could use for authentication, but due to restrictions on who is hosting the cloud we will just have users authenticate each time they run terraform code.

## 4: Setting up the Platform

We can set up the platform in our provisioned cloud space by running the following command

```
make setup
```

## 5: Tearing down the Platform

We can tear down the platform similarly by running the command

```
make destroy
```

