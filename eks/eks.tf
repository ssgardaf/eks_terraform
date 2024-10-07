# EKS 클러스터 리소스 생성
resource "aws_eks_cluster" "eks" {
  name     = var.cluster_name                    # 클러스터 이름을 변수에서 참조
  role_arn = aws_iam_role.eks_cluster_role.arn   # EKS 클러스터에 할당된 IAM 역할 ARN

  # VPC 설정 (서브넷 및 보안 그룹 설정)
  vpc_config {
    subnet_ids         = var.subnet_ids                          # 클러스터에 사용할 서브넷 IDs
    security_group_ids = [aws_security_group.eks_cluster.id]     # EKS 클러스터용 보안 그룹 ID
  }

  # IAM 역할 정책 부착 의존성 설정
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy_attachment,  # 클러스터에 필요한 IAM 정책
    aws_iam_role_policy_attachment.eks_service_policy_attachment   # 서비스 정책
  ]
}

# EKS 노드 그룹 리소스 생성
resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.eks.name  # 연결할 EKS 클러스터 이름
  node_group_name = "${var.cluster_name}-node-group"  # 노드 그룹 이름 (클러스터 이름 기반)
  node_role_arn   = aws_iam_role.eks_worker_role.arn  # 노드에 할당된 IAM 역할 ARN
  subnet_ids      = var.subnet_ids             # 노드 그룹에 사용할 서브넷 IDs

  # 오토스케일링 설정
  scaling_config {
    desired_size = 5    # 기본적으로 1개의 노드를 실행
    max_size     = 10    # 최대 5개의 노드를 실행할 수 있음
    min_size     = 1    # 최소 1개의 노드를 유지
  }

  # 노드 그룹의 AMI(이미지) 타입 설정
  ami_type       = "AL2_x86_64"  # Amazon Linux 2 (x86_64 아키텍처)
  capacity_type  = "ON_DEMAND"   # 온디맨드 인스턴스 사용 (SPOT을 사용하려면 SPOT으로 변경)
  disk_size      = 20            # 각 노드의 루트 볼륨 크기 (20GB)
  instance_types = ["t3.medium"] # 인스턴스 타입 설정 (t3.medium)

  # 의존성 설정 (IAM 정책 및 클러스터 생성 후 동작)
  depends_on = [
    aws_eks_cluster.eks,                                     # EKS 클러스터 생성 후 실행
    aws_iam_role_policy_attachment.eks_worker_node_policy,   # 워커 노드에 필요한 IAM 정책
    aws_iam_role_policy_attachment.eks_cni_policy,           # CNI 정책 부착
    aws_iam_role_policy_attachment.ec2_container_registry_read_only  # EC2 컨테이너 레지스트리 읽기 전용 정책
  ]
}
