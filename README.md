# Terraform 설치 및 사용 가이드

이 프로젝트는 HashiCorp의 Terraform을 설치하고 사용하는 방법을 안내합니다.

## 목차

- [프로젝트 소개](#프로젝트-소개)
- [파일 구조](#파일-구조)
- [설치 방법](#설치-방법)
- [Terraform 명령어](#terraform-명령어)

## 프로젝트 소개

Terraform은 인프라를 코드로 관리할 수 있도록 해주는 도구입니다. 클라우드 인프라 자원(AWS, GCP, Azure 등)을 자동으로 생성하고 관리할 수 있습니다. 이 가이드에서는 Ubuntu 환경에서 Terraform을 설치하는 과정을 설명합니다.


## 설치 방법

Ubuntu에서 Terraform을 설치하는 단계는 아래와 같습니다.

<pre>
<code>
sudo apt update
sudo apt install -y gnupg software-properties-common curl
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt install terraform

sudo apt-get install python3-venv
python3 -m venv awscli-env
source awscli-env/bin/activate
pip install awscli

aws configure
</code>
</pre>

이 명령어들은 Ubuntu에서 HashiCorp의 Terraform을 설치하는 과정을 설명합니다. 각 명령어를 순서대로 실행하면 Terraform이 시스템에 설치됩니다.

## Terraform 명령어

Terraform 설치 후 사용할 수 있는 몇 가지 기본 명령어입니다.

- 초기화 (init)**: Terraform 프로젝트 디렉토리에서 초기화를 수행하여 필요한 플러그인과 모듈을 다운로드합니다.

  ```bash
  terraform init

- 변경 사항을 미리 확인할 수 있는 명령어입니다. 실제로 인프라를 변경하지 않고, 어떤 리소스가 생성, 변경, 삭제될지 미리 보여줍니다.

  ```bash
  terraform plan

- 실제로 Terraform이 인프라를 배포하거나 수정하는 명령어입니다. plan에서 예측한 변경 사항을 적용하여 인프라를 업데이트합니다.

  ```bash
  terraform apply

- 현재 Terraform 상태 파일에 기록된 리소스 정보를 확인할 수 있는 명령어입니다.
  ```bash
  terraform show

- **배포된 모든 인프라 리소스를 제거하는 명령어입니다. 테스트 환경에서 리소스를 제거하거나, 인프라를 다시 설정해야 할 때 사용합니다.
  ```bash
  terraform destroy
