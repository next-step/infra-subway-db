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

select
    tt1.employee_id AS 사원번호,
    ANY_VALUE(tt3.last_name) AS 이름,
    ANY_VALUE(tt1.annual_income) AS 연봉,
    ANY_VALUE(tt4.position_name) AS 직급명,
    max(tt2.time) AS 입출입시간,
    tt2.region AS 지역,
    tt2.record_symbol AS 입출입구분
from (
    select 
        t1.employee_id, 
        t3.annual_income 
    from (select * from manager where end_date = '9999-01-01') t1
    inner join (select * from department where note = 'active')t2
    on t2.id = t1.department_id
    inner join (select * from salary where end_date = '9999-01-01') t3
    on t3.id = t1.employee_id
    order by t3.annual_income desc
    limit 5
) tt1
inner join (select * from record where record_symbol = 'O') tt2
on tt2.employee_id = tt1.employee_id
left join employee tt3
on tt3.id = tt1.employee_id
left join position tt4
on tt4.id = tt1.employee_id
group by tt1.employee_id, tt2.region
order by null



---

### 2단계 - 인덱스 설계

1. 인덱스 적용해보기 실습을 진행해본 과정을 공유해주세요

---

### 추가 미션

1. 페이징 쿼리를 적용한 API endpoint를 알려주세요
