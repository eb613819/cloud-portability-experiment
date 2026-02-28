# Cloud Portability Experiment
### Multi-Cloud 3-Tier Deployment with OpenTofu and Ansible

This project explores cloud portability and vendor lock-in by deploying identical 3-tier application stacks across multiple cloud providers using reusable Infrastructure as Code and configuration management.

---

# Table of Contents

1. [Overview](#overview)  
   1.1 [Project Goals](#11-project-goals)  
   1.2 [Non-Goals](#12-non-goals)  
   1.3 [Future Work](#13-future-work)  

2. [Tooling](#2-tooling)  
   2.1 [Infrastructure Provisioning](#21-infrastructure-provisioning)  
   2.2 [Configuration Management](#22-configuration-management)  
   2.3 [Chosen Application](#23-chosen-application)  

3. [Architecture](#3-architecture)  
   3.1 [High-Level Design](#31-high-level-design)  
   3.2 [Multi-Cloud Strategy](#32-multi-cloud-strategy)  
   3.3 [3-Tier Breakdown](#33-3-tier-breakdown)  
   3.4 [DNS Design](#34-dns-design)  
   3.5 [Architecture Diagram](#35-architecture-diagram)  

4. [Repository Structure](#4-repository-structure)  

5. [Deployment Workflow](#5-deployment-workflow)  

6. [Development](#6-development)  
   6.1 [Development Environment](#61-development-environment)  
   6.2 [Development Reference Documentation](#62-development-reference-documentation)  
   6.3 [Lab Notes](#63-lab-notes)  

---

# Overview

This project explores cloud portability by deploying the same 3-tier application architecture across three major cloud providers:

- Amazon Web Services (AWS)  
- Microsoft Azure  
- Google Cloud Platform (GCP)  

Infrastructure is provisioned using OpenTofu and configured using Ansible.

The central question explored is:

> Can the same infrastructure and configuration code deploy identical application stacks across multiple cloud providers with minimal changes?

The focus is on abstraction, portability, and reusable automation rather than cloud-specific optimizations.

## 1.1 Project Goals

### Primary Goal

Design provider-agnostic infrastructure and configuration code that:

- Deploys the same 3-tier architecture in AWS, Azure, and GCP  
- Reuses the same OpenTofu module structure  
- Reuses the same Ansible roles  
- Minimizes cloud-specific conditionals  

Switching providers should require modifying configuration values — not rewriting infrastructure modules.

### Secondary Goals

- Maintain strict separation between provisioning and configuration  
- Automatically assign DNS subdomains under `evanbrooks.me`  
- Keep each deployment architecturally identical  
- Build a strong multi-cloud portfolio project  

## 1.2 Non-Goals

To keep the focus on portability:

- No managed cloud-native PaaS databases  
- No proprietary provider services  
- No cross-cloud networking (initial phase)  
- No global load balancing  

The design intentionally avoids cloud-specific shortcuts.

## 1.3 Future Work

### Cross-Cloud MongoDB Replica Set

A potential future enhancement is implementing a distributed MongoDB replica set spanning providers to explore:

- Regional fault tolerance  
- Cross-cloud latency impacts  
- Distributed systems trade-offs  

This would be an educational extension rather than a recommended production design.

---

# 2. Tooling

## 2.1 Infrastructure Provisioning

**OpenTofu** is used to:

- Provision virtual machines  
- Configure networking and firewall rules  
- Assign public IP addresses  
- Output infrastructure values for Ansible  
- Create DNS A records  

Infrastructure code is structured to:

- Abstract provider-specific resources  
- Use reusable modules  
- Maintain consistent variable interfaces across providers  

## 2.2 Configuration Management

**Ansible** is used to:

- Install system dependencies  
- Install MongoDB  
- Install and configure Rocket.Chat  
- Configure reverse proxy  
- Manage system services  

The same Ansible roles are reused across all three cloud environments.  
Only the inventory differs per provider.

## 2.3 Chosen Application

The application deployed in each cloud provider is **Rocket.Chat**.

It was selected because:

- It represents a realistic production-style web application  
- It requires a database (MongoDB)  
- It follows a traditional 3-tier architecture  
- It can be fully automated using configuration management  

Each provider hosts an independent Rocket.Chat deployment.

---

# 3. Architecture

## 3.1 High-Level Design

Each cloud provider hosts an identical 3-tier stack.

Across all providers:

- 3 independent deployments  
- 9 total virtual machines  
- 3 separate DNS endpoints  

Each stack is fully isolated and self-contained.

## 3.2 Multi-Cloud Strategy

Rather than distributing one application across clouds, this project deploys:

- One complete 3-tier stack per provider  

This isolates portability from distributed system complexity and allows clean comparison across platforms.

## 3.3 3-Tier Breakdown

For each provider:

- 1 Frontend VM  
- 1 Backend VM  
- 1 Database VM  

### Frontend Tier
- Public IP  
- Reverse proxy (Nginx)  
- Routes traffic to backend  

### Backend Tier
- Runs Rocket.Chat  
- Handles application logic  

### Database Tier
- Runs MongoDB  
- Private network access only  

## 3.4 DNS Design

Each frontend VM receives a subdomain under:
```
evanbrooks.me
```

Example structure:
- aws.chat.evanbrooks.me  
- az.chat.evanbrooks.me  
- gcp.chat.evanbrooks.me  

OpenTofu automatically creates DNS A records pointing to the appropriate frontend public IP.

## 3.5 Architecture Diagram
```
             +-------------------+
             |   evanbrooks.me   |
             +-------------------+
                      |
       -------------------------------
       |             |               |
      AWS           Azure             GCP
       |             |               |
  +------------+  +------------+  +------------+
  | Frontend   |  | Frontend   |  | Frontend   |
  +------------+  +------------+  +------------+
       |             |               |
  +------------+  +------------+  +------------+
  | Backend    |  | Backend    |  | Backend    |
  +------------+  +------------+  +------------+
       |             |               |
  +------------+  +------------+  +------------+
  | Database   |  | Database   |  | Database   |
  +------------+  +------------+  +------------+
```

Each stack operates independently.

---

# 4. Repository Structure
**PLACEHOLDER**
This section will document:

- Directory layout  
- OpenTofu module structure  
- Provider-specific configuration files  
- Ansible role hierarchy  
- Inventory organization  

(To be completed after initial scaffolding.)

---

# 5. Deployment Workflow

For each provider:

1. Run OpenTofu to provision infrastructure  
2. Capture outputs (IP addresses, hostnames)  
3. Generate Ansible inventory  
4. Run Ansible playbooks  
5. Validate application via DNS endpoint  

The workflow remains identical across providers.

---

# 6. Development

## 6.1 Development Environment

Development is performed in:

- University GNS3 gHost environment  
- Ubuntu Linux  
- VS Code as editor  

All provisioning and configuration commands are executed from this control environment.

## 6.2 Development Reference Documentation

Reference documentation used during development:

- OpenTofu documentation  
- Ansible documentation  
- AWS provider documentation  
- Azure provider documentation  
- GCP provider documentation  
- Rocket.Chat installation documentation  
- MongoDB installation documentation  

## 6.3 Setup
### OpenTofu
#### OpenTofu Installation
These steps were used to install OpenTofu on the gHost running Ubuntu 24.04.3 LTS.
1.) Download the installer script:
  ```bash
  curl -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
  ```
2.) Grant execute permissions and review the script:
  ```bash
  chmod +x install-opentofu.sh && less install-opentofu.sh
  ```
3.) Install using the script:
  ```bash
  ./install-opentofu.sh --install-method standalone
  ```
4.) Check that OpenTofu is installed:
  ```bash
  tofu version
  ```
  ```console
  OpenTofu v1.11.4
  on linux_amd64
  ```
5.) Remove the installer:
  ```bash
  rm -f install-opentofu.sh
  ```

#### Autocomplete
OpenTofu provides tab-completion support for all command names and some command arguments.
Auto-completion was enabled by running the following:
```bash
tofu -install-autocomplete
```

### Ansible
#### Ansible Installation
When installing software on the gHost, we want to be careful to not run full system updates; that can make them unstable and force instructors to reset the gHost to a known good state. We can safely install Ansible on the gHost with the following command:
```bash
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt update
sudo apt install -y ansible software-properties-common python-is-python3 python3-pip python3-tabulate python3-lxml

pip install pydantic==1.9 --break-system-packages
```

### SSH Key
An SSH key was generated to securely access the virtual machines provisioned by Tofu, eliminating the need for password-based authentication.

#### Generate the SSH Key
We generate an SSH key with the following command:
```bash
ssh-keygen -t ed25519 -C "cloud_port_experiment"
```
- `-t` specifies the key type
- `-C` adds a comment to the key
  
**Note**: Use the default file location when prompted and give it a passphrase that you can remember.

A success will show the key's randomart image.

#### Start the SSH Agent
Start the SSH agent and set the necessary environment variables:
```bash
eval $(ssh-agent -s)
```
- `eval` executes the output of the command in the current shell
- `ssh-agent -s` starts the SSH agent and outputs the environment variables

If successful, the agent PID will show:
```bash
Agent pid 2880398
```

#### Add the SSH Key to the Agent
Add the generated private key to the running SSH agent:
```bash
ssh-add ~/.ssh/id_ed25519
```
- `ssh-add` loads a private key into the SSH agent
- `~/.ssh/id_ed25519` is the default private key generated earlier

This will prompt for the key's passphrase, then add it to the agent:
```bash
Identity added: /home/itsvm/.ssh/id_ed25519 (cloud_port_experiment)
```

#### Verify the Key is Loaded
To confirm the key was successfully added:
```bash
ssh-add -l
```
- `-l` lists the fingerprints of all loaded keys

If successful, you should see the key's fingerprint displayed.

#### Start SSH Agent Automatically on Login
So that we do not have to manually start the SSH agent on every login, we can append the commands to `.bashrc`:
```bash
cat >> ~/.bashrc << 'EOF'

# Auto-start ssh-agent if not running
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval $(ssh-agent -s)
    ssh-add ~/.ssh/id_ed25519
fi
EOF
```
- `cat >> ~/.bashrc` appends content to your shell configuration file
- The conditional checks whether the SSH agent is already running
- If not, it starts the agent and loads your key

### Azure
#### Student Azure Account
Azure has a student subscription with $100 of credits. I created a student account using my OHIO credentials.

#### Install Azure CLI
OpenTofu’s AzureRM provider authenticates using the Azure CLI, not the Azure PowerShell (Az) module. The Azure CLI must be installed and available. I installed it with:
```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```
After installation, restart the shell, then verify:
```bash
az version
```

#### Log in to Azure
If you are not logged in, authenticate with:
```bash
az login
```

#### Select the Correct Azure Subscription
If you have access to multiple subscriptions, ensure the correct one is selected:
```powershell
az account set --subscription 00000000-0000-0000-0000-000000000000
```
You can confirm the active subscription again with:
```powershell
az account show
```

### Google Cloud
#### GCP Account
Google accounts must be used for GCP, so I created an account using my OHIO credentials. The free trial gave me $300 free credit, but I did have to put a card on file.

#### Install GCP CLI
OpenTofu's Google provider can authenticate using the Google Cloud CLI (gcloud). I installed it with the following steps.
1.) Install required packages:
```bash
sudo apt-get update
sudo apt-get install ca-certificates gnupg curl
```
2.) Import the Google Cloud public key:
```bash
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
```
3.) Add the gcloud CLI distribution URI as a package source:
```bash
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
```
4.) Update and install the gcloud CLI:
```bash
sudo apt-get update && sudo apt-get install google-cloud-cli
```

#### Initialize and authorize the gcloud CLI
1.) You need a project to initialize the gcloud CLI. One is already created called `my first project` but I used the web interface to change the name to `Cloud Portability Experiment`.
2.) Run the following to initialize the gcloud CLI:
```bash
gcloud init
```
3.) Follow the prompts to authorize and configure, making sure to select your project.
4.) Check the login worked:
```bash
gcloud config list
```

### Amazon Web Services
#### AWS Account
