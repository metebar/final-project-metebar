# Project Report: WordPress High Availability on AWS

**Student:** Metecan Barutcu  
**Student ID:** 32247318  
**Date:** 14 June 2026  
**Repository:** https://github.com/metebar/final-project-metebar

---

## 1. Overview

This project is the final assignment of the cloud computing course. The goal was to build a high availability WordPress deployment on AWS and bring together all the topics we learned during the semester. These topics include S3, EC2, ALB, Terraform, benchmarking, auto scaling, and RDS.

I decided to extend my Assignment 05 WordPress setup instead of starting from scratch. The main improvements are replacing the local database with Amazon RDS, adding an Auto Scaling Group instead of fixed EC2 instances, and setting up CloudWatch alarms for automatic scaling.

---

## 2. Architecture

The infrastructure consists of these components:

- **VPC** with public and private subnets configured across multiple availability zones
- **ALB** receives HTTP traffic and distributes it to EC2 instances
- **ASG** manages EC2 instances automatically (min: 1, max: 3)
- **RDS MySQL 8.0** runs the WordPress database inside private subnets
- **S3** stores WordPress media uploads
- **CloudWatch Alarms** scale out when CPU goes above 70%, scale in when CPU drops below 30%

Traffic flow: User → ALB → EC2 (WordPress) → RDS (MySQL)

---

## 3. What I Changed from Assignment 05

In Assignment 05, I used two fixed EC2 instances with MariaDB installed directly on the server. For this project I made several important changes.

**Database:** I moved from MariaDB on EC2 to Amazon RDS MySQL 8.0. With RDS, backups and patching are handled automatically by AWS. WordPress now connects to RDS using an endpoint address instead of localhost.

**Scaling:** Instead of two fixed EC2 instances, I used an Auto Scaling Group. It starts with one instance and can go up to three depending on CPU usage. This is more cost efficient because extra instances are only running when there is actual load.

**Monitoring:** I added two CloudWatch alarms. If average CPU goes over 70% for two minutes, ASG launches a new instance. If CPU stays below 30%, ASG removes one instance.

**Networking:** I created a custom VPC with public subnets for EC2 and ALB, and private subnets for RDS. The database is not directly accessible from the internet, which is more secure.

**IaC:** Assignment 05 had three separate Terraform folders. This project uses a single unified configuration that deploys everything at once with one `terraform apply` command.

---

## 4. Terraform Resources

The `main.tf` file contains all the AWS resources:

- `aws_vpc`, `aws_subnet`, `aws_internet_gateway`, `aws_route_table` — networking
- `aws_security_group` — separate security groups for ALB, EC2, and RDS
- `aws_s3_bucket` + bucket policy — media storage
- `aws_db_instance` + `aws_db_subnet_group` — RDS MySQL
- `aws_lb` + `aws_lb_target_group` + `aws_lb_listener` — load balancer
- `aws_launch_template` — EC2 configuration with user-data script
- `aws_autoscaling_group` — auto scaling
- `aws_autoscaling_policy` (x2) + `aws_cloudwatch_metric_alarm` (x2) — scaling policies

---

## 5. Deployment Steps

```bash
# 1. Configure AWS credentials
aws configure
aws configure set aws_session_token <token>

# 2. Initialize Terraform
cd terraform
terraform init

# 3. Review the plan
terraform plan

# 4. Deploy everything (RDS takes around 10 minutes)
terraform apply

# 5. Get the WordPress URL
terraform output alb_dns_name
```

---

## 6. Auto Scaling Test Results

I used ApacheBench to test whether the auto scaling works under load.

**Test command:**
```bash
ab -n 50000 -c 500 http://wp-alb-1106887450.us-east-1.elb.amazonaws.com/
```

**What happened:**
- Under 500 concurrent connections, CPU utilization went above 70%
- CloudWatch `wp-high-cpu` alarm changed to "In Alarm" state
- ASG automatically launched a second EC2 instance
- Number of running instances increased from 1 to 2
- ALB kept distributing traffic during the scaling process

Some requests timed out during the test because a single t2.micro instance cannot handle 500 concurrent connections at the same time. But this is actually expected behavior. The high load triggered the CloudWatch alarm and ASG responded correctly by adding a new instance.

**ApacheBench results summary:**
- Total requests completed: 35,119
- 50% of requests served within: 4,003 ms
- 90% of requests served within: 6,727 ms
- 99% of requests served within: 18,740 ms

**Self-healing test:**
During deployment, one instance failed the ELB health check. ASG detected this automatically and replaced it with a new healthy instance without any manual action. This also shows the high availability is working.

**Screenshots:**
- `docs/Screenshots/01-wordpress-site.png` — WordPress site running via ALB
- `docs/Screenshots/02-asg-activity.png` — ASG activity history
- `docs/Screenshots/03-cloudwatch-ok.png` — CloudWatch alarms in OK state
- `docs/Screenshots/04-ec2-two-instances.png` — Two EC2 instances after scale-out
- `docs/Screenshots/05-cloudwatch-high-cpu-alarm.png` — wp-high-cpu alarm in alarm state

---

## 7. Concepts Applied

| Course Topic | Used In This Project |
|---|---|
| S3 | Media bucket for WordPress uploads |
| EC2 | WordPress application servers managed by ASG |
| AWS CLI | Credential configuration and verification |
| Terraform / IaC | All infrastructure defined as code |
| ALB | Load balancing across ASG instances |
| ASG | Auto scaling min:1 max:3 |
| CloudWatch | CPU alarms triggering scale out and scale in |
| RDS | Managed MySQL 8.0 database |
| Benchmarking | ApacheBench load test to verify scaling behavior |

---

## 8. Conclusion

This project combined all the topics from the semester into one real deployment. The most important improvement compared to Assignment 05 is that the database is now on RDS, which is more stable and reliable, and the EC2 instances can scale up and down automatically based on traffic.

The benchmarking test showed that the system responds correctly when load increases. CloudWatch detected the high CPU and ASG added a new instance without any manual steps. All the infrastructure is written in Terraform, so anyone can reproduce the full setup by running just one command.