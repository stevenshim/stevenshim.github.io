---
title: Route53 DNS Delegation (DNS 위임) 
published: false
---

# 개요
도메인 주소를 관리를 할 때, 주로 관리의 문제를 해소, 권한 분리 등의 주로 사용할 수 있는 방법으로, DNS Delegation (DNS 위임)을 사용할 수 있습니다.

이번 블로깅 내용은 AWS Route53에서 도메인 위임을 어떻게 진행하는지, 실무 환경에서 활용 방법, 위임 시 주의할 점은 무엇인지 다뤄보려고 합니다.

> 개념의 용어(Term)로, 영어는 `DNS Delegation`, `Domain Delegation`, 한글는 `도메인 위임`, `DNS 위임` 등 다양하게 쓰이는 것으로 보인다. `Domain Delegation` 혹은 `도메인 위임`이 틀린 용어인지는 모르겠으나, `DNS Delegation` 혹은 `DNS 위임` 이라는 용어를 더 많이 사용하는 것으로 보인다.   

## DNS Delegation의 개념
도메인 위임은 상위 도메인에서 동위 혹은 하위 도메인에 대한 권한/관리를 위임하는 내용입니다.

도메인에는 `.` (root) 도메인이 존재하며, 이 하위에는 `.com`, `.net`, `.io` 등 최상위 도메인이 있으며, 일반적으로 우리가 구매하는 도메인은 이 최상위 도메인에서 구매한 `some-name.io` 같은게 있습니다.

위 내용을 간소하여 설명하면 `.` -> `.io` -> `some-name.io` 순으로 위임이 되어있습니다.

구매한 도메인(some-name.io)에 대해서 혹은 구매한 도메인의 sub-domain 에 대해서 재위임을 할 수 있는데, 이렇게 다시 위임하여 관리의 목적을 달성할 수 있습니다.


## DNS 위임하기
> 보통 도메인을 구매하면 도메인 업체 서비스에서 DNS 관리 기능을 포함합니다.

여기서 부터는 우리가 구매한 도메인에 대해서 위임을 하므로, 최상위 도메인의 위임 과정은 잠시 잊고, 우리 도메인을 어떻게 위임하는지 알아보도록 하겠습니다.

DNS 위임은 `질의(DNS lookup)`해야할 Name Server를 위임하고 싶은 서버로 지정하는 것입니다.

즉, 동위 수준에서 위임, 혹은 하위 도메인(sub-domain)을 위임하는게 가능합니다.

(그림 위임된 DNS 서버에 질의 과정)

### Route53 에서 Hosted Zone 생성
Amazone Route53은 AWS의 DNS 서비스입니다. 
Amazon Rouet53의 Hosted Zone을 통하여 AWS에서 구매한 도메인 혹은 타 판매처에서 구매한 도메인에 대해 관리를 할 수 있습니다.

Hosted Zone 생성은 쉽습니다. 

> 어떠한 도메인에 대한 Hosted Zone 을 생성하는건 도메인 구매를 하지 않아도 가능합니다. 하지만 이 Hosted Zone으로 위임되어 있지 않으면 이 쪽으로 질의가 되지 않겠지요.

(생성 사진)


### Route53에서 DNS 위임

### 타 판매처에서 구매한 DNS를 Route53으로 위임

### 운영중인 서비스의 DNS 위임 시, 주의사항

### AWS Multi Account 환경에서 DNS 위임 전략
(개발, 스테이징, 운영 등 계정 분리로 환경 분리된 상황에서 도메인 위임)


## 관련 문서 
MS의 문서에 설명이 잘 되어있다.
https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/plan/reviewing-dns-concepts#delegation

https://docs.microsoft.com/ko-kr/azure/dns/dns-domain-delegation
