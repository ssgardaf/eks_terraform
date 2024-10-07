# EKS 클러스터 이름 변수 (클러스터의 이름을 지정)
variable "cluster_name" {
  description = "The name of the EKS cluster"  # EKS 클러스터의 이름에 대한 설명
}

# VPC ID 변수 (EKS 클러스터가 생성될 VPC ID를 지정)
variable "vpc_id" {
  description = "The ID of the VPC where the EKS cluster will be created"  # EKS 클러스터가 생성될 VPC의 ID에 대한 설명
}

# 서브넷 ID 리스트 변수 (EKS 클러스터가 생성될 서브넷들의 ID를 지정)
variable "subnet_ids" {
  description = "A list of subnet IDs where the EKS cluster will be created"  # EKS 클러스터가 생성될 서브넷 ID들의 리스트에 대한 설명
  type        = list(string)  # 리스트 형식의 문자열 값
}
