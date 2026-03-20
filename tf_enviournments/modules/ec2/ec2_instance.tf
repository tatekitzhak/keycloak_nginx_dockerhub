/*

Component:
- VPC, like "house": (10.0.0.0/16),The boundary of your private network. AWS Cloud
- Internet Gateway, like "front door": The bridge between your VPC and the Public Internet. Attached to VPC
- Public Subnet, like "room": A subset of the VPC IP range (10.0.101.0/24). Resides inside VPC
- Route Table, like "pathway": "The ""GPS"" that directs traffic from 0.0.0.0/0 to the IGW." Linked to VPC
- RT Association,The glue that applies the routing rules to your specific subnet. Connects Subnet to RT

*/

# Create the EC2 Instance using the data source ID
resource "aws_instance" "ubuntu_ec2_instance_terraform" {

  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.tf_subnet_public.id
  vpc_security_group_ids      = [var.sg_id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm.name
  key_name                    = aws_key_pair.deployer.key_name

  tags = {
    Name = "aws-ec2-instance-terraform-${local.formatted_time}"
  }

  # Docker pre-installed via user_data so CD can pull from Docker Hub and run containers
  # user_data = file("${path.module}/install_docker_on_ubuntu_aws_ec2.sh")
  user_data = <<-EOF
              #!/bin/bash
              
              # 1. Setup Logging immediately
              LOG="/var/log/install_docker_on_ubuntu_aws_ec2.log"
              exec > >(tee -a "$LOG") 2>&1
              
              echo "--- LOG START: $(date) ---"
              set -e  # Exit on any error

              # 2. Add Docker's official GPG key & Repository
              apt-get update -y
              apt-get install -y ca-certificates curl gnupg
              install -m 0755 -d /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
              chmod a+r /etc/apt/keyrings/docker.gpg

              echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

              # 3. Install Docker Engine
              apt-get update -y
              apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

              # 4. Enable Service & Set Permissions
              systemctl enable docker
              systemctl start docker
              usermod -aG docker ubuntu

              echo "--- INSTALL COMPLETE: $(docker --version) ---"
              EOF
}


# Define the Internet Gateway resource and attach it to the VPC
resource "aws_internet_gateway" "terraform_gw" {
  vpc_id = var.vpc_id

  tags = {
    Name        = "terraform_internet_gateway-${local.formatted_time}"
    Environment = "TF_development_internet_gateway"
  }
}

# Public subnet
resource "aws_subnet" "tf_subnet_public" {
  vpc_id                  = var.vpc_id
  cidr_block              = "10.0.101.0/24"
  map_public_ip_on_launch = true

  # count                   = length(var.public_subnets_cidr)
  # availability_zone       = element(local.availability_zones, count.index)

  tags = {
    Name        = "terraform_subnet_public-${local.formatted_time}"
    Environment = "TF_development_subnet_public"
  }
}


resource "aws_route_table" "terraform_rt_public" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform_gw.id
  }

  tags = {
    Name        = "terraform-rt-public-${local.formatted_time}"
    Environment = "TF_development_rt_public"
  }
}

#  Associate route tables for subnets
resource "aws_route_table_association" "terraform_rta_public" {
  subnet_id      = aws_subnet.tf_subnet_public.id
  route_table_id = aws_route_table.terraform_rt_public.id
}


output "ec2_ip_address" {
  value = aws_instance.ubuntu_ec2_instance_terraform.public_ip
}

output "ec2_instance_id" {
  description = "EC2 instance ID for SSM and CD deploy"
  value       = aws_instance.ubuntu_ec2_instance_terraform.id
}

