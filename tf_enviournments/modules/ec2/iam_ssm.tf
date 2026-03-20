# IAM instance profile for SSM so the CD job can run SSM SendCommand on this instance.

resource "aws_iam_role" "ec2_ssm" {
  name        = "ec2-ssm-role-${local.formatted_time}"
  description = "Role for EC2 so GitHub Actions CD can run SSM SendCommand"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "ec2-ssm-role-${local.formatted_time}"
  }
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_managed" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_ssm" {
  name = "ec2-ssm-instance-profile-${local.formatted_time}"
  role = aws_iam_role.ec2_ssm.name
}
