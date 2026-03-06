# Cloud Portability Experiment
### Portable 3-Tier Deployment Across Multiple Cloud Providers Using OpenTofu and Ansible

This project explores cloud portability and vendor lock-in by deploying identical 3-tier application stacks across multiple cloud providers using reusable Infrastructure as Code (IaC) and configuration management.

---

# Table of Contents

- 1. [Overview](#1-overview)
  - [1.1 Project Goals](#11-project-goals)
  - [1.2 Non-Goals](#12-non-goals)
  - [1.3 Future Work](#13-future-work)

2. [Tooling](#2-tooling)
  - [2.1 Infrastructure Provisioning](#21-infrastructure-provisioning)
  - [2.2 Configuration Management](#22-configuration-management)
  - [2.3 Chosen Application](#23-chosen-application)

3. [Architecture](#3-architecture)
  - [3.1 High-Level Design](#31-high-level-design)
  - [3.2 Multi-Cloud Strategy](#32-multi-cloud-strategy)
  - [3.3 3-Tier Breakdown](#33-3-tier-breakdown)
  - [3.4 DNS Design](#34-dns-design)
  - [3.5 Architecture Diagram](#35-architecture-diagram)

4. [Repository Structure](#4-repository-structure)

5. [Deployment Workflow](#5-deployment-workflow)

6. [Development](#6-development)
  - [6.1 Development Environment](#61-development-environment)
  - [6.2 Development Reference Documentation](#62-development-reference-documentation)
  - [6.3 Setup](#63-setup)
    - [OpenTofu](#opentofu)
    - [Ansible](#ansible)
    - [SSH Key](#ssh-key)
    - [Azure](#azure)
    - [Google Cloud](#google-cloud)
    - [Amazon Web Services](#amazon-web-services)

7. [Provider-Native Single VM Deployment (No Abstraction)](#7-provider-native-single-vm-deployment-no-abstraction)
  - [7.1 Directory Structure](#71-directory-structure)
  - [7.2 Provider Configuration](#72-provider-configuration)
  - [7.3 Networking Layer](#73-networking-layer)
  - [7.4 Public IP Allocation](#74-public-ip-allocation)
  - [7.5 Security Model (SSH Access)](#75-security-model-ssh-access)
  - [7.6 SSH Key Injection](#76-ssh-key-injection)
  - [7.7 Virtual Machine Resource](#77-virtual-machine-resource)
  - [7.8 Deployment Lifecycle](#78-deployment-lifecycle-identical-across-providers)
  - [7.9 Comparative Observations](#79-comparative-observations)

8. [Cloud-Agnostic Deployment of a Single VM](#8-cloud-agnostic-deployment-of-a-single-vm)
  - [8.1 Motivation for a Unified Interface](#81-motivation-for-a-unified-interface)
  - [8.2 Directory Structure](#82-directory-structure)
  - [8.3 Portable Interface](#83-portable-interface)
  - [8.4 Provider-specific Modules](#84-provider-specific-modules)
  - [8.5 Deployment Lifecycle](#85-deployment-lifecycle)

9. [Extending the Architecture to Three Tiers](#9-extending-the-architecture-to-three-tiers)

10. [Cloud-Agnostic Three VM Deployment](#10-cloud-agnostic-three-vm-deployment)
  - [10.1 Architectural Approach](#101-architectural-approach)
  - [10.2 Directory Structure](#102-directory-structure)
  - [10.3 Deployment Lifecycle](#103-deployment-lifecycle)
  - [10.4 Design Benefits](#104-design-benefits)
  - [10.5 Transition to Configuration Management](#105-transition-to-configuration-management)

11. [Automated Application Deployment with Ansible](#11-automated-application-deployment-with-ansible)
  - [11.1 Network Access Model](#111-network-access-model)
  - [11.2 Ansible Role Structure](#112-ansible-role-structure)
  - [11.3 Dynamic Inventory Generation](#113-dynamic-inventory-generation)
  - [11.4 Playbook Execution](#114-playbook-execution)
  - [11.5 Resulting Application Deployment](#115-resulting-application-deployment)

12. [Integrated Provisioning and Configuration Workflow](#12-integrated-provisioning-and-configuration-workflow)
  - [12.1 Orchestrating the Full Deployment](#121-orchestrating-the-full-deployment)
  - [12.2 Waiting for Infrastructure Readiness](#122-waiting-for-infrastructure-readiness)
  - [12.3 Automatic Ansible Invocation](#123-automatic-ansible-invocation)
  - [12.4 End-to-End Deployment Lifecycle](#124-end-to-end-deployment-lifecycle)
    
---

# 1. Overview

This project explores cloud portability by deploying the same 3-tier application architecture across three major cloud providers:

- Amazon Web Services (AWS)
- Microsoft Azure
- Google Cloud Platform (GCP)

Rather than running all deployments simultaneously, the project maintains **a single active deployment at a time**. Changing the target provider triggers OpenTofu to destroy the existing infrastructure and recreate the stack in the selected cloud environment.

This approach allows the same infrastructure and configuration code to be reused across providers while avoiding the cost and complexity of maintaining multiple concurrent environments.

The central question explored is:

> Can the same infrastructure and configuration code deploy identical application stacks across multiple cloud providers with minimal changes?

The focus is on abstraction, portability, and reusable automation rather than cloud-specific optimizations. The system therefore demonstrates **redeployment portability rather than simultaneous multi-cloud operation**.

## 1.1 Project Goals

### Primary Goal

Design provider-agnostic infrastructure and configuration code that:

- Deploys the same 3-tier architecture in AWS, Azure, and GCP using the same codebase.
- Reuses the same OpenTofu module structure  
- Reuses the same Ansible roles  
- Minimizes cloud-specific conditionals  

Switching providers should require modifying configuration values, not rewriting infrastructure modules. The target cloud provider can be changed by modifying configuration variables and re-running the OpenTofu deployment.

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

### Cross-Cloud Database Replication (Educational)
A potential future enhancement is implementing a distributed database setup (e.g., MySQL replication) across cloud providers to explore:
- Fault tolerance across multiple regions
- Cross-cloud latency and performance considerations
- Trade-offs in distributed systems design

This setup is intended purely for educational purposes and is **not a recommended approach for production deployments**.

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

**Ansible** is used to configure the virtual machines after they are provisioned by OpenTofu.

The configuration process installs and configures:

- Nginx web server
- PHP-FPM runtime
- WordPress application
- MariaDB database server
- Required system packages
- TLS certificates using Let's Encrypt

Each application tier is implemented as an Ansible role:

- `web` – installs Nginx and configures the reverse proxy
- `app` – installs PHP-FPM and WordPress
- `db` – installs and configures MariaDB

These roles are applied to the appropriate hosts using a dynamically generated inventory created by OpenTofu.

The same Ansible roles are reused across all cloud providers. Only the inventory values differ.

## 2.3 Chosen Application

The application deployed in each cloud provider is **WordPress**.

WordPress was selected because:

- It represents a realistic production-style web application
- It requires a relational database (MySQL or MariaDB)
- It follows a traditional 3-tier architecture (web server, application runtime, database)
- It can be fully automated using configuration management

Although WordPress is often deployed on a single server, separating the tiers provides a clear demonstration of infrastructure provisioning, network design, and configuration management.

---

# 3. Architecture

## 3.1 High-Level Design

The system deploys a **single 3-tier application stack at a time** consisting of:

- 1 Web server
- 1 Application server
- 1 Database server

The infrastructure is designed so that the **same OpenTofu and Ansible code can deploy this stack in AWS, Azure, or GCP**.

Switching providers replaces the existing infrastructure with an equivalent deployment in the selected cloud environment.

This allows the project to evaluate portability while keeping the infrastructure footprint small and cost-efficient.

## 3.2 Multi-Cloud Strategy

Rather than operating a distributed application across multiple providers, this project focuses on **redeployment portability**.

The infrastructure is designed so that:

- The same OpenTofu modules can deploy infrastructure in any provider
- The same Ansible roles configure the application stack
- Switching providers requires only configuration changes

When the target provider changes, OpenTofu destroys the existing infrastructure and recreates the stack in the new provider.

This strategy isolates the challenge of **cloud portability** from the complexity of **multi-cloud distributed systems**.

## 3.3 3-Tier Breakdown

For the active deployment:

- 1 Web VM
- 1 Application VM
- 1 Database VM

### Web Tier

- Public IP
- Runs **Nginx**
- Terminates TLS
- Acts as a reverse proxy to the application tier
- Serves as the SSH jump host for administrative access

### Application Tier

- Runs **PHP-FPM**
- Hosts the **WordPress** application files
- Processes dynamic requests forwarded from the web tier

### Database Tier

- Runs **MariaDB**
- Stores WordPress data
- Accessible only from the application tier via the private network

## 3.4 DNS Design

The deployed application receives a subdomain under:
```
evanbrooks.me
```

Example structure:
- blog.evanbrooks.me  
- wp.evanbrooks.me  

OpenTofu automatically creates DNS A records pointing to the appropriate frontend public IP.

## 3.5 Architecture Diagram
```
           +-------------------+
           |   evanbrooks.me   |
           +-------------------+
                    |
                Active Deployment
                    |
          ------------------------
          |          |           |
        Web        App        Database
        (VM)       (VM)        (VM)

      Infrastructure provisioned in:
      AWS  |  Azure  |  GCP
      (selected at deployment time)
```

---

# 4. Repository Structure
The repository is structured as follows:
```bash
cloud-portability-experiment/
├── sandbox/           # Code for development iterations
└── three-tier-app/    # Code for finished project
     ├── ansible.tf              # Runs ansible playbook
     ├── dns.tf                  # Configure namecheap records through API
     ├── interface-vars.tf       # Interface specific variables
     ├── interface.auto.tfvars   # Interface variable values
     ├── inventory.tf            # Generates ansible inventory
     ├── locals.tf               # Defines locals (IPs)
     ├── main.tf                 # Module calls (aws_vm, azure_vm, gcp_vm) with counts
     ├── module-vars.tf          # Module specific variables
     ├── module.auto.tfvars      # Module variable values
     ├── namecheap-vars.tf       # Namecheap variables (username, api key, client ip, domain)
     ├── namecheap.auto.tfvars   # gitignored namecheap variable values
     ├── output.tf               # Outputs
     ├── providers.tf            # Providers
     ├── ssh.tf                  # Checks SSH is available
     ├── versions.tf             # Versions
     ├── .gitignore
     ├── modules/
     │   ├── aws/
     │   │   ├── main.tf
     │   │   ├── aws-vars.tf
     │   │   └── aws-out.tf
     │   ├── az/
     │   │   ├── main.tf
     │   │   ├── az-vars.tf
     │   │   └── az-out.tf
     │   └── gcp/
     │       ├── main.tf
     │       ├── gcp-vars.tf
     │       └── gcp-out.tf
     └── ansible/
         ├── site.yml
         ├── ansible.cfg
         ├── inventory.yml       # gitignored - generated by tofu
         ├── group_vars/
         │   └── all.yml
         └── roles/
             ├── web/
             │   ├── tasks/
             │   │   └── main.yml
             │   └── templates/
             │       ├── nginx.conf1.j2
             │       └── nginx.conf2.j2
             ├── app/
             │   ├── tasks/
             │   │   └── main.yml
             │   └── templates/
             │       └── wp-config.php.j2
             └── db/
                  └── tasks/
                     └── main.yml
```

---

# 5 Deployment Workflow

The deployment process follows a consistent workflow regardless of the target provider.

1. Run OpenTofu to provision infrastructure
2. Select the desired cloud provider
3. OpenTofu waits for SSH availability
4. Ansible is automatically invoked to configure the servers
5. The WordPress site becomes available at the configured DNS endpoint

If the provider configuration changes, OpenTofu replaces the existing infrastructure with an equivalent deployment in the new provider.

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

- [OpenTofu documentation](https://opentofu.org/docs/)
- Ansible documentation  
- AWS provider documentation
- [AWS CLI installation documentation](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- Azure provider documentation
- [Azure CLI installation documentation](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux?view=azure-cli-latest&pivots=apt)
- GCP provider documentation
- [GCP CLI installation docs](https://docs.cloud.google.com/sdk/docs/install-sdk#deb)

## 6.3 Setup
### OpenTofu
#### OpenTofu Installation
These steps were used to install OpenTofu on the gHost running Ubuntu 24.04.3 LTS.
1. Download the installer script:
  ```bash
  curl -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
  ```
2. Grant execute permissions and review the script:
  ```bash
  chmod +x install-opentofu.sh && less install-opentofu.sh
  ```
3. Install using the script:
  ```bash
  ./install-opentofu.sh --install-method standalone
  ```
4. Check that OpenTofu is installed:
  ```bash
  tofu version
  ```
  ```console
  OpenTofu v1.11.4
  on linux_amd64
  ```
5. Remove the installer:
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
The `azurerm` provider will automatically use the active Azure CLI login context.
#### Student Azure Account
Azure has a student subscription with $100 of credits. I created a student account using my OHIO credentials.

#### Install Azure CLI
OpenTofu’s `azurerm` provider authenticates using the Azure CLI, not the Azure PowerShell (Az) module. The Azure CLI must be installed and available. I installed it with:
```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```
After installation, restart the shell, then verify:
```bash
az version
```
[Azure CLI installation documentation.](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux?view=azure-cli-latest&pivots=apt)

#### Log in to Azure
If you are not logged in, authenticate with:
```bash
az login
```

#### Select the Correct Azure Subscription
If you have access to multiple subscriptions, ensure the correct one is selected:
```bash
az account set --subscription 00000000-0000-0000-0000-000000000000
```
You can confirm the active subscription again with:
```bash
az account show
```

### Google Cloud
The `google` provider will automatically use the Application Default Credentials generated below.
#### GCP Account
Google accounts must be used for GCP, so I created an account using my OHIO credentials. The free trial gave me $300 free credit, but I did have to put a card on file.

#### Install GCP CLI
OpenTofu's `google` provider can authenticate using the Google Cloud CLI (gcloud). I installed it with the following steps.
1. Install required packages:
```bash
sudo apt-get update
sudo apt-get install ca-certificates gnupg curl
```
2. Import the Google Cloud public key:
```bash
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
```
3. Add the gcloud CLI distribution URI as a package source:
```bash
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
```
4. Update and install the gcloud CLI:
```bash
sudo apt-get update && sudo apt-get install google-cloud-cli
```
[GCP CLI installation documentation.](https://docs.cloud.google.com/sdk/docs/install-sdk#deb)

#### Initialize and authorize the gcloud CLI
1. You need a project to initialize the gcloud CLI. A default project is automatically created, but I renamed it via the web console to `Cloud Portability Experiment` for clarity.
2. Run the following to initialize the gcloud CLI:
```bash
gcloud init
```
3. Follow the prompts to authorize and configure, making sure to select your project.
4. Check the login worked:
```bash
gcloud config list
```

#### Enable Application Default Credentials
The OpenTofu `google` provider uses ADC. Enable them with:
```bash
gcloud auth application-default login
```
This stores credentials locally in:
```bash
~/.config/gcloud/application_default_credentials.json
```
The provider will automatically use these credentials.
You can verify authentication with:
```bash
gcloud auth list
```
At this point, OpenTofu can authenticate to GCP using your logged-in CLI context.

#### Enable Compute Engine API
In order to create and run virtual machines, the `Compute Engine API` needs to be enabled in the project. This can be done from the Google Cloud Console.

### Amazon Web Services
The `aws` provider automatically reads credentials from the AWS CLI configuration files.
#### AWS Account
AWS offers a free tier for new accounts. I created an AWS account dedicated to this experiment with my OHIO credentials and enabled the free tier.

#### Install AWS CLI
To install AWS, use the following commands:
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```
Verify installation:
```bash
aws --version
```
[AWS CLI installation docs](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

#### Login and Configure AWS CLI
AWS does not use an interactive browser login like Azure or GCP for automation. Instead, credentials are configured locally. From the AWS Console:
1. Go to IAM → Users
2. Create a user
3. Attach `AdministratorAccess` policy (for lab simplicity)
4. After creation, generate an Access Key for the user
5. Copy the Access Key ID and Secret Access Key
Then configure locally:
```bash
aws configure
```
Provide:
- Access Key ID
- Secret Access Key
- Default region (e.g., `us-east-2`)
- Output format (json)
This creates:
```bash
~/.aws/credentials
~/.aws/config
```
The OpenTofu `aws` provider automatically reads from these files. You can verify authentication with:
```bash
aws sts get-caller-identity
```
If successful, it will return your account and user ARN. At this point, OpenTofu can authenticate to AWS.

---

# 7. Provider-Native Single VM Deployment (No Abstraction)

Before attempting to design a provider-agnostic module structure, it was necessary to understand how each provider models core infrastructure primitives. Each cloud provider was implemented independently using a fully provider-native OpenTofu configuration. Each provider has its own `main.tf`, with no shared modules or variables.

The goal of this phase was to:
- Create the closest possible equivalent infrastructure in Azure, AWS, and GCP
- Understand provider-specific networking requirements
- Validate SSH access using the same public key
- Observe structural differences before abstraction

## 7.1 Directory Structure

The provider-native configurations are located in:
```bash
sandbox/
   └── single_vm_native/
       ├── az/
       │   └── main.tf
       ├── aws/
       │   └── main.tf
       └── gcp/
           └── main.tf
```
Each directory contains a standalone `main.tf` capable of provisioning:
- A virtual network
- A subnet
- Public internet access
- SSH access (port 22 open)
- A single Ubuntu 24.04 VM
- An output exposing the public IP and SSH command

## 7.2 Provider Configuration

Each provider requires a different initialization model:

### Azure
- Requires `azurerm` provider
- Requires a resource group
- Region defined via resource group location
   - Using `northcentralus`

### AWS
- Requires `aws` provider
- Region defined directly in provider block
   - Using `us-east-2`

### GCP
- Requires `google` provider
- Requires project
- Region and zone defined directly in provider block
   - Using `us-central1` and `us-central1-a` 

### **Key Differences**:  
- Azure introduces a mandatory resource group abstraction.  
- GCP requires explicit project and zone.  
- AWS only requires a region.

## 7.3 Networking Layer
All three providers create a network with CIDR `10.0.0.0/16` and a subnet `10.0.1.0/24`, but the structure differs significantly.

### Azure
- `azurerm_virtual_network`
- `azurerm_subnet`
- Explicit `azurerm_network_interface`
- Explicit NSG association to NIC

Azure requires more explicit wiring between components.

### AWS
- `aws_vpc`
- `aws_subnet`
- Internet Gateway
- Route Table
- Route Table Association

AWS requires explicit routing configuration for internet access.

### GCP
- `google_compute_network`
- `google_compute_subnetwork`
- Firewall rule

GCP does not require route tables for basic internet access.

### **Key Differences**:

| Concept | Azure | AWS | GCP |
|----------|--------|--------|--------|
| Network object | Virtual Network | VPC | VPC Network |
| Subnet | Explicit | Explicit | Explicit |
| Internet routing | Implicit via public IP | Requires IGW + route table | Implicit |
| NIC object | Required | Implicit in instance | Implicit in instance |

- Azure requires the most explicit network wiring.  
- AWS requires explicit routing configuration.  
- GCP is the most minimal.

## 7.4 Public IP Allocation

Each provider provisions a static public IP.

- Azure: `azurerm_public_ip`
- AWS: Public IP auto-associated to instance
- GCP: `google_compute_address` (static IP resource)

**Key Difference:**
- Azure and GCP treat public IP as a standalone resource.  
- AWS attaches public IP directly to the instance.

## 7.5 Security Model (SSH Access)

All three configurations open TCP port 22 to `0.0.0.0/0`.

### Azure
- `azurerm_network_security_group`
- Associated to NIC

### AWS
- `aws_security_group`
- Attached directly to instance

### GCP
- `google_compute_firewall`
- Applied at network level

### **Key Differences**:

- Azure attaches security at the NIC level.  
- AWS attaches security at the instance level.  
- GCP applies firewall rules at the network level.

This reflects fundamentally different security boundary models.

## 7.6 SSH Key Injection
All three use the same public key:
```bash
~/.ssh/id_ed25519.pub
```
Which can be referenced directly in the `main.tf` using:
```hcl
file("~/.ssh/id_ed25519.pub")
```
However, injection differs:
- Azure: `admin_ssh_key` block inside VM resource
- AWS: `aws_key_pair` resource + reference in instance
- GCP: `metadata` field using `ssh-keys`

**Key Differences**:
- Azure embeds the key inside the VM resource.  
- AWS requires registering the key separately.  
- GCP injects the key via instance metadata.

## 7.7 Virtual Machine Resource

Each provider provisions an Ubuntu 24.04 VM:

| Provider | Resource Type | Machine Type |
|----------|---------------|--------------|
| Azure | `azurerm_linux_virtual_machine` | Standard_B2pts_v2 |
| AWS | `aws_instance` | t3.micro |
| GCP | `google_compute_instance` | e2-small |

All:
- Disable password authentication
- Use SSH key authentication
- Output public IP
- Output SSH command

Despite similar outcomes, the schema and required surrounding infrastructure differ significantly.

## 7.8 Deployment Lifecycle (Identical Across Providers)

Although infrastructure structure differs, the OpenTofu workflow remains identical.

From within each provider directory:
```bash
tofu init
tofu validate
tofu plan
tofu apply
```
After apply completes:
```bash
ssh ubuntu@<public-ip>
```
To clean up:
```bash
tofu destroy
```
**Key Insight**:

The infrastructure models differ greatly.  
The deployment lifecycle does not.

This demonstrates that OpenTofu abstracts the provisioning workflow, but not the provider-specific infrastructure design.

## 7.9 Comparative Observations

1. Azure requires the most explicit component wiring.
2. AWS requires the most explicit internet routing configuration.
3. GCP requires the least structural configuration.
4. Security boundaries differ fundamentally across providers.
5. SSH key handling varies significantly.
6. The OpenTofu execution model remains identical.

This highlights that infrastructure portability requires conceptual alignment, not identical resource blocks. While the outcome (a publicly accessible Ubuntu VM) is the same, the structural path to achieving that outcome differs meaningfully across providers.

---

# 8. Cloud-Agnostic Deployment of a Single VM

## 8.1 Motivation for a Unified Interface
[Section 7](#7-provider-native-single-vm-deployment-no-abstraction) demonstrated that deploying a virtual machine across AWS, Azure, and GCP requires substantially different resource models, networking constructs, security configurations, and identity mechanisms. Although the end result was functionally equivalent, the internal structures of each provider differed in ways that are not syntactically or semantically aligned.

These structural differences make portability at the resource-definition level impractical. Consolidating all providers into a single `main.tf` would require extensive conditional logic, provider-specific branching, and deeply nested abstractions. Such an approach would obscure native semantics, reduce readability, and ultimately create a configuration that is difficult to follow or maintain.

Rather than forcing uniformity at the resource layer, portability must instead be achieved at a higher level of abstraction. This section proposes a cloud-neutral interface that sits above provider-specific implementations. The interface expresses architectural intent through a shared set of inputs and outputs, while individual provider modules act as adapters that translate those inputs into native OpenTofu resource definitions.

In this approach, portability does not come from forcing all providers to look the same. Instead, it comes from defining a consistent interface at the top level, while allowing each provider to implement resources in its own way. The provider modules remain native and structurally correct, but the user interacts with a single, consistent set of inputs and outputs.

## 8.2 Directory Structure
To implement the layered, cloud-agnostic interface, the project directory was organized to clearly separate the cloud-neutral interface from provider-specific implementations. The structure ensures that portability is achieved through a consistent top-level interface, while each provider module remains fully native to its platform.

The directory for the single VM cloud-agnostic deployment is structured as follows:
```bash
sandbox/single_vm_agnostic/
├── interface-vars.tf        #Cloud-neutral input variables
├── interface.auto.tfvars    #Values for the interface variables
├── main.tf                  #Module calls (aws_vm, azure_vm, gcp_vm) with counts
├── module-vars.tf           #Variable definitions for provider modules
├── module.auto.tfvars       #Provider-specific configuration values
├── output.tf                #Cloud-agnostic outputs selecting the active module
├── providers.tf             #Provider configurations
└── modules/
    ├── aws/
    │   ├── aws-vars.tf      #AWS-specific module variables
    │   ├── aws-out.tf       #AWS module outputs (public_ip, ssh_command)
    │   └── main.tf          #AWS-native resources
    ├── azure/
    │   ├── az-vars.tf       #Azure-specific module variables
    │   ├── az-out.tf        #Azure module outputs (public_ip, ssh_command)
    │   └── main.tf          #Azure-native resources
    └── gcp/
        ├── gcp-vars.tf      #GCP-specific module variables
        ├── gcp-out.tf       #GCP module outputs (public_ip, ssh_command)
        └── main.tf          #GCP-native resources
```
**Key Points**:
1. Root Module (`sandbox/single_vm_agnostic/`)
   - Defines the cloud-neutral interface: `interface-vars.tf` declares high-level variables such as `name_prefix`, `platform`, and SSH keys.
   - Declares and assigns module-specific variables (module-vars.tf and module.auto.tfvars) at the root level, even though they are used only by individual provider modules. **Reason**: OpenTofu does not automatically load variable declarations or .tfvars files from inside subdirectories, so placing them in the root ensures that module inputs are properly resolved when invoking the provider modules.
   - Invokes all provider modules, but only the module matching `var.platform` is created via `count` or conditional logic.
   - Outputs (`output.tf`) expose a single, platform-agnostic interface for the VM’s public IP and SSH command, selecting the correct module’s outputs.
2. Provider Modules (`sandbox/single_vm_agnostic/modules/`)
   - Contain provider-native resource definitions (`main.tf`) for AWS, Azure, or GCP.
   - Declare module-specific inputs (`*-vars.tf`) to parameterize provider settings such as AMI IDs, VM sizes, or image references.
   - Define module-level outputs (`*-out.tf`) which expose `public_ip` and `ssh_command` back to the root module.
3. Separation of Concerns
   - The root module expresses architectural intent (what resources are needed).
   - Each provider module implements provider-specific resources (how the intent is realized).
   - Portability is achieved without merging provider resources or adding complex conditional logic inside the modules themselves.

## 8.3 Portable Interface
The cloud-neutral interface defines the architectural intent for a single virtual machine without exposing provider-specific constructs. Input variables, declared at the root module, include parameters such as `name_prefix`, `platform`, `admin_username`, `ssh_pub_key`, and `open_ports`. These variables provide a consistent contract for all provider modules, ensuring that the same high-level configuration can drive deployments in AWS, Azure, and GCP.

For example, the name_prefix variable is extended within each module to include the provider name, generating consistent resource naming like `demo-aws`, `demo-azure`, or `demo-gcp`. This approach maintains clarity while avoiding naming collisions across providers.

Due to OpenTofu’s variable resolution model, module-specific variables and their default values must be defined at the root (module-vars.tf and module.auto.tfvars) rather than within each module directory. This ensures that values are available at module instantiation time and avoids errors caused by empty or unresolved variables.

## 8.4 Provider-specific Modules
Each provider module acts as an adapter that translates the cloud-neutral interface into native OpenTofu resource blocks. No cross-provider abstraction exists within the modules; each module is structurally aligned with its provider’s resource model:
- **AWS module**: Creates a VPC, subnet, security group, key pair, and EC2 instance.
- **Azure module**: Constructs a resource group, virtual network, subnet, network security group, public IP, NIC, and Linux VM. Provider-specific constructs like NSG rules and NIC associations are handled internally by the module.
- **GCP module**: Configures a network, subnet, firewall rules, static IP, and compute instance.
This separation ensures that each module maintains provider-native semantics while conforming to the common interface, simplifying debugging, maintenance, and future extensions.

## 8.5 Deployment Lifecycle
The cloud-agnostic single VM deployment provides a consistent and predictable workflow for provisioning, accessing, and tearing down virtual machines across AWS, Azure, and GCP. Users interact with the system via a single root module and specify the target cloud using the platform variable.

### Initialize Directory
Initialize `sandbox/single_vm_agnostic/` as an OpenTofu working directory:
```bash
cd sandbox/single_vm_agnostic/
tofu init
```

### Deployment
To create a VM, run:
```bash
tofu apply -var="platform=<provider>"
```
Where provider is one of `aws`, `azure`, or `gcp`. Only the module corresponding to the selected provider will be instantiated.
If a VM from a previous provider exists in the state, OpenTofu will automatically plan to destroy it before creating the new VM. This ensures that only one VM is active at a time, avoiding resource conflicts and reducing unnecessary costs.

### Outputs
After a successful deployment, the root module exposes a consistent set of outputs for user interaction:
```bash
terraform output public_ip
terraform output ssh_command
```
These outputs provide the VM’s external IP and a ready-to-use SSH command, abstracting away provider-specific resource details. Users do not need to reference module-specific outputs or understand provider-native attributes.

### Cleanup
Tearing down the deployment is equally straightforward:
```bash
tofu destroy -var="platform=<provider>"
```
**Note**: the platform variable is not used in this command, but if not provided it will prompt for it. This command will cleanup all active resources.

### Summary
This workflow enforces a simple operational model:
1. Specify the provider via the `platform` variable.
2. Apply the configuration to create the VM, automatically destroying any previous deployment from another provider.
3. Access the VM using the unified outputs (`public_ip` and `ssh_command`).
4. Destroy the deployment when no longer needed, safely removing provider-specific resources.
By following this workflow, users achieve cloud portability with minimal cognitive overhead, while the underlying modules maintain provider-native semantics and structural correctness.

## 8.6 Reflections
This exercise demonstrated that true cloud portability requires abstraction at the interface level rather than at the resource level. By defining a consistent set of inputs, outputs, and a platform variable, we achieved:
- Behavioral consistency across AWS, Azure, and GCP.
- Simplicity of operation, with a single `tofu apply` and `tofu destroy` workflow.
- Modular clarity, keeping provider-specific implementations isolated and maintainable.
The approach balances portability with the flexibility to leverage each provider’s native constructs, avoiding complex conditional logic while maintaining readability and control.

---

# 9. Provider-Native Three VM Deployment (No Abstraction)
Before introducing a unified interface layer, each cloud provider was implemented independently using its own native OpenTofu configuration. The purpose of this step was to validate that the three-tier architecture could be successfully provisioned and accessed in each environment without abstraction.

By deploying AWS, Azure, and GCP separately, I ensured:
- Each provider’s networking model was correctly implemented
- SSH access patterns were verified
- Private and public IP behavior was fully understood
- Tier isolation rules functioned as expected
Only after confirming that each provider worked independently was abstraction considered. This reduced debugging complexity and ensured that any later issues could be attributed to the interface layer rather than provider-specific configuration errors.

## 9.1 Directory Structure
At this stage, each provider exists as its own working directory with an independent `main.tf`:
```bash
sandbox/
   └── three_vm_native/
       ├── az/
       │   └── main.tf
       ├── aws/
       │   └── main.tf
       └── gcp/
           └── main.tf
```
Each directory:
- Contains a complete network definition
- Provisions three virtual machines
- Implements tier-specific firewall rules
- Outputs relevant public and private IP addresses
There is no shared state, shared variables, or cross-provider orchestration at this stage.

## 9.2 Three-Tier Architecture Pattern
Although implemented separately, each provider follows the same logical architecture:
```bash
Internet
   ↓
Web VM (public IP)
   ↓
App VM (private)
   ↓
DB VM (private)
```
**Web Tier**
- Assigned a public IP
- Allowed inbound SSH (22) from the internet
- Allowed inbound HTTP (80)
- Serves as a jump host for administrative access

**Application Tier**
- No public IP
- Allowed SSH only from the private subnet
- Allowed application traffic (Ghost: 2368) from the private subnet

**Database Tier**
- No public IP
- Allowed SSH only from the private subnet
- Allowed MySQL (3306) from the private subnet

This pattern ensured that only the web tier was exposed to the internet, while the application and database tiers remained private.

## 9.3 SSH Access Model
All three providers implemented the same operational access pattern:
- SSH from local machine → Web VM (public IP)
- SSH from Web VM → App VM (private IP)
- SSH from Web VM → DB VM (private IP)

This verified:
- Internal routing within each virtual network
- Correct firewall rule configuration
- Proper isolation of private-tier resources

## 9.4 Validation and Testing
After provisioning in each provider:
- SSH connectivity to the web VM was tested
- SSH from web to app and db was confirmed
- Private IP reachability was verified
- Public IP assignment behavior was validated
This confirmed that the three-tier design functioned consistently across AWS, Azure, and GCP when implemented natively.

## 9.5 Rationale for Delaying Abstraction
The decision to delay abstraction was intentional.
Abstracting infrastructure before confirming provider-native behavior can obscure errors and complicate troubleshooting. By first validating each environment independently, the system gained:
- A known-good baseline per provider
- Confidence in networking and firewall behavior
- A clear reference implementation for later modularization
Only after establishing this baseline will a unified interface layer be introduced to standardize deployment across providers.

## 9.6 Deployment Lifecycle (Identical Across Providers)
Each provider-native configuration was deployed and tested independently using the standard OpenTofu workflow. The lifecycle for AWS, Azure, and GCP was identical aside from directory selection.
### 1. Navigate to Provider Directory
```bash
cd aws
# or
cd azure
# or
cd gcp
```

### 2. Initialize OpenTofu
```bash
tofu init
```
This downloads the appropriate provider plugins and initializes the working directory.

### 3. Validate and Review Plan
```bash
tofu validate
tofu plan
```
This step validates:
- Resource creation order
- Networking dependencies
- Firewall rule configuration
- Public vs. private IP assignment
Reviewing the plan before applying ensures that only the intended infrastructure will be created.

### 4. Apply the Configuration
```bash
tofu apply
```
After provisioning, outputs display the public IP address of the web tier and private IPs of the internal tiers.

### 5. Validate SSH Connectivity
First, connect to the web tier:
```bash
ssh ubuntu@<web_public_ip>
```
Close the connection using `exit`. Then test connectivity using the web tier as a jumphost:
```bash
ssh -J ubuntu@<web_public_ip> ubuntu@<app_private_ip>
ssh -J ubuntu@<web_public_ip> ubuntu@<db_private_ip>
```

### 6. Destroy Infrastructure
After validation:
```bash
tofu destroy
```
This removes all resources created by the configuration

---

# 10. Cloud-Agnostic Three VM Deployment
After validating provider-native implementations independently, an interface layer was introduced to abstract provider-specific logic behind a unified, cloud-agnostic deployment model.

The goal of this phase was to:
- Preserve the verified three-tier architecture
- Standardize inputs and outputs
- Enable single-directory deployments
- Maintain provider isolation within modules
- Allow platform selection through variables
This resulted in a modular OpenTofu design capable of provisioning identical infrastructure patterns across AWS, Azure, and GCP using a shared interface.

## 10.1 Architectural Approach
The abstraction layer follows a module-based design:
- Root module: Defines cloud-neutral inputs and selects the active provider
- Provider modules: Contain fully native AWS, Azure, and GCP implementations
- Unified outputs: Normalize provider-specific attributes into a consistent interface

Each provider module provisions:
- Virtual network
- Subnet
- Firewall/security rules
- Web VM (public IP)
- App VM (private only)
- DB VM (private only)

The root module exposes consistent outputs regardless of platform:
- `web_public_ip`
- `app_private_ip`
` `db_private_ip`
This ensures that downstream tooling (e.g., Ansible) does not need to know which cloud is active.

## 10.2 Directory Structure
The directory is structured identical to that of [section 8](#8-cloud-agnostic-deployment-of-a-single-vm):
```bash
sandbox/three_vm_agnostic/
├── interface-vars.tf        #Cloud-neutral input variables
├── interface.auto.tfvars    #Values for the interface variables
├── main.tf                  #Module calls (aws_vm, azure_vm, gcp_vm) with counts
├── module-vars.tf           #Variable definitions for provider modules
├── module.auto.tfvars       #Provider-specific configuration values
├── output.tf                #Cloud-agnostic outputs selecting the active module
├── providers.tf             #Provider configurations
└── modules/
    ├── aws/
    │   ├── aws-vars.tf      #AWS-specific module variables
    │   ├── aws-out.tf       #AWS module outputs (web_public_ip, app_private_ip, db_private_ip)
    │   └── main.tf          #AWS-native resources
    ├── azure/
    │   ├── az-vars.tf       #Azure-specific module variables
    │   ├── az-out.tf        #Azure module outputs (web_public_ip, app_private_ip, db_private_ip)
    │   └── main.tf          #Azure-native resources
    └── gcp/
        ├── gcp-vars.tf      #GCP-specific module variables
        ├── gcp-out.tf       #GCP module outputs (web_public_ip, app_private_ip, db_private_ip)
        └── main.tf          #GCP-native resources
```
**Root Layer** Responsibilities
- Defines cloud-neutral variables
- Selects the active provider via conditional module count
- Aggregates outputs from the active module
- Maintains a single working directory for deployment
**Provider Module** Responsibilities
- Implement provider-native networking constructs
- Define provider-specific variables
- Expose standardized outputs back to the root module
This separation ensures that provider-specific complexity remains encapsulated within modules.

## 10.3 Deployment Lifecycle
With the interface layer in place, the lifecycle becomes:
### Initialize
```bash
cd sandbox/three_vm_agnostic
tofu init
```
### Validate and Plan
```bash
tofu validate
tofu plan
```
### Apply
```bash
tofu apply
#OR
tofu apply -var="platform=<aws|azure|gcp>"
```
**Note**: If infrastructure is already deployed and the selected provider is changed, OpenTofu will destroy the previously provisioned resources before creating the new environment. This behavior ensures that only one provider environment is active at a time.

### Validate Access
```bash
ssh ubuntu@<web_public_ip>
```
Jump host access:
```bash
ssh -J ubuntu@<web_public_ip> ubuntu@<app_private_ip>
ssh -J ubuntu@<web_public_ip> ubuntu@<db_private_ip>
```
### Destroy
```bash
tofu destroy
```

## 10.4 Design Benefits
The interface layer provides:
- Single working directory
- Unified variable management
- Standardized outputs
- Encapsulation of provider-specific logic
- Clean separation between provisioning and configuration management

Most importantly, it enables the next phase of the project:

Infrastructure provisioning and application configuration can now be decoupled. Ansible can consume the normalized outputs without needing to know whether AWS, Azure, or GCP is active.

## 10.5 Transition to Configuration Management
With cloud-agnostic infrastructure in place and validated, the next step is to automate application deployment.

The following section introduces Ansible to install and configure Wordpress across:
- Web tier (Nginx reverse proxy)
- Application tier (Wordpress)
- Database tier (MariaDB)
The infrastructure layer now provides a stable and portable foundation for configuration management.

---

# 11. Configuration Management and Application Deployment
With a cloud-agnostic infrastructure layer established in Section 10, the next phase of the project focuses on **automating application deployment and configuration**.

Rather than manually configuring servers after provisioning, **Ansible** is used to install and configure the full application stack across the three virtual machines.

This phase introduces:
- Automated software installation
- Configuration templating
- Multi-host orchestration
- Integration between OpenTofu provisioning and Ansible configuration

The goal of this phase is to ensure that **application deployment is fully reproducible and portable across cloud providers**.

The resulting system deploys a complete **WordPress three-tier application** consisting of:

| Tier | Role |
|-----|-----|
| Web | Nginx reverse proxy and TLS termination |
| Application | PHP-FPM + WordPress |
| Database | MariaDB |

Each component is deployed using **Ansible roles** mapped to the infrastructure created in Section 10.

---

## 11.1 Architecture
```text
Internet
   |
   v
Web Tier (Nginx + TLS)
   |
   v
Application Tier (PHP-FPM + WordPress)
   |
   v
Database Tier (MariaDB)
```
This separation provides several architectural advantages:

- Isolation between presentation, application logic, and persistence
- Independent configuration of each tier
- Simplified troubleshooting
- Scalability potential in real-world environments

### Network Access Design

During implementation, the application and database virtual machines were configured with **public IP addresses**.

Originally, the architecture assumed that only the web server would expose a public endpoint while the application and database tiers remained private. However, this design would require a **NAT gateway** to allow outbound internet access for package installation and updates.

To avoid the additional cost associated with NAT gateways across multiple cloud providers, the application and database instances were given public IP addresses while **strict firewall rules restrict inbound access**.

The resulting configuration is:

| Tier | Public IP | SSH Access |
|-----|-----|-----|
| Web | Yes | Internet |
| App | Yes | Private network only |
| DB | Yes | Private network only |

Firewall rules enforce that:

- External SSH access is allowed only to the **web tier**
- The **web server acts as a jump host** for administrative access
- Application and database SSH access is restricted to the internal network

Example administrative SSH access flow:

```bash
ssh ubuntu@<web_public_ip>
ssh -J ubuntu@<web_public_ip> ubuntu@<app_private_ip>
ssh -J ubuntu@<web_public_ip> ubuntu@<db_private_ip>
```
Although the application and database instances possess public IP addresses, firewall restrictions ensure that they remain **administratively isolated from the public internet**.

In production environments, these tiers would typically reside in **private subnets with outbound access provided by a NAT gateway or internal package mirror**. The approach used here prioritizes **cost efficiency for an educational deployment** while maintaining controlled administrative access.

## 11.2 Ansible Directory Structure
Application configuration is implemented using **Ansible roles**, which separate responsibilities by tier.
```bash
ansible/
├── site.yml
├── ansible.cfg
├── inventory.yml
├── group_vars/
│   └── all.yml
└── roles/
    ├── web/
    │   ├── tasks/
    │   │   └── main.yml
    │   └── templates/
    │       ├── nginx.conf1.j2
    │       └── nginx.conf2.j2
    ├── app/
    │   ├── tasks/
    │   │   └── main.yml
    │   └── templates/
    │       └── wp-config.php.j2
    └── db/
        └── tasks/
            └── main.yml
```
Each role manages configuration for a specific tier:

| Role | Responsibility |
|-----|-----|
| web	| Installs Nginx and configures reverse proxy and TLS |
| app | Installs PHP-FPM and WordPress |
| db | Installs and configures MariaDB |

Templates are used to dynamically generate configuration files based on variables supplied during deployment.

## 11.3 Playbook Execution
The deployment is orchestrated through a single Ansible playbook:
```bash
site.yaml
```
Database and application roles execute **in parallel**, while the web tier is configured afterward.
```yaml
- hosts: db_group:app_group
  become: true
  gather_facts: false

  roles:
    - { role: db,  when: "'db_group' in group_names" }
    - { role: app, when: "'app_group' in group_names" }

- hosts: web_group
  become: true
  roles:
    - web
```
This execution model allows:
- Database and application installation to occur simultaneously
- Web tier configuration to occur after backend services are available

## 11.4 Transition to Automated Deployment
At this stage, the infrastructure layer (OpenTofu) and configuration layer (Ansible) are fully functional but still operate as separate steps.

The final phase of the project integrates both layers into a **single automated deployment pipeline**, where infrastructure provisioning, configuration management, DNS configuration, and application deployment occur as part of the same workflow.

---

# 12. End-to-End Automated Deployment Pipeline
To simplify deployment and demonstrate a fully automated infrastructure workflow, the provisioning and configuration layers were integrated into a single pipeline executed through **OpenTofu**.
This integration enables the entire system to be deployed with a single command.
```bash
tofu apply
```
The OpenTofu configuration was extended to perform additional orchestration tasks beyond infrastructure provisioning.

## 12.1 Automated Inventory Generation
OpenTofu generates an Ansible inventory file dynamically using `inventory.tf` and the IP addresses produced during infrastructure provisioning.

The infrastructure modules expose the following normalized outputs:
- `web_public_ip`
- `app_private_ip`
- `db_private_ip`

These values are used to construct the Ansible inventory file automatically. This approach removes the need for manual inventory management and ensures that configuration management always targets the correct infrastructure resources. It also allows the same Ansible configuration to operate across multiple cloud providers without modification.

## 12.2 SSH Availability Checks
Newly provisioned virtual machines may take several seconds to complete their initialization and begin accepting SSH connections.
To prevent configuration tasks from executing before hosts are ready, the OpenTofu configuration includes logic in `ssh.tf` to wait for SSH availability.
This step ensures that:
- Virtual machines have completed initialization
- SSH services are active
- Configuration management can proceed reliably

## 12.3 DNS Configuration
The deployment pipeline also automates DNS configuration using the Namecheap API. Namecheap variables are declared in `namecheap-vars.tf`. A
`namecheap.auto.tfvars` file must exist locally to provide the required credentials and domain configuration values. The domain configured in `ansible/group_vars/all.yml` must also match
the DNS configuration.
During deployment:
- The web server’s public IP address is retrieved from OpenTofu outputs
- A DNS record is created or updated for the configured domain
- The record points the domain to the web server
This step ensures that the application becomes accessible via a domain name immediately after deployment.

## 12.4 Ansible Execution
Once infrastructure provisioning, SSH availability checks, and DNS configuration are complete, OpenTofu invokes the Ansible playbook responsible for installing and configuring the application stack using `ansible.tf`.
The Ansible execution performs the following tasks:
- Install and configure **MariaDB** on the database server
- Install **PHP-FPM and WordPress** on the application server
- Configure **Nginx reverse proxy and TLS** on the web server
This process installs the full application stack without requiring manual intervention.

## 12.5 Directory Structure
The structure of the project directory is as follows:
```bash
three-tier-app/ 
├── ansible.tf              # Runs ansible playbook
├── dns.tf                  # Configure namecheap records through API
├── interface-vars.tf       # Interface specific variables
├── interface.auto.tfvars   # Interface variable values
├── inventory.tf            # Generates ansible inventory
├── locals.tf               # Defines locals (IPs)
├── main.tf                 # Module calls (aws_vm, azure_vm, gcp_vm) with counts
├── module-vars.tf          # Module specific variables
├── module.auto.tfvars      # Module variable values
├── namecheap-vars.tf       # Namecheap variables (username, api key, client ip, domain)
├── namecheap.auto.tfvars   # gitignored namecheap variable values
├── output.tf               # Outputs
├── providers.tf            # Providers
├── ssh.tf                  # Checks SSH is available
├── versions.tf             # Versions
├── .gitignore
├── modules/
│   ├── aws/
│   │   ├── main.tf
│   │   ├── aws-vars.tf
│   │   └── aws-out.tf
│   ├── az/
│   │   ├── main.tf
│   │   ├── az-vars.tf
│   │   └── az-out.tf
│   └── gcp/
│       ├── main.tf
│       ├── gcp-vars.tf
│       └── gcp-out.tf
└── ansible/
    ├── site.yml
    ├── ansible.cfg
    ├── inventory.yml       # gitignored - generated by tofu
    ├── group_vars/
    │   └── all.yml
    └── roles/
        ├── web/
        │   ├── tasks/
        │   │   └── main.yml
        │   └── templates/
        │       ├── nginx.conf1.j2
        │       └── nginx.conf2.j2
        ├── app/
        │   ├── tasks/
        │   │   └── main.yml
        │   └── templates/
        │       └── wp-config.php.j2
        └── db/
             └── tasks/
                └── main.yml
```

## 12.6 Deployment Workflow
The resulting deployment lifecycle is:
```bash
tofu apply
   │
   ├── Provision infrastructure (AWS / Azure / GCP)
   ├── Allocate public and private IP addresses
   ├── Generate Ansible inventory
   ├── Wait for SSH availability
   ├── Configure DNS records
   ├── Execute Ansible playbook
   │      ├── Install MariaDB
   │      ├── Install WordPress + PHP
   │      └── Configure Nginx reverse proxy and TLS
   └── Deployment complete
```
After the process completes, the WordPress application is accessible via the configured domain name.

## 12.7 Project Outcome
The final system demonstrates a **fully automated, cloud-agnostic application deployment pipeline**.
Key characteristics include:
- Infrastructure provisioning through **OpenTofu**
- Configuration management through **Ansible**
- Cloud abstraction across **AWS, Azure, and GCP**
- Automated DNS configuration
- End-to-end deployment from a single command
The platform can now deploy an identical three-tier WordPress application stack across multiple cloud providers with minimal modification, demonstrating the effectiveness of **infrastructure-as-code and configuration management integration**.
