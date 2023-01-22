# How to Deploy My Own Node/Express App to Azure AKS

* https://learn.microsoft.com/en-us/azure/aks/learn/quick-kubernetes-deploy-cli

---

## Write the application

Create the Node/Express application. Test it to ensure it is working locally.

## Build Docker Image 

Build command:

`docker build --tag node-express-docker .`

Start the app using Docker Compose to test it is working:

`docker compose up`

Then access it locally at http://localhost:3000 as this is the port forwarding we added to the config.

List Docker images

`docker images`

Push to Docker Hub

`docker push node-express-docker:latest`



## Setup Azure CLI (unless already done)
There are a few ways to run this.
1. You could install it on your local machine. 
1. You can run it from a docker container: `docker run -it mcr.microsoft.com/azure-cli`

### Docker Apple Silicon
Running from Docker is not an option on Apple silicon. A Google search resulted in an issue opened Jan 2022 requesting this feature, but it was never completed. If you download the image, it will give the following error:
```
WARNING: The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested
```

### Docker Non-Apple Silicon
Run the following to download the image and start up a container. You run the commands from within that contain.

`docker run -it mcr.microsoft.com/azure-cli`

### Install Locally without HomeBrew
I found a way to install this locally on MacOS without HomeBrew. As it is basically a Python package, just load the Python environment, install using PIP, and run it from there.


```
mkdir $HOME/dev/azure-cli && cd $HOME/dev/azure-cli
source venv/bin/activate
pip install --upgrade pip
pip install azure-cli
```

Then I made an `az` alias in my .dotfiles that point to this location. You should be able to run it normally now.



## Deploy Application to AKS

### Establish azure-cli connection to required subscription
First time running `az`, you will need to run configure first.

`az configure`

From time to time, you may need to login. Usually, you do this once and it should remember.

`az login`

You may need to change which subscription to use. I am using one called `akd-playground` for this purpose. To change it run:

`az account set --subscription aks-playground`

Then you can run `az account show` and confirm it switched correctly.

Verify Microsoft.OperationsManagement and Microsoft.OperationalInsights providers are registered on your subscription. These are Azure resource providers required to support Container insights. To check the registration status, run the following commands:
```
az provider show -n Microsoft.OperationsManagement -o table
az provider show -n Microsoft.OperationalInsights -o table
```

If they are not registered, register Microsoft.OperationsManagement and Microsoft.OperationalInsights using the following commands:
```
az provider register --namespace Microsoft.OperationsManagement
az provider register --namespace Microsoft.OperationalInsights
az provider register --namespace Microsoft.insights
az provider register --namespace Microsoft.ContainerService
```

** For the above, I used Azure Cloud Shell on the portal, ad you needed to run as administrative privledges.

### Create a Resource Group to store the application

```
az group create --name node-express-demo-rg --location eastus2
```

### Create the AKS cluser by running:

```
az aks create -g node-express-demo-rg -n node-express-demo-aksc --enable-managed-identity --node-count 1 --enable-addons monitoring --enable-msi-auth-for-monitoring  --generate-ssh-keys
```

### Connect to the AKS Cluster

Run the following to install `kubectl` locally. You'll use this to work on the Kubernetes cluster.

```
az aks install-cli
```

** I was getting permission errors when running this. But I think I have kubectl already from Docker, so going to try with that.

### Download kubectl credentials 

az aks get-credentials --name node-express-demo-aksc --overwrite-existing --resource-group node-express-demo-rg 

### Verify kubectl connectivity

```
kubectl get nodes
```

It listed the running nodes, so everything is working this far!

## Deploy Application to AKS Cluster

Crate a manifest.yaml file (I called mine azure-ui-manifest.yaml), and put in the example text from https://learn.microsoft.com/en-us/azure/aks/learn/quick-kubernetes-deploy-cli. However, I removed the back-end section, only keep the front-end, because I don't have any cache/database layer. It is purely an API.

### Deploy the app

Run the following to push the manifest file to the AKS cluser created earlier.
```
kubectl apply -f azure-ui-manifest.yaml
```

### Get External IP to Test
Run this and wait for the external IP to appear. Use that with :3000 to test the API is working.

```
kubectl get service aks-node-express-demo --watch
```

That's it! You should have a working Node/Express app, bundled via an image from Docker Hub, running in an AKS kubernetes cluster deployed on Azure! Congratulations on your first step!


### Destr
To ensure you are not getting changed, you can destroy the resource group.
```
az group delete --name node-express-demo-rg --yes --no-wait
```