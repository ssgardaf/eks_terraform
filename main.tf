# AWS 프로바이더 설정 (리전을 us-east-2로 설정)
provider "aws" {
  region = var.aws_region   # 변수에서 리전을 참조하도록 변경
}

# VPC 모듈 설정
module "vpc" {
  source                    = "./vpc"   # VPC 모듈 소스 경로
  vpc_name                  = var.vpc_name      # VPC 이름을 변수에서 참조
  vpc_cidr                  = var.vpc_cidr      # VPC의 CIDR 블록을 변수에서 참조
  public_subnet_cidr_blocks = var.public_subnet_cidr_blocks  # 퍼블릭 서브넷 CIDR 블록을 변수에서 참조
  private_subnet_cidr_blocks = var.private_subnet_cidr_blocks # 프라이빗 서브넷 CIDR 블록을 변수에서 참조
  availability_zones        = var.availability_zones  # 가용 영역을 변수에서 참조
}

# EKS 모듈 설정 (Kubernetes 클러스터)
module "eks" {
  source        = "./eks"       # EKS 모듈 소스 경로
  cluster_name  = var.cluster_name      # EKS 클러스터 이름을 변수에서 참조
  vpc_id        = module.vpc.vpc_id     # VPC ID를 VPC 모듈에서 참조
  subnet_ids    = module.vpc.private_subnet_ids  # 서브넷 ID를 VPC 모듈에서 참조
}

# EC2 모듈을 호출하여 EC2 인스턴스를 배포
module "ec2" {
  source   = "./ec2"  # EC2 모듈 경로
  vpc_id   = module.vpc.vpc_id  # VPC ID 전달
  subnet_id = module.vpc.public_subnet_ids[0]  # 첫 번째 퍼블릭 서브넷 사용
}