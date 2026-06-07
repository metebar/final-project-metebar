variable "aws_region" {
  default = "us-east-1"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "db_instance_class" {
  default = "db.t3.micro"
}

variable "db_name" {
  default = "wordpressdb"
}

variable "db_username" {
  default = "wpuser"
}

variable "db_password" {
  default = "WpPass2026!"
}

variable "s3_bucket_name" {
  default = "metecan-wp-media-2026"
}

variable "key_name" {
  default = ""
}