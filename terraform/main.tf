# Create VPCs
resource "aws_vpc" "tenant" {
  count = 3
  cidr_block = "10.0.${count.index}.0/24"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "tenant${count.index}"
  }
}

# Create two subnets in tenant0 VPC
resource "aws_subnet" "tenant_public_subnets" {
  count = 3
  vpc_id                  = aws_vpc.tenant[count.index].id
  cidr_block              = "10.0.${count.index}.0/26" 
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "tenant${count.index}-public-subnet"
  }
}

resource "aws_subnet" "tenant_2_public_subnets" {
  count = 3
  vpc_id                  = aws_vpc.tenant[count.index].id
  cidr_block              = "10.0.${count.index}.64/26" 
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = true
  tags = {
    Name = "tenant${count.index}-public-subnet${count.index}"
  }
}

resource "aws_subnet" "tenant_private_subnets" {
  count = 3
  vpc_id                  = aws_vpc.tenant[count.index].id
  cidr_block              = "10.0.${count.index}.128/26" 
  availability_zone       = "us-east-1b" 
  map_public_ip_on_launch = false
  tags = {
    Name = "tenant${count.index}-private-subnet"
  }
}

resource "aws_subnet" "tenant_2_private_subnets" {
  count = 3
  vpc_id                  = aws_vpc.tenant[count.index].id
  cidr_block              = "10.0.${count.index}.192/26" 
  availability_zone       = "us-east-1d" 
  map_public_ip_on_launch = false
  tags = {
    Name = "tenant${count.index}-private-subnet${count.index}"
  }
}

# Create three route tables
resource "aws_route_table" "tenant_public_route_tables" {
  count = 3
  vpc_id = aws_vpc.tenant[count.index].id
  tags = {
    Name = "tenant${count.index}-public-rt"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "tenant_igw" {
    count = 3
    vpc_id = aws_vpc.tenant[count.index].id
    tags = {
        Name = "tenant${count.index}-igw"
    }
}

# Attach the Internet Gateway to one of the subnets
resource "aws_route" "subnet_igw_route" {
    count = 3
    route_table_id         = aws_route_table.tenant_public_route_tables[count.index].id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = aws_internet_gateway.tenant_igw[count.index].id
}

# Associate the pubblc route table with the pubic subnet
resource "aws_route_table_association" "public_subnet_association" {
    count = 3
    subnet_id      = aws_subnet.tenant_public_subnets[count.index].id
    route_table_id = aws_route_table.tenant_public_route_tables[count.index].id
}

# Associate the pubblc route table with the pubic subnet2
resource "aws_route_table_association" "public_subnet2_association" {
    count = 3
    subnet_id      = aws_subnet.tenant_2_public_subnets[count.index].id
    route_table_id = aws_route_table.tenant_public_route_tables[count.index].id
}

# Create an Elastic IP for the NAT Gateway
resource "aws_eip" "nat_gateway_eip" {
    count = 3
    tags = {
        Name = "tenant${count.index}-ngw-ip"
    }
}

# Create the NAT Gateway
resource "aws_nat_gateway" "nat_gateway" {
    count = 3
    allocation_id = aws_eip.nat_gateway_eip[count.index].id
    subnet_id     = aws_subnet.tenant_public_subnets[count.index].id
    tags = {
        Name = "tenant${count.index}-ngw"
    }
}

resource "aws_route_table" "tenant_private_route_tables" {
  count = 3
  vpc_id = aws_vpc.tenant[count.index].id
  tags = {
    Name = "tenant${count.index}-private-rt"
  }
}

resource "aws_route" "subnet_ngw_route" {
    count = 3
    route_table_id         = aws_route_table.tenant_private_route_tables[count.index].id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id         = aws_nat_gateway.nat_gateway[count.index].id
}

# Associate the private route tables with the private subnets
resource "aws_route_table_association" "private_subnet_association" {
    count = 3
    subnet_id      = aws_subnet.tenant_private_subnets[count.index].id
    route_table_id = aws_route_table.tenant_private_route_tables[count.index].id
}

# Associate the private route tables with the private subnet2
resource "aws_route_table_association" "private_subnet2_association" {
    count = 3
    subnet_id      = aws_subnet.tenant_2_private_subnets[count.index].id
    route_table_id = aws_route_table.tenant_private_route_tables[count.index].id
}

# Create VPC peering connection
resource "aws_vpc_peering_connection" "tenant0_to_tenant1" {
  vpc_id = aws_vpc.tenant[0].id
  peer_vpc_id = aws_vpc.tenant[1].id
  auto_accept = true
  tags = {
    Name = "tenant0_to_tenant1"
  }
}

# Create VPC peering connection
resource "aws_vpc_peering_connection" "tenant0_to_tenant2" {
  vpc_id = aws_vpc.tenant[0].id
  peer_vpc_id = aws_vpc.tenant[2].id
  auto_accept = true
  tags = {
    Name = "tenant0_to_tenant2"
  }
}

# Adding routing for vpc peering
resource "aws_route" "vpc_peer_tenant0_to_tenant1_public" {
    route_table_id         = aws_route_table.tenant_public_route_tables[0].id
    destination_cidr_block = "10.0.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.tenant0_to_tenant1.id
}

resource "aws_route" "vpc_peer_tenant1_to_tenant0_public" {
    route_table_id         = aws_route_table.tenant_public_route_tables[1].id
    destination_cidr_block = "10.0.0.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.tenant0_to_tenant1.id
}

resource "aws_route" "vpc_peer_tenant0_to_tenant1_private" {
    route_table_id         = aws_route_table.tenant_private_route_tables[0].id
    destination_cidr_block = "10.0.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.tenant0_to_tenant1.id
}

resource "aws_route" "vpc_peer_tenant1_to_tenant0_private" {
    route_table_id         = aws_route_table.tenant_private_route_tables[1].id
    destination_cidr_block = "10.0.0.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.tenant0_to_tenant1.id
}

resource "aws_route" "vpc_peer_tenant0_to_tenant2_public" {
    route_table_id         = aws_route_table.tenant_public_route_tables[0].id
    destination_cidr_block = "10.0.2.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.tenant0_to_tenant2.id
}

resource "aws_route" "vpc_peer_tenant2_to_tenant0_public" {
    route_table_id         = aws_route_table.tenant_public_route_tables[2].id
    destination_cidr_block = "10.0.0.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.tenant0_to_tenant2.id
}

resource "aws_route" "vpc_peer_tenant0_to_tenant2_private" {
    route_table_id         = aws_route_table.tenant_private_route_tables[0].id
    destination_cidr_block = "10.0.2.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.tenant0_to_tenant2.id
}

resource "aws_route" "vpc_peer_tenant2_to_tenant0_private" {
    route_table_id         = aws_route_table.tenant_private_route_tables[2].id
    destination_cidr_block = "10.0.0.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.tenant0_to_tenant2.id
}


# Create ec2 in tenant1
resource "aws_instance" "tenant_ec2" {
  ami           = "ami-0573324ffc6ebc574"
  instance_type = "t3.large"
  subnet_id     = aws_subnet.tenant_private_subnets[1].id
  key_name      = "interview"
  vpc_security_group_ids = [aws_security_group.allow_ssh1.id]

  root_block_device {
    volume_size = 30
  }

  tags = {
    Name = "tenant1"
  }
}

# Create ec2 in tenant0
resource "aws_instance" "tenant0_ec2" {
  ami           = "ami-0573324ffc6ebc574"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.tenant_public_subnets[0].id
  key_name      = "interview"
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  tags = {
    Name = "tenant0"
  }
}

# Create ec2 in tenant0 SG
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow ssh inbound traffic"
  vpc_id      = aws_vpc.tenant[0].id

  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

# Create ec2 in tenant0 SG
resource "aws_security_group" "allow_ssh1" {
  name        = "allow_ssh"
  description = "Allow ssh inbound traffic"
  vpc_id      = aws_vpc.tenant[1].id

  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["10.0.0.0/24"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

# Create ec2 in tenant0 SG
resource "aws_security_group" "allow_ssh2" {
  name        = "allow_ssh"
  description = "Allow ssh inbound traffic"
  vpc_id      = aws_vpc.tenant[2].id

  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["10.0.0.0/24"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

# Create VPN Gateway in tenant0 VPC
resource "aws_vpn_gateway" "tenant0_vpn" {
  vpc_id = aws_vpc.tenant.0.id
  tags = {
    Name = "tenant0-vpn-gateway"
  }
}

# Create IAM for EKS

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks_role" {
  name               = "eks-cluster-interview"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "interview-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_role.name
}

# Optionally, enable Security Groups for Pods
# Reference: https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html
resource "aws_iam_role_policy_attachment" "interview-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_role.name
}

# Create EKS cluster

resource "aws_eks_cluster" "my_cluster" {
  name     = "interview-eks-cluster"
  role_arn = aws_iam_role.eks_role.arn
  vpc_config {
    subnet_ids = [aws_subnet.tenant_public_subnets[2].id, aws_subnet.tenant_2_public_subnets[2].id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.interview-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.interview-AmazonEKSVPCResourceController,
  ]
}

# EKS Node group role
data "tls_certificate" "example" {
  url = aws_eks_cluster.my_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "example" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.example.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.my_cluster.identity[0].oidc[0].issuer
}

data "aws_iam_policy_document" "example_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.example.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.example.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-group-example"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

#resource "aws_iam_role" "eks_node_role" {
#  assume_role_policy = data.aws_iam_policy_document.example_assume_role_policy.json
#  name               = "eks-node-group-interview"
#}

resource "aws_iam_role_policy_attachment" "interiew-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "interiew-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "interiew-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
} 

# EKS Node creation
resource "aws_eks_node_group" "example" {
  cluster_name    = aws_eks_cluster.my_cluster.name
  node_group_name = "interview"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.tenant_private_subnets[2].id, aws_subnet.tenant_2_private_subnets[2].id]
  instance_types  = ["t2.micro"]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  remote_access {
    ec2_ssh_key = "interview"
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_eks_cluster.my_cluster,
    aws_iam_role_policy_attachment.interiew-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.interiew-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.interiew-AmazonEC2ContainerRegistryReadOnly,
  ]
}

resource "aws_eks_addon" "example" {
  cluster_name                = aws_eks_cluster.my_cluster.name
  addon_name                  = "vpc-cni"
}
