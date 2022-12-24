<p align="center">
    <img width="200px;" src="https://raw.githubusercontent.com/woowacourse/atdd-subway-admin-frontend/master/images/main_logo.png"/>
</p>
<p align="center">
  <img alt="npm" src="https://img.shields.io/badge/npm-%3E%3D%205.5.0-blue">
  <img alt="node" src="https://img.shields.io/badge/node-%3E%3D%209.3.0-blue">
  <a href="https://edu.nextstep.camp/c/R89PYi5H" alt="nextstep atdd">
    <img alt="Website" src="https://img.shields.io/website?url=https%3A%2F%2Fedu.nextstep.camp%2Fc%2FR89PYi5H">
  </a>
  <img alt="GitHub" src="https://img.shields.io/github/license/next-step/atdd-subway-service">
</p>

<br>

# 인프라공방 샘플 서비스 - 지하철 노선도

<br>

## 🚀 Getting Started

### Install
#### npm 설치
```
cd frontend
npm install
```
> `frontend` 디렉토리에서 수행해야 합니다.

### Usage
#### webpack server 구동
```
npm run dev
```
#### application 구동
```
./gradlew clean build
```
<br>

## 미션

* 미션 진행 후에 아래 질문의 답을 작성하여 PR을 보내주세요.


### 1단계 - 쿼리 최적화

1. 인덱스 설정을 추가하지 않고 아래 요구사항에 대해 200ms 이하(M1의 경우 2s)로 반환하도록 쿼리를 작성하세요.

- 활동중인(Active) 부서의 현재 부서관리자 중 연봉 상위 5위안에 드는 사람들이 최근에 각 지역별로 언제 퇴실했는지 조회해보세요. (사원번호, 이름, 연봉, 직급명, 지역, 입출입구분, 입출입시간)


#### 드라이빙 테이블 모수를 줄여본다
- 필요한 column 과 이를 조인할 테이블을 먼저 찾는다.
```
사원번호 -> manager -> employee_id
이름 -> employee -> last_name
연봉 -> salary -> annual_income
직급명 -> position -> position_name
지역 -> record -> region
입출입구분 -> record -> record_symbol
입출입시간 -> record -> time
```

- '활동' '부서' '관리자' '연봉 상위 5위' 키워드를 통해 from 절의 subquery 로 department, manager, position (직급명 조회를 위해), employee, salary 테이블을 조인한다.
  - 해당 테이블 조인시 데이터가 가장 적은 department 를 드라이빙 테이블로 시작하여 조인함.
- 연봉 상위 5위의 활동 부서 관리자를 찾아 왔으면, record 테이블 (드리븐 테이블)과 다시 조인하고, 퇴실 여부로 체크하여 반환한다. 

#### [쿼리]
```mysql
select
    top_5_manager.employee_id as 사원번호,
    top_5_manager.last_name as 이름,
    top_5_manager.annual_income as 연봉,
    top_5_manager.position_name as 직급명,
    r.time as 입출입시간,
    r.region as 지역,
    r.record_symbol as 입출입구분
from (
         select
             m.employee_id,
             e.last_name,
             s.annual_income,
             p.position_name
         from department as d
                  inner join manager as m on d.id = m.department_id
                  inner join position as p on p.id = m.employee_id
                  inner join employee as e on e.id = m.employee_id
                  inner join salary as s on s.id = e.id
         where d.note = 'active'
           and p.position_name = 'manager'
           and now() between m.start_date and m.end_date
           and now() between p.start_date and p.end_date
           and now() between s.start_date and s.end_date
         order by s.annual_income desc
         limit 5
     ) as top_5_manager
         inner join record r on r.employee_id = top_5_manager.employee_id and r.record_symbol = 'o'
order by top_5_manager.annual_income desc; 
```

#### [실행계획]
![image](https://user-images.githubusercontent.com/52458039/209435026-53d06708-4593-4579-925c-d38052f48464.png)


#### [Visual Explain]
![image](https://user-images.githubusercontent.com/52458039/209435042-a84a4a09-83ed-4391-86a2-3e432a7eaabd.png)

---

### 2단계 - 인덱스 설계

1. 인덱스 적용해보기 실습을 진행해본 과정을 공유해주세요

---

### 추가 미션

1. 페이징 쿼리를 적용한 API endpoint를 알려주세요
