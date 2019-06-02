---
title: AWS CLI Profile 사용하기, AWS CLI 여러 계정 Config 설정 
published: true
---
**Table of Contents**
- [들어가며](#%EB%93%A4%EC%96%B4%EA%B0%80%EB%A9%B0)
- [Prerequisites](#prerequisites)
- [AWS CLI Profile 설정 (기초)](#aws-cli-profile-%EC%84%A4%EC%A0%95-%EA%B8%B0%EC%B4%88)
  - [기본 Profile 설정하기](#%EA%B8%B0%EB%B3%B8-profile-%EC%84%A4%EC%A0%95%ED%95%98%EA%B8%B0)
  - [Profile 추가하기 (Access Key Pair)](#profile-%EC%B6%94%EA%B0%80%ED%95%98%EA%B8%B0-access-key-pair)
- [AWS CLI Profile 설정 (중급)](#aws-cli-profile-%EC%84%A4%EC%A0%95-%EC%A4%91%EA%B8%89)
  - [Profile 추가하기 (Role ARN)](#profile-%EC%B6%94%EA%B0%80%ED%95%98%EA%B8%B0-role-arn)
  - [EC2에 할당된 IAM Role 을 이용하여 Profile 추가하기 (Role ARN)](#ec2%EC%97%90-%ED%95%A0%EB%8B%B9%EB%90%9C-iam-role-%EC%9D%84-%EC%9D%B4%EC%9A%A9%ED%95%98%EC%97%AC-profile-%EC%B6%94%EA%B0%80%ED%95%98%EA%B8%B0-role-arn)
  - [Source profile 에 다른 profile 사용하기](#source-profile-%EC%97%90-%EB%8B%A4%EB%A5%B8-profile-%EC%82%AC%EC%9A%A9%ED%95%98%EA%B8%B0)

# 들어가며
AWS CLI 에는 하나 이상의 Profile 설정이 가능하고, 각 Profile 마다 Access Keypair 혹은 Assume Role 을 지정할 수 있다.  
이 방식으로 다양한 Use-case 를 만들 수 있다.
* 각 Profile 마다 서로 다른 AWS Account의 Access Key Pair 를 설정
* 기본 Profile 에는 Read 권한만 설정 후, 추가 Profile 에 더 많은 권한을 설정.
* Assume Role 을 활용하여 내 계정, 혹은 다른 계정의 Role 을 위임 받는 방식으로 관리

# Prerequisites
* [AWS CLI 설치](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
* Access Key Pair 준비
* IAM Role 준비 - Assume Role 방식의 profile 설정 원할 경우 (중급 내용)

# AWS CLI Profile 설정 (기초)
## 기본 Profile 설정하기
AWS CLI의 default profile 설정은 아래 명령어로 수행할 수 있다.

```bash
$ aws configure

AWS Access Key ID [None]        : AKIAIOSFOD111EXAMPLE
AWS Secret Access Key [None]    : wJalrXUtnFEMI/K7MDENG/bPxR111EXAMPLEKEY
Default region name [None]      : ap-northeast-2
Default output format [None]    : json
```
위 명령어로 설정한 Profile 정보는 아래 경로에 저장된다.

**Linux & Mac**
> ~/.aws/config  
> ~/.aws/credentials

**Windows**
> %USERPROFILE%\.aws\config  
> %USERPROFILE%\.aws\credentials

## Profile 추가하기 (Access Key Pair)
만약 다른 User 혹은 다른 계정의 Access Key Pair 를 추가하고자 할 때는 아래처럼 옵션으로 추가할 수 있다.
```bash
$ aws configure --profile user-a

AWS Access Key ID [None]        : AKIAIOSFOD111EXAMPLE2
AWS Secret Access Key [None]    : wJalrXUtnFEMI/K7MDENG/bPxR111EXAMPLEKEY2
Default region name [None]      : us-west-2
Default output format [None]    : json
```

추가된 Profile 의 Credential 로 AWS CLI 명령을 수행하려면 `--profile` 옵션을 사용한다.
```bash
$ aws s3 ls --profile user-a
```

`.aws/config` 와 `.aws/credentials` 파일을 열어서 저장된 결과를 보면 아래와 같다.  

**.aws/config 파일**
```bash
[default]
region=ap-northeast-2
output=json

[profile user-a]
region=us-west-2
output=json
```

**.aws/credentials 파일**
```bash
[default]
aws_access_key_id=AKIAIOSFOD111EXAMPLE
aws_secret_access_key=wJalrXUtnFEMI/K7MDENG/bPxR111EXAMPLEKEY

[user1]
aws_access_key_id=AKIAIOSFOD111EXAMPLE2
aws_secret_access_key=wJalrXUtnFEMI/K7MDENG/bPxR111EXAMPLEKEY2
```

# AWS CLI Profile 설정 (중급)
중급으로 분리한 이유는, 아래 내용은 IAM 에 대해 조금 더 이해하고 있어야 하기 때문이다.  
IAM 을 잘 다루는 사람이라면 아래 내용은 매우 쉽게 느껴질 것이다.

## Profile 추가하기 (Role ARN)
IAM Role 역시 profile 로 등록할 수 있다.  
이 경우는 IAM User 가 Role 권한을 위임 받을 수 있도록 **Assume Role 설정이 사전에 되어 있어야 한다.**  
IAM Role 준비되지 않았다면, 아래 문서를 보고 IAM Role 을 준비하자.  
[IAM User 에게 위임 가능한 IAM Role 생성하기.](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-user.html) 

Role ARN 을 추가하려면 config 를 직접 수정해야 한다.  
`role-a` 설정을 추가하도록 하자.

```bash
$ vi ~/.aws/config

[default]
region=ap-northeast-2
output=json

[profile user-a]
region=us-west-2
output=json

[profile role-a]
role_arn = arn:aws:iam::0774477123456:role/admin_role
source_profile = default
region = ap-northeast-2
```

Role ARN 을 Profile 로 등록하는 경우 *너무나도 당연하지만* Access Key Pair를 등록하는 과정과 2가지 차이점이 있다.
* `source_profie = default` 설정
  * Role 을 Assume 하려면 Assume 할 Credential 이 필요하다.
* ~/.aws/credentials 에는 credentail 설정을 추가할 필요가 없음


## EC2에 할당된 IAM Role 을 이용하여 Profile 추가하기 (Role ARN)
> 이 use-case 는 EC2 내부에서 EC2에 할당된 Role을 이용하는 AWS CLI를 설정할 경우이다.  

간혹 Bastion Host 나, Admin 전용 EC2 등에 IAM Role 을 할당하여 사용하는 경우가 있다.  
위와 같은 EC2 내부에서 AWS CLI 를 사용 할 경우, IAM User Credential 없이 Instance Profile (Ec2InstanceMetadata) 를 가져다가 사용할 수 있다.

**~/.aws/config 를 수정해보자.**
```bash
[default]
region = ap-northeast-2

[profile role-b]
role_arn = arn:aws:iam::1234567890123:role/another_account_role
credential_source = Ec2InstanceMetadata
region = ap-northeast-2
```
`credential_source = Ec2InstanceMetadata` 설정을 통해 EC2 에 할당된 IAM Role 을 사용할 수 있다.

## Source profile 에 다른 profile 사용하기
이 use-case 는 일반적이진 않을 수 있다. 
* 다양한 사람과 co-work 하는 환경에서 조금 더 복잡한 권한 체계를 사용하는 경우
* 내 PC 에서 Role A의 권한을 위임받고, 바로 다시 Role B의 권한을 이어서 위임 받는 경우

Role Assuming 은 꼭 IAM User 의 Credential 에서 한 단계만 가능한것은 아니다.  
IAM User -> Role A -> Role B assuming 도 가능한데, 이해를 돕고자 아래 Figure 1-1 을 추가한다.

**Figure 1-1**  
![](img/2019-06-02-awscli-profile/assume-role-to-role.png)  

그럼 `source_profile` 을 설정해보자.

**~/.aws/config 를 수정해보자.**
```bash
[default]
output = json
region = ap-northeast-2

[profile role-a]
role_arn = arn:aws:iam::0774477123456:role/admin_role
source_profile = default
region = ap-northeast-2

[profile target]
role_arn = arn:aws:iam::1234567890123:role/another_account_role
source_profile = role-a
region = ap-northeast-2
```

이 처럼,
* `role-a` 의 `source_profile` 은 `default` 로 설정 하고,
* `role-b` 의 `source_profile` 은 `role-a` 로 설정이 가능하다.

이 경우에도 `--profile` 옵션 역시 평소와 같이 쓰면 된다.
```bash
## default profile 을 사용한 명령어
$ aws s3 

## role-a profile 을 사용한 명령어
$ aws s3 --profile role-a

## target profile 을 사용한 명령어 
$ aws s3 --profile target
```
