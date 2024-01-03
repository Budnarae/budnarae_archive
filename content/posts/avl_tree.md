+++
title = 'avl tree를 이용한 중복값 검사'
date = 2024-01-02T23:04:21Z
tags = ["data structure", "algorithm"]
+++

---
## avl tree를 사용한 중복 검사
---

### 1. 개요
본문은 보다 효율적으로 중복 여부를 검사하기 위해 고민한 경험을 공유하기 위해 작성되었다. 이 주제를 고민하게 된 계기는 [42 서울](https://42seoul.kr/seoul42/main/view)의 2서클 과제인 push_swap이었다. 당장 push_swap의 모든 것을 알 필요는 없다. 그 내용이 방대할 뿐더러, 이 글의 내용을 이해하는 데 필요하지도 않기 때문이다. 중요한 것은 push_swap을 구현하기 위해 데이터들의 중복 여부를 검사하는 알고리즘을 만들어야 한다는 사실이다. 보다 자세한 조건은 아래와 같다.

1. 데이터는 main 함수의 매개변수로 받는다.
2. 모든 데이터는 int형이다 (main의 매개변수로 받으면 char **형태로 들어오지만, atoi를 이용해 변환한다).
3. 모든 데이터는 서로 중복되지 않아야 한다.

가장 간단하게 떠올릴 수 있는 방법은 모든 데이터를 서로 비교하는 것이다.

```mermaid
flowchart  LR
	style  A  fill:#89cff0
	style  B  fill:#acb1d6
	A[16]  -->  B[32]
	B  -->  C[24]
	C  -->  D[...]
	D  -->  E[16]
```

```mermaid
flowchart  LR
	style  A  fill:#89cff0
	style  C  fill:#acb1d6
	A[16]  -->  B[32]
	B  -->  C[24]
	C  -->  D[...]
	D  -->  E[16]
```

```mermaid
flowchart  LR
	style  A  fill:#89cff0
	style  E  fill:#ff91af
	A[16]  -->  B[32]
	B  -->  C[24]
	C  -->  D[...]
	D  -->  E[16]
```

---

