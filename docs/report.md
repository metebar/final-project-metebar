# Project Report: WordPress High Availability on AWS

**Student:** Metecan Barutcu  
**Student ID:** 32247318  
**Date:** June 2026  
**Repository:** https://github.com/metebar/final-project-metebar

---

## 1. Overview

This project is a final wrap-up of the cloud computing course. I built a high availability WordPress deployment on AWS using the concepts we learned during the semester: S3, EC2, ALB, Terraform, benchmarking, auto scaling, and RDS.

The main idea was to take my Assignment 05 WordPress setup and improve it by replacing the local database with RDS, adding an Auto Scaling Group instead of fixed EC2 instances, and setting up CloudWatch monitoring with automatic scaling policies.

---

## 2. Architecture

The infrastructure has these main components:

- **VPC** with public and private subnets across 2 availability zones
- **ALB** receives all HTTP traffic and forwards to EC2 instances
- **ASG** manages EC2 instances automatically (min: 1, max: 3)
- **RDS MySQL 8.0** runs the WordPress database in private subnets
- **S3** stores WordPress media uploads
- **CloudWatch Alarms** trigger scale-out when CPU > 70%, scale-in when CPU < 30%

Traffic flow: User → ALB → EC2 (WordPress) → RDS (MySQL)

---

## 3. What I Changed from Assignment 05

In Assignment 05, I had two fixed EC2 instances with MariaDB installed directly on the server. This project changes several things:

**Database:** I moved from MariaDB on EC2 to Amazon RDS MySQL 8.0. RDS handles backups, patching, and availability automatically. WordPress connects to RDS through an endpoint instead of localhost.

**Scaling:** Instead of two fixed EC2 instances, I used an Auto Scaling Group. The ASG starts with one instance and can scale up to three based on CPU load. This is more cost-efficient because we only run extra instances when needed.

**Monitoring:** I added two CloudWatch alarms. When average CPU goes above 70% for two minutes, a new EC2 instance is added. When CPU drops below 30%, one instance is removed.

**Networking:** I created a custom VPC with separate public subnets for EC2/ALB and private subnets for RDS. This is better security practice because the database is not directly reachable from the internet.

**IaC:** Assignment 05 had three separate terraform folders (terraform-01, 02, 03). This project uses a single unified Terraform configuration that deploys everything at once.

---

## 4. Terraform Resources

The `main.tf` file includes these AWS resources:

- `aws_vpc`, `aws_subnet`, `aws_internet_gateway`, `aws_route_table` — networking
- `aws_security_group` — separate SGs for ALB, EC2, and RDS
- `aws_s3_bucket` + policy — media storage
- `aws_db_instance` + `aws_db_subnet_group` — RDS MySQL
- `aws_lb` + `aws_lb_target_group` + `aws_lb_listener` — load balancer
- `aws_launch_template` — EC2 configuration with user-data
- `aws_autoscaling_group` — auto scaling
- `aws_autoscaling_policy` (x2) + `aws_cloudwatch_metric_alarm` (x2) — scaling policies

---

## 5. Deployment Steps

```bash
# 1. Configure AWS credentials
aws configure

# 2. Initialize Terraform
cd terraform
terraform init

# 3. Review plan
terraform plan

# 4. Deploy (takes ~10 min, RDS takes longest)
terraform apply

# 5. Get the site URL
terraform output alb_dns_name
```

---

## 6. Concepts Applied

| Course Topic | Used In This Project |
|---|---|
| S3 | Media bucket for WordPress uploads |
| EC2 | WordPress application servers via ASG |
| AWS CLI | Credential setup, verification |
| Terraform / IaC | All infrastructure defined in code |
| ALB | Load balancing across ASG instances |
| ASG | Auto scaling min:1 max:3 |
| CloudWatch | CPU alarms for scaling triggers |
| RDS | Managed MySQL database |

---

## 7. Conclusion

This project brought together everything from the semester into one working deployment. The biggest improvement over Assignment 05 is that the database is now managed by RDS, which is more reliable, and the EC2 instances scale automatically based on actual traffic. All infrastructure is defined in Terraform so the whole setup can be reproduced with one command.