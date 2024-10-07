# EKS 클러스터 ID 출력
output "cluster_id" {
  description = "The ID of the EKS cluster"  # EKS 클러스터 ID에 대한 설명
  value       = aws_eks_cluster.eks.id       # 클러스터의 ID 값 출력
}

# EKS 클러스터 엔드포인트 출력
output "cluster_endpoint" {
  description = "The endpoint of the EKS cluster"  # EKS 클러스터 엔드포인트에 대한 설명
  value       = aws_eks_cluster.eks.endpoint       # 클러스터의 API 엔드포인트 URL 출력
}

# EKS 클러스터의 ARN 출력
output "cluster_arn" {
  description = "The ARN of the EKS cluster"  # EKS 클러스터 ARN에 대한 설명
  value       = aws_eks_cluster.eks.arn       # 클러스터의 ARN 값 출력
}

# EKS 노드 그룹의 ARN 출력
output "node_group_arn" {
  description = "The ARN of the EKS node group"  # EKS 노드 그룹 ARN에 대한 설명
  value       = aws_eks_node_group.node_group.arn  # 노드 그룹의 ARN 값 출력
}

# EKS 클러스터 이름 출력
output "cluster_name" {
  value = aws_eks_cluster.eks.name  # 클러스터의 이름 출력
}

# EKS 클러스터의 인증 기관 데이터 출력 (API 접근을 위한 인증서)
output "cluster_certificate_authority_data" {
  value = aws_eks_cluster.eks.certificate_authority[0].data  # 인증서 데이터 출력
}
