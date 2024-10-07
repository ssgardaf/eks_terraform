# VPC 리소스 생성 (CIDR 블록과 이름 설정)
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr     # VPC의 네트워크 범위를 변수에서 참조
  tags = {
    Name = var.vpc_name         # VPC 이름을 변수에서 참조
  }
}

# 인터넷 게이트웨이 리소스 생성 (VPC에 연결)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id      # 인터넷 게이트웨이를 VPC에 연결
  tags = {
    Name = "${var.vpc_name}-igw"  # 인터넷 게이트웨이 이름 설정
  }
}

# 퍼블릭 서브넷 리소스 생성 (가용 영역 및 CIDR 블록 설정)
resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidr_blocks)  # 퍼블릭 서브넷 개수 정의
  vpc_id            = aws_vpc.main.id                        # VPC ID 참조
  cidr_block        = var.public_subnet_cidr_blocks[count.index]  # 서브넷의 CIDR 블록 설정
  availability_zone = var.availability_zones[count.index]         # 가용 영역 설정
  tags = {
    Name = "${var.vpc_name}-public-${count.index + 1}"   # 퍼블릭 서브넷 이름 설정
  }
  map_public_ip_on_launch = true  # 퍼블릭 IP 자동 할당 활성화
}

# 프라이빗 서브넷 리소스 생성 (가용 영역 및 CIDR 블록 설정)
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidr_blocks)  # 프라이빗 서브넷 개수 정의
  vpc_id            = aws_vpc.main.id                        # VPC ID 참조
  cidr_block        = var.private_subnet_cidr_blocks[count.index]  # 서브넷의 CIDR 블록 설정
  availability_zone = var.availability_zones[count.index]         # 가용 영역 설정
  tags = {
    Name = "${var.vpc_name}-private-${count.index + 1}"  # 프라이빗 서브넷 이름 설정
  }
  map_public_ip_on_launch = false  # 퍼블릭 IP 자동 할당 비활성화
}

# 퍼블릭 라우팅 테이블 생성
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id  # VPC ID 참조
  tags = {
    Name = "${var.vpc_name}-public"  # 퍼블릭 라우팅 테이블 이름 설정
  }
}

# 퍼블릭 서브넷과 라우팅 테이블을 연결
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)  # 퍼블릭 서브넷 개수 정의
  subnet_id      = aws_subnet.public[count.index].id  # 서브넷 ID 참조
  route_table_id = aws_route_table.public.id          # 라우팅 테이블 ID 참조
}

# 프라이빗 라우팅 테이블 생성
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id  # VPC ID 참조
  tags = {
    Name = "${var.vpc_name}-private"  # 프라이빗 라우팅 테이블 이름 설정
  }
}

# 프라이빗 서브넷과 라우팅 테이블을 연결
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)  # 프라이빗 서브넷 개수 정의
  subnet_id      = aws_subnet.private[count.index].id  # 서브넷 ID 참조
  route_table_id = aws_route_table.private.id          # 라우팅 테이블 ID 참조
}

# 퍼블릭 라우팅 테이블에 인터넷 게이트웨이 경로 추가
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id   # 퍼블릭 라우팅 테이블 ID 참조
  destination_cidr_block = "0.0.0.0/0"                 # 모든 트래픽에 대해 적용
  gateway_id             = aws_internet_gateway.igw.id # 인터넷 게이트웨이 ID 참조
}

# NAT 게이트웨이 생성 (프라이빗 서브넷에서 외부 인터넷 연결)
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat.id   # 할당된 EIP(Elastic IP) ID 참조
  subnet_id     = aws_subnet.public[0].id  # 첫 번째 퍼블릭 서브넷에 NAT 게이트웨이 설정
}

# Elastic IP 생성 (NAT 게이트웨이용)
resource "aws_eip" "nat" {
  domain = "vpc"  # VPC와 연결된 EIP 생성
}

# 프라이빗 라우팅 테이블에 NAT 게이트웨이 경로 추가
resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.private.id  # 프라이빗 라우팅 테이블 ID 참조
  destination_cidr_block = "0.0.0.0/0"                 # 모든 트래픽에 대해 적용
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id  # NAT 게이트웨이 ID 참조
}
