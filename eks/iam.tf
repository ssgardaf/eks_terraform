# EKS 클러스터용 Assume Role 정책 생성 (EKS 서비스가 역할을 가질 수 있도록 설정)
data "aws_iam_policy_document" "eks_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

# EKS 클러스터 역할 생성
resource "aws_iam_role" "eks_cluster_role" {
  name               = "${var.cluster_name}-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role_policy.json
  tags = {
    Name = "${var.cluster_name}-eks-cluster-role"
  }
}

# EKS 클러스터에 필요한 정책 부착 (AmazonEKSClusterPolicy)
resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# EKS 서비스에 필요한 정책 부착 (AmazonEKSServicePolicy)
resource "aws_iam_role_policy_attachment" "eks_service_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# EKS 워커 노드를 위한 Assume Role 정책 생성 (EC2 서비스 역할)
data "aws_iam_policy_document" "eks_worker_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# EKS 워커 노드용 EBS 정책 생성 (EBS 관리 권한 부여)
resource "aws_iam_policy" "eks_worker_ebs_policy" {
  name        = "eks_worker_ebs_policy"
  description = "EKS worker nodes policy for managing EBS volumes"
  policy      = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateVolume",
          "ec2:DeleteVolume",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumeStatus",
          "ec2:DescribeVolumeAttribute",
          "ec2:CreateTags"
        ],
        "Resource" : "*"
      }
    ]
  })
}

# EKS 워커 노드 역할에 EBS 정책 부착
resource "aws_iam_role_policy_attachment" "eks_worker_policy_attach" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = aws_iam_policy.eks_worker_ebs_policy.arn
}

# EKS 워커 노드용 IAM 역할 생성
resource "aws_iam_role" "eks_worker_role" {
  name               = "${var.cluster_name}-eks-worker-role"
  assume_role_policy = data.aws_iam_policy_document.eks_worker_assume_role_policy.json
  tags = {
    Name = "${var.cluster_name}-eks-worker-role"
  }
}

# EKS 워커 노드 역할에 필요한 정책 부착 (AmazonEKSWorkerNodePolicy)
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_worker_role.name
}

# EKS CNI 정책 부착 (AmazonEKS_CNI_Policy)
resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_worker_role.name
}

# EC2 컨테이너 레지스트리 읽기 전용 정책 부착 (AmazonEC2ContainerRegistryReadOnly)
resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_worker_role.name
}

# S3 접근을 위한 IAM 정책 생성
resource "aws_iam_policy" "eks_s3_access_policy" {
  name        = "EKSWorkerS3AccessPolicy"
  description = "IAM policy for EKS worker nodes to access S3"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ],
        Resource = [
          "arn:aws:s3:::flink-kafka-test-s3",
          "arn:aws:s3:::flink-kafka-test-s3/*"
        ]
      }
    ]
  })
}

# EKS 워커 노드 역할에 S3 접근 정책 부착
resource "aws_iam_role_policy_attachment" "eks_worker_s3_policy" {
  policy_arn = aws_iam_policy.eks_s3_access_policy.arn
  role       = aws_iam_role.eks_worker_role.name
}

# EKS 워커 노드용 로드 밸런서 관리 정책 생성
resource "aws_iam_policy" "eks_worker_load_balancer_policy" {
  name        = "EKSWorkerLoadBalancerPolicy"
  description = "IAM policy for EKS worker nodes to manage Load Balancers"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:CreateTargetGroup",
          "elasticloadbalancing:DeleteTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets"
        ],
        Resource = "*"
      }
    ]
  })
}

# 워커 노드 역할에 로드 밸런서 정책 부착
resource "aws_iam_role_policy_attachment" "eks_worker_load_balancer_attachment" {
  policy_arn = aws_iam_policy.eks_worker_load_balancer_policy.arn
  role       = aws_iam_role.eks_worker_role.name
}

# NGINX Ingress Controller용 정책 생성
resource "aws_iam_policy" "nginx_ingress_policy" {
  name        = "nginx-ingress-policy"
  description = "IAM policy for NGINX Ingress Controller"
  policy      = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeInternetGateways"
        ],
        "Resource" : "*"
      }
    ]
  })
}

# ALB 컨트롤러 정책 생성
resource "aws_iam_policy" "alb_controller_policy" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "IAM policy for the AWS Load Balancer Controller"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "iam:CreateServiceLinkedRole",
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTags",
          "ec2:GetCoipPoolUsage",
          "ec2:DescribeCoipPools",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeListenerCertificates",
          "elasticloadbalancing:DescribeSSLPolicies",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeTags",
          "elasticloadbalancing:AddTags"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateTargetGroup"
        ],
        Resource = "*"
      }
    ]
  })
}

# ALB 컨트롤러 Assume Role 정책 생성
data "aws_iam_policy_document" "alb_controller_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["elasticloadbalancing.amazonaws.com"]
    }
  }
}

# ALB 컨트롤러 IAM 역할 생성
resource "aws_iam_role" "alb_controller_role" {
  name               = "${var.cluster_name}-alb-controller-role"
  assume_role_policy = data.aws_iam_policy_document.alb_controller_assume_role_policy.json
  tags = {
    Name = "${var.cluster_name}-alb-controller-role"
  }
}

# AWS Glue 접근을 위한 IAM 정책 부착 (Glue를 Iceberg 카탈로그로 사용하기 위함)
resource "aws_iam_role_policy_attachment" "eks_worker_glue_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
  role       = aws_iam_role.eks_worker_role.name
}
# ALB 컨트롤러 역할에 정책 부착
resource "aws_iam_role_policy_attachment" "alb_controller_policy_attachment" {
  policy_arn = aws_iam_policy.alb_controller_policy.arn
  role       = aws_iam_role.alb_controller_role.name
}
