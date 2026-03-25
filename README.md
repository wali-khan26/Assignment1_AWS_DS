# UniEvent API Processor 

**Author:** WALI MUHAMMAD KHAN  
**Contact:** walimokhan@gmail.com  
**Repository:** `Assignment1_AWS_CE`

##  Project Overview
UniEvent is a highly available, fault-tolerant cloud web application built entirely on Amazon Web Services (AWS). It automatically fetches live event data from the Ticketmaster Discovery API, processes the information, securely stores event media in Amazon S3, and serves a dynamic dashboard to users. 

This project demonstrates production-grade cloud architecture, utilizing isolated private networks, automated scaling, and identity-based security.

---

##  Architecture Components
* **Virtual Private Cloud (VPC):** Custom network isolating resources.
* **Public Subnets:** Hosts the Application Load Balancer (ALB) and NAT Gateway.
* **Private Subnets:** Hosts the EC2 compute instances securely away from the public internet.
* **NAT Gateway:** Allows private EC2 instances to securely fetch external API data.
* **Elastic Compute Cloud (EC2):** Ubuntu servers running Apache and Python.
* **Auto Scaling Group (ASG):** Ensures high availability by maintaining a minimum fleet of 2 servers across different Availability Zones.
* **Application Load Balancer (ALB):** Single point of entry that routes internet traffic to healthy backend servers.
* **Amazon S3:** Secure, decoupled storage for event media (posters).
* **Identity and Access Management (IAM):** Secure roles for credential-less S3 access.

---

##  Step-by-Step Implementation Guide

### Step 1: Network Provisioning (VPC & Subnets)
1. Created a custom **VPC**.
2. Created two **Public Subnets** (AZ-A, AZ-B) and two **Private Subnets** (AZ-A, AZ-B).
3. Created and attached an **Internet Gateway (IGW)** to the VPC.
4. Deployed a **NAT Gateway** inside Public Subnet A and allocated an Elastic IP.
5. **Route Tables:**
   * **Public Route Table:** Routed `0.0.0.0/0` to the IGW. Explicitly associated with both Public Subnets.
   * **Private Route Table:** Routed `0.0.0.0/0` to the NAT Gateway. Explicitly associated with both Private Subnets.

### Step 2: Security & IAM
1. **IAM Role:** Created an EC2 IAM Role with the `AmazonS3FullAccess` policy.
2. **ALB Security Group:** Allowed Inbound HTTP (Port 80) from `0.0.0.0/0` (the internet).
3. **EC2 Security Group:** * Allowed Inbound HTTP (Port 80) *only* from the ALB Security Group.
   * Allowed Outbound traffic (`0.0.0.0/0`) to enable API fetching and package downloads.

### Step 3: Secure Storage Setup
1. Created a private **Amazon S3 Bucket** (`unievent-media-bucket`).
2. Ensured **Block Public Access** was turned ON to secure university event media.

### Step 4: Compute & Automation (Launch Template)
1. Created an **EC2 Launch Template** using an Ubuntu AMI.
2. Attached the previously created EC2 IAM Role.
3. Assigned the EC2 Security Group.
4. Injected the following **User Data script** to fully automate server configuration on boot:
   * Updated the OS and installed `apache2`, `python3-pip`, `requests`, and `boto3`.
   * Started and enabled the Apache web server.
   * Created and executed a Python script that:
     1. Fetches a live event from the Ticketmaster API.
     2. Uploads the event poster to the S3 bucket using `boto3`.
     3. Dynamically generates an `index.html` dashboard displaying the fetched event title.

### Step 5: High Availability (Load Balancing & Auto Scaling)
1. **Target Group:** Created a Target Group checking instance health on Port 80.
2. **Application Load Balancer (ALB):** Deployed in the Public Subnets, listening on Port 80, and forwarding traffic to the Target Group.
3. **Auto Scaling Group (ASG):** * Configured to use the Launch Template.
   * Deployed instances strictly into the **Private Subnets**.
   * Set Desired, Minimum, and Maximum capacity to 2.
   * Enabled Target Tracking Scaling Policies (e.g., scale out if CPU > 50%).

---

##  Testing and Validation

To verify the architecture meets all assignment requirements:

1. **Verify Private Compute:** Check EC2 instances in the console. They possess no Public IPv4 addresses, proving they run securely in private subnets.
2. **Verify Secure Storage:** Navigate to the S3 bucket. A `.jpg` poster is successfully stored inside the `posters/` directory via the automated Python script.
3. **Verify Data Display:** Navigate to the ALB DNS name in a web browser. The dynamic "University Events Dashboard" displays the live Ticketmaster event.
4. **Chaos Testing (Fault Tolerance):**
   * Manually terminate an active EC2 instance in the AWS Console.
   * Refresh the ALB DNS link; the website remains online due to load balancing.
   * Observe the ASG Activity history; it automatically detects the failure and launches a replacement instance to heal the fleet.

---
*Developed for Cloud Engineering Assignment 1.*
