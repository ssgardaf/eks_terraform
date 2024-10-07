# EKS 클러스터 보안 그룹 생성 (클러스터와 노드 간의 통신 허용)
resource "aws_security_group" "eks_cluster" {
  name        = "streaming-cluster-sg"  # 보안 그룹 이름
  description = "Cluster communication with worker nodes"  # 보안 그룹 설명
  vpc_id      = var.vpc_id  # VPC ID를 변수에서 참조

  tags = {
    Name = "streaming-cluster-sg"  # 보안 그룹 태그
  }
}

# 클러스터로의 인바운드 트래픽 허용 규칙 (워크 노드가 클러스터 API 서버와 통신할 수 있도록 허용)
resource "aws_security_group_rule" "cluster_inbound" {
  description              = "Allow worker nodes to communicate with the cluster API Server"  # 규칙 설명
  from_port                = 443  # HTTPS 포트
  protocol                 = "tcp"  # TCP 프로토콜
  security_group_id        = aws_security_group.eks_cluster.id  # 클러스터 보안 그룹 ID
  source_security_group_id = aws_security_group.eks_nodes.id  # 워커 노드 보안 그룹 ID
  to_port                  = 443  # 클러스터 API 서버와의 통신 허용
  type                     = "ingress"  # 인바운드 트래픽 허용
}

# 클러스터로부터의 아웃바운드 트래픽 허용 규칙 (클러스터가 워커 노드와 통신할 수 있도록 허용)
resource "aws_security_group_rule" "cluster_outbound" {
  description              = "Allow cluster API Server to communicate with the worker nodes"  # 규칙 설명
  from_port                = 1024  # 아웃바운드 트래픽 시작 포트
  protocol                 = "tcp"  # TCP 프로토콜
  security_group_id        = aws_security_group.eks_cluster.id  # 클러스터 보안 그룹 ID
  source_security_group_id = aws_security_group.eks_nodes.id  # 워커 노드 보안 그룹 ID
  to_port                  = 65535  # 아웃바운드 트래픽 허용 범위
  type                     = "egress"  # 아웃바운드 트래픽 허용
}

# EKS 노드 보안 그룹 생성 (클러스터 내 모든 노드용 보안 그룹)
resource "aws_security_group" "eks_nodes" {
  name        = "${var.cluster_name}-node-sg"  # 노드 보안 그룹 이름
  description = "Security group for all nodes in the cluster"  # 보안 그룹 설명
  vpc_id      = var.vpc_id  # VPC ID

  # 노드의 아웃바운드 트래픽을 허용 (모든 IP 주소로 트래픽 허용)
  egress {
    from_port   = 0  # 시작 포트 (모든 포트 허용)
    to_port     = 0  # 끝 포트 (모든 포트 허용)
    protocol    = "-1"  # 모든 프로토콜 허용
    cidr_blocks = ["0.0.0.0/0"]  # 모든 IP 주소 허용
  }

  tags = {
    Name                                           = "${var.cluster_name}-node-sg"  # 보안 그룹 태그
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"  # Kubernetes 클러스터 소유 태그
  }
}

# 노드 간 내부 통신을 허용하는 보안 그룹 규칙 (노드 간의 모든 트래픽 허용)
resource "aws_security_group_rule" "nodes_internal" {
  description              = "Allow nodes to communicate with each other"  # 규칙 설명
  from_port                = 0  # 시작 포트
  protocol                 = "-1"  # 모든 프로토콜 허용
  security_group_id        = aws_security_group.eks_nodes.id  # 노드 보안 그룹 ID
  source_security_group_id = aws_security_group.eks_nodes.id  # 노드 간 통신을 위한 동일 보안 그룹
  to_port                  = 65535  # 끝 포트
  type                     = "ingress"  # 인바운드 트래픽 허용
}

# 클러스터 제어 플레인에서 워커 노드로의 통신을 허용하는 보안 그룹 규칙
resource "aws_security_group_rule" "nodes_cluster_inbound" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"  # 규칙 설명
  from_port                = 1025  # 시작 포트
  protocol                 = "tcp"  # TCP 프로토콜
  security_group_id        = aws_security_group.eks_nodes.id  # 노드 보안 그룹 ID
  source_security_group_id = aws_security_group.eks_cluster.id  # 클러스터 보안 그룹 ID
  to_port                  = 65535  # 끝 포트
  type                     = "ingress"  # 인바운드 트래픽 허용
}
