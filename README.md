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
     -------------------------------------------------
     |                      |                       |
    AWS                   Azure                   GCP
     |                      |                       |
+------------+ +------------+ +------------+
| Frontend | | Frontend | | Frontend |
+------------+ +------------+ +------------+
| | |
+------------+ +------------+ +------------+
| Backend | | Backend | | Backend |
+------------+ +------------+ +------------+
| | |
+------------+ +------------+ +------------+
| Database | | Database | | Database |
+------------+ +------------+ +------------+
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

## 6.3 Lab Notes
