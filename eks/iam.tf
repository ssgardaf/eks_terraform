# EKS 클러스터용 Assume Role 정책 생성 (EKS 서비스가 역할을 가질 수 있도록 설정)
data "aws_iam_policy_document" "eks_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]  # 역할을 할당하는 동작
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]  # EKS 서비스가 역할을 가져갈 수 있도록 설정
    }
  }
}

# EKS 클러스터 역할 생성 (IAM 역할을 클러스터에 할당)
resource "aws_iam_role" "eks_cluster_role" {
  name               = "${var.cluster_name}-eks-cluster-role"  # 역할 이름을 클러스터 이름 기반으로 설정
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role_policy.json  # Assume Role 정책 적용
  tags = {
    Name = "${var.cluster_name}-eks-cluster-role"  # 역할 이름 태그
  }
}

# EKS 클러스터에 필요한 정책 부착 (AmazonEKSClusterPolicy)
resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"  # 클러스터 관리 정책
  role       = aws_iam_role.eks_cluster_role.name  # 역할에 정책 부착
}

# EKS 서비스에 필요한 정책 부착 (AmazonEKSServicePolicy)
resource "aws_iam_role_policy_attachment" "eks_service_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"  # 서비스 관련 정책
  role       = aws_iam_role.eks_cluster_role.name  # 역할에 정책 부착
}

# EKS 워커 노드를 위한 Assume Role 정책 생성 (EC2 서비스 역할)
data "aws_iam_policy_document" "eks_worker_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]  # 역할을 할당하는 동작
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]  # EC2 서비스가 역할을 가져갈 수 있도록 설정
    }
  }
}

# EKS 워커 노드용 EBS 정책 생성 (EBS 관리 권한 부여)
resource "aws_iam_policy" "eks_worker_ebs_policy" {
  name        = "eks_worker_ebs_policy"  # 정책 이름
  description = "EKS worker nodes policy for managing EBS volumes"  # 정책 설명
  policy      = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",  # 허용
        "Action" : [  # EC2에서 EBS 관련 작업을 허용
          "ec2:CreateVolume",
          "ec2:DeleteVolume",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumeStatus",
          "ec2:DescribeVolumeAttribute",
          "ec2:CreateTags"
        ],
        "Resource" : "*"  # 모든 리소스에 대해 허용
      }
    ]
  })
}

# EKS 워커 노드 역할에 EBS 정책 부착
resource "aws_iam_role_policy_attachment" "eks_worker_policy_attach" {
  role       = aws_iam_role.eks_worker_role.name  # 역할에 정책 부착
  policy_arn = aws_iam_policy.eks_worker_ebs_policy.arn  # EBS 관리 정책 부착
}

# EKS 워커 노드용 IAM 역할 생성
resource "aws_iam_role" "eks_worker_role" {
  name               = "${var.cluster_name}-eks-worker-role"  # 역할 이름 설정
  assume_role_policy = data.aws_iam_policy_document.eks_worker_assume_role_policy.json  # EC2 서비스 역할 Assume Role 정책 적용
  tags = {
    Name = "${var.cluster_name}-eks-worker-role"  # 역할 이름 태그
  }
}

# EKS 워커 노드 역할에 필요한 정책 부착 (AmazonEKSWorkerNodePolicy)
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"  # 워커 노드 관리 정책
  role       = aws_iam_role.eks_worker_role.name  # 역할에 정책 부착
}

# EKS CNI 정책 부착 (AmazonEKS_CNI_Policy)
resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"  # 네트워크 인터페이스 정책
  role       = aws_iam_role.eks_worker_role.name  # 역할에 정책 부착
}

# EC2 컨테이너 레지스트리 읽기 전용 정책 부착 (AmazonEC2ContainerRegistryReadOnly)
resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"  # 컨테이너 레지스트리 읽기 정책
  role       = aws_iam_role.eks_worker_role.name  # 역할에 정책 부착
}

# NGINX Ingress Controller용 정책 생성
resource "aws_iam_policy" "nginx_ingress_policy" {
  name        = "nginx-ingress-policy"  # 정책 이름
  path        = "/"  # 경로 설정
  description = "IAM policy for NGINX Ingress Controller"  # 정책 설명
  policy      = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",  # 허용
        "Action" : [  # EC2 자원 관련 권한 부여
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeInternetGateways"
        ],
        "Resource" : "*"  # 모든 리소스에 대해 허용
      }
    ]
  })
}

# EKS 워커 노드용 로드 밸런서 관리 정책 생성
resource "aws_iam_policy" "eks_worker_load_balancer_policy" {
  name        = "EKSWorkerLoadBalancerPolicy"  # 정책 이름
  description = "IAM policy for EKS worker nodes to manage Load Balancers"  # 정책 설명
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",  # 허용
        Action   = [  # 로드 밸런서 및 타겟 그룹 관련 작업 허용
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
        Resource = "*"  # 모든 리소스에 대해 허용
      }
    ]
  })
}

# 워커 노드 역할에 로드 밸런서 정책 부착
resource "aws_iam_role_policy_attachment" "eks_worker_load_balancer_attachment" {
  policy_arn = aws_iam_policy.eks_worker_load_balancer_policy.arn  # 로드 밸런서 정책 ARN 참조
  role       = aws_iam_role.eks_worker_role.name  # 역할에 정책 부착
}

# ALB 컨트롤러 정책 생성 (로드 밸런서 관련 역할 및 정책 정의)
resource "aws_iam_policy" "alb_controller_policy" {
  name        = "AWSLoadBalancerControllerIAMPolicy"  # 정책 이름
  path        = "/"  # 경로 설정
  description = "IAM policy for the AWS Load Balancer Controller"  # 정책 설명
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # 다양한 EC2 및 로드 밸런서 관련 권한 설정
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
      # 보안 그룹 및 로드 밸런서 관련 작업
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

# ALB 컨트롤러 Assume Role 정책 생성 (ALB 서비스 역할 설정)
data "aws_iam_policy_document" "alb_controller_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]  # ALB 컨트롤러에 역할 할당
    principals {
      type        = "Service"
      identifiers = ["elasticloadbalancing.amazonaws.com"]  # ALB 서비스가 역할을 가질 수 있도록 설정
    }
  }
}

# ALB 컨트롤러 IAM 역할 생성
resource "aws_iam_role" "alb_controller_role" {
  name               = "${var.cluster_name}-alb-controller-role"  # 역할 이름 설정
  assume_role_policy = data.aws_iam_policy_document.alb_controller_assume_role_policy.json  # Assume Role 정책 적용
  tags = {
    Name = "${var.cluster_name}-alb-controller-role"  # 역할 이름 태그
  }
}

# ALB 컨트롤러 역할에 정책 부착
resource "aws_iam_role_policy_attachment" "alb_controller_policy_attachment" {
  policy_arn = aws_iam_policy.alb_controller_policy.arn  # ALB 컨트롤러 정책 ARN 참조
  role       = aws_iam_role.alb_controller_role.name  # 역할에 정책 부착
}
