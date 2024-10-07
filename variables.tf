# 리전 설정 변수
variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-2"  # 기본값으로 'us-east-2' 리전 설정
}


# VPC 이름을 정의하는 변수 (VPC의 명칭)
variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "streaming-vpc"
}

# VPC의 CIDR 블록을 정의하는 변수 (VPC 네트워크 범위)
variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# 퍼블릭 서브넷의 CIDR 블록을 정의하는 변수 (퍼블릭 서브넷의 네트워크 범위)
variable "public_subnet_cidr_blocks" {
  description = "CIDR blocks of the public subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

# 프라이빗 서브넷의 CIDR 블록을 정의하는 변수 (프라이빗 서브넷의 네트워크 범위)
variable "private_subnet_cidr_blocks" {
  description = "CIDR blocks of the private subnets"
  type        = list(string)
  default     = ["10.0.30.0/24", "10.0.40.0/24"]
}

# 서브넷이 배치될 가용 영역을 정의하는 변수 (AWS 리전 내의 가용 영역)
# 기본 리전: us-east-2 (오하이오 리전)
variable "availability_zones" {
  description = "Availability zones for subnets"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b"]
}

# EKS 클러스터의 이름을 정의하는 변수 (Kubernetes 클러스터 명칭)
variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
  default     = "streaming-eks"
}
