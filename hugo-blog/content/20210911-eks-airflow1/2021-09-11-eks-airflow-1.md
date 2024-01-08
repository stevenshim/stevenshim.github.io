+++
title = 'EKS에 Airflow 2.x (운영에 쓸만한 수준으로) 구축하기 - Part 1 설치전 고려 사항들'
date = 2021-09-11T00:00:00+09:00
draft = true
+++

# 들어가며
이번 글은 운영환경에서도 쓸만한 수준의 Airflow 2.x 를 EKS 환경에 구축하는 내용을 다뤄보려고 합니다.<br>
과거에 Airflow 1.x 을 파이프라인 도구 테스트 목적으로 아주 간단하게 사용한 경험은 있지만, 데이터 엔지니어만큼 심도 있게 사용해본 적도 없거니와, 신규 기능이 런칭을  것을 계속 확인한 것도 아니기에 자세히 알고 있진 않았습니다.

최근 개발팀의 요구 사항으로 Airflow 2.x 를 EKS에 구축을 하게 되었는데, Airflow의 특징, AWS와 EKS(Kubernetes)에 대한 기초 이상 수준의 이해가 필요하다 느껴져, 구축 경험을 글로 적어봅니다.

### Prerequisites
본 주제의 내용을 동일하게 구축하시려면, 아래 내용이 먼저 준비되어야 합니다.
* AWS의 EKS 환경이 필요합니다.
    * EKS 환경의 CNI는 Amazon [VPC CNI](https://github.com/aws/amazon-vpc-cni-k8s) 를 사용합니다.
    * EKS 환경에서 IRSA(IAM Role for Service Account)를 활용합니다.
    * EKS 환경에서 SGP(Security Group for Pod)를 활용합니다.
* kubectl 및 helm 명령어를 수행할 수 있는 환경이 필요합니다.
* EKS(Kubernetes)에 대한 기초 수준의 이해가 필요합니다.

# Airflow2
우선 Airflow의 기본 구조를 설명하는 아래 아키텍쳐 다이어그램을 보시면 빠른 이해에 도움이 되라라 생각합니다.

![](/images/2021-09-11-eks-airflow/airflow-architecture.png)<br>
*Figure 1 - [Airflow2 Architecture]((https://airflow.apache.org/docs/apache-airflow/stable/concepts/overview.html))*

Airflow의 각 컴포넌트 / 기능의 설명입니다.
* Webserver - UI 콘솔을 제공하며, DAG 실행 현황, Connection 관리 등 Airflow 전반을 확인하는 컴포넌트입니다. 
* Scheduler - DAG을 통해 구성된 task의 스케줄을 관리합니다. (triggering & submitting tasks)
* Metadata Database - Airflow의 전반적인 메타데이터(Connections 정보, DAG 상태 등)를 저장합니다.
* Executor - Executor는 task 동작을 관리합니다. Executor는 여러 종류가 있는데요, 실제 운영 환경에서 쓸만한 Executor를 구성하기는 까다로울 수 있습니다.
* Worker - Executor 설정을 기반으로, Task를 실제 수행하는 것이 worker입니다.
* DAG(Directed Acyclic Graph) - Task 정보, Task의 의존성, 파라미터 정의, Task 파이프라인 등을 Python 기반 코드로 구성하는 Airflow의 코어 기능입니다.
* DAG Directory - Scheduler와 Executor가 동일하게 읽어야 합니다.

## 구축 목표
가급적 운영환경에서도 쓸만한 수준의 아키텍쳐를 완성할 수 있도록 목표를 설정했습니다.
* Airflow 2.x를 EKS 환경에 설치합니다.
* EKS 환경인 만큼 executor는 Kubernetes Executor 기반으로 동작하게 합니다.
* Metadata Database는 RDS를 사용합니다.

* Prerequisites에 명시한 것처럼
    * EKS의 CNI는 AWS VPC CNI를 사용합니다.
    * Airflow Pod는 EKS의 [IRSA(IAM Role for Service Account)](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) 를 활용합니다.
    * Airflow Pod는 EKS의 [SGP(Security Group for Pods)](https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html) 를 활용합니다.

#### Kubernetes Executor 사용 이유
Executor는 Scheduler에 의해서 task를 실행하기 위한 인터페이스를 제공합니다.<br>
Helm chart로 배포하는 Airflow 2.x 에는 현재 
[LocalExecutor](https://airflow.apache.org/docs/apache-airflow/stable/executor/local.html), 
[CeleryExecutor](https://airflow.apache.org/docs/apache-airflow/stable/executor/celery.html), 
[CeleryKubernetesExecutor](https://airflow.apache.org/docs/apache-airflow/stable/executor/celery_kubernetes.html), 
[KubernetesExecutor](https://airflow.apache.org/docs/apache-airflow/stable/executor/kubernetes.html) 
4가지 종류가 있는데, 그 중 KubernetesExecutor는 Kubernetes 환경을 아주 이상적으로 사용하게 해주는 Executor입니다.

![](/images/2021-09-11-eks-airflow/kubernetes-executor-architecture.png)<br>
*Figure 2 - [Kubernetes Executor Architecture](https://airflow.apache.org/docs/apache-airflow/stable/executor/kubernetes.html)*

위 *Figure 2*를 보시면 Scheduler는 실행해야 할 DAG이 있을 때, Kubernetes Executor를 통하여 dynamic하게 Worker Pod를 생성하여 task를 처리한 뒤, Pod가 소멸되는 방식입니다.

즉, 필요에 의해서 Worker Pod가 생성되고, task가 종료되면 소멸합니다.

이런 방식은 Kubernetes 환경에서 리소스를 매우 효율적으로 사용할 수 있는 방법입니다.<br>
CeleryExecutor와 다르게 Kubernetes Executor는 수행되는 task가 없는 상황에서 worker(Pod)가 항상 유휴자원으로 남을 필요도 없습니다.

#### Metadata Database로 RDS를 사용하는 이유
일정 규모 이상의 엔지니어링 조직을 갖춘 회사라면, DB를 전문적으로 운영하는 조직이 따로 있는 경우가 흔합니다. 
물론 Airflow helm chart를 활용하면 Kubernetes 환경에 postgresql 혹은 mysql 기반의 DB를 Pod로 자동 구축을 해줍니다.<br>
하지만 helm chart를 통해에서 Pod 기반으로 생성된 Metadata Database를 DBA 혹은 DB운영 담당자가 기본으로 삼는 관리 방식을 벗어나기 쉽습니다.<br>
혹시라도 개발팀에서 직접 Metadata Database 까지 운영해야 한다면, 백업/복구, 버그패치, Failover 등도 고려해야 하므로 운영 환경에 적합한지 고민해 볼 필요가 있습니다.

>[Airflow Production Guide](https://airflow.apache.org/docs/helm-chart/stable/production-guide.html) 는 Airflow를 운영(Production)환경에 구축할 때 고려할만한 사항들을 소개하고 있습니다.

#### EKS의 [IRSA(IAM Role for Service Account)](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) 를 활용하는 이유
Worker Pod가 task를 수행하다보면, AWS 관리형 서비스를 사용하게 될 수도 있습니다.<br>
EKS 환경에서는 IRSA를 활용해 Pod에 IAM Role을 할당할 수 있습니다.<br>
Pod에 직접 Access Key를 넣는 방식은 보안적으로 좋지 않기 때문에 AWS를 사용하고 있으면서, EKS를 쓰는 환경이라면, IRSA를 도입해야 할 수밖에 없습니다.

예를 들어, task 중 S3에서 object를 가져오는 경우에도 IAM 권한이 필요합니다.<br>
Task가 산출물로 DynamoDB 혹은 SQS 등에 데이터를 적재한다면 역시 권한이 필요합니다.


#### EKS의 [VPC CNI](https://github.com/aws/amazon-vpc-cni-k8s) 와 [SGP(Security Group for Pods)](https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html)
이 부분은 EKS 사용자마다 사정이 다를 수 있습니다. AWS VPC CNI를 사용한다면, SGP(Security Group for Pod)를 이용해 Pod의 네트워크 보안 정책을 관리할 수 있습니다.

하지만 EKS 기반에 SGP를 사용하면서, helm chart로 Airflow를 설치하면 추가로 손봐야 할 설정이 꽤 많습니다.<br>
설치 및 셋업 과정에 이 부분도 자세히 설명하려고 합니다.


# Part 1 마무리
Airflow 사용자마다 상황이 다르겠지만, AWS 환경에서 EKS를 기반으로 Airflow를 구축하는 경우는, 위에 언급된 비슷한 고민을 할 것이라 생각합니다.<br>
어떤 분들에게는 과도하게 느껴지실 수도 있고, 반대로 너무 심플하게 느끼실 수도 있습니다.<br>
적당히 규모 있는 수준이란 기준도 애매하지만, 어느 회사나 한 번쯤 검토해보았을 사안들을 먼저 소개했습니다.

다음 Part2 에서는 본격적으로 설치를 시작해볼까 합니다.

