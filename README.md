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

#### [Coding as a Hobby 와 같은 결과를 반환하세요.]
```mysql
select
  p.hobby as hobby,
  concat(round(count(p.hobby) * 100.0 / (select count(*) from programmer), 1), '%') as percent
from programmer p
group by p.hobby
order by p.hobby desc;
```
- 인덱스 걸기 전 실행계획 & Visual Explain
![image](https://user-images.githubusercontent.com/52458039/209472591-c9d516cc-eeef-4d7d-b1dd-2fd51fbded75.png)
![image](https://user-images.githubusercontent.com/52458039/209470369-81d59c6e-52a5-446e-9efe-113a855ee2c3.png)
- 약 5.435초
- 아래와 같은 인덱스 추가
  - programmer id 컬럼 pk 추가
  - hobby 컬럼 index 추가
- hobby 인덱스 추가 후 실행계획 & Visual Explain <br>
![image](https://user-images.githubusercontent.com/52458039/209472708-797ba59b-d6aa-4129-af1f-f32c9fc396a0.png)
![image](https://user-images.githubusercontent.com/52458039/209471218-abdc045b-4bcd-4ec4-b64d-62b5cfb0478c.png)
- 약 0.3초


#### [프로그래머별로 해당하는 병원 이름을 반환하세요. (covid.id, hospital.name)]
```mysql
select
  c.id as covid_id,
  h.name as hospital_name
from hospital h
       inner join covid c on c.hospital_id = h.id
       inner join programmer p on p.id = c.programmer_id;
```

- 인덱스 걸기 전 실행계획 & Visual Explain
![image](https://user-images.githubusercontent.com/52458039/209472550-5e4f76af-b8bd-4949-8861-370fe03ecd49.png)
![image](https://user-images.githubusercontent.com/52458039/209472532-3210e9a6-99f1-42d1-b0bb-00e0f25024e2.png)
- 30초 초과 에러
- 아래와 같은 인덱스 추가
  - programmer id 컬럼 pk 추가
  - hospital id 컬럼 pk 추가
  - covid hospital_id 컬럼 index 추가
  - covid programmer_id 컬럼 index 추가
  - programmer hobby 컬럼 index 추가
- hobby 인덱스 추가 후 실행계획 & Visual Explain
![image](https://user-images.githubusercontent.com/52458039/209472796-ea601419-d0b2-4da6-8010-ee92fbbde12d.png)
![image](https://user-images.githubusercontent.com/52458039/209472357-73e124f6-2de5-4b44-aab8-2f0af8415026.png)
- 약 0.043 초

#### [프로그래밍이 취미인 학생 혹은 주니어(0-2년)들이 다닌 병원 이름을 반환하고 user.id 기준으로 정렬하세요. (covid.id, hospital.name, user.Hobby, user.DevType, user.YearsCoding)]
```mysql
select
  c.id as covid_id,
  h.name as hospital_id,
  p.hobby as hobby,
  p.dev_type as dev_type,
  p.years_coding as years_coding
from hospital h
       inner join covid c on c.hospital_id = h.id
       inner join programmer p on p.id = c.programmer_id
where p.hobby = 'Yes' and (p.student <> 'No' or p.years_coding = '0-2 years')
order by p.id;
```

- 인덱스 걸기 전 실행계획 & Visual Explain
![image](https://user-images.githubusercontent.com/52458039/209483158-e3cae5b2-5a5a-40b5-8518-deda1ea02c0c.png)
![image](https://user-images.githubusercontent.com/52458039/209483142-d0e3ccd6-d9ba-477f-a192-59920ebef538.png)

- 30초 초과 에러
- 아래와 같은 인덱스 추가
  - programmer id 컬럼 pk 추가
  - hospital id 컬럼 pk 추가
  - covid hospital_id 컬럼 index 추가
  - covid programmer_id 컬럼 index 추가 

- 인덱스 추가 후 실행계획 & Visual Explain
![image](https://user-images.githubusercontent.com/52458039/209483962-b0220237-67c3-45a8-800e-0c3f2b53a824.png)
![image](https://user-images.githubusercontent.com/52458039/209483954-d200cd37-cdb4-4f56-b40e-3254c1de7aa0.png)
- 약 0.019초

#### [서울대병원에 다닌 20대 India 환자들을 병원에 머문 기간별로 집계하세요. (covid.Stay)]
```mysql
select
  c.stay,
  count(c.stay) as count_number
from covid as c
       inner join (select id from hospital where name = '서울대병원') as h on h.id = c.hospital_id
       inner join (select id from programmer where country = 'India') as p on p.id = c.programmer_id
       inner join (select id from member where age between 20 and 29) as m on m.id = c.member_id
group by c.stay;
```

- 인덱스 걸기 전 실행계획 & Visual Explain
![image](https://user-images.githubusercontent.com/52458039/209557558-a2f7f8cf-8ebb-44c7-ba89-575c0fef7990.png)
![image](https://user-images.githubusercontent.com/52458039/209557614-5c5e9db0-f539-4d66-a9b1-45b7dba56a5f.png)

- 30초 초과 에러 발생
- 아래와 같은 인덱스 추가
  - programmer id 컬럼 pk 추가
  - hospital id 컬럼 pk 추가
  - covid hospital_id 컬럼 index 추가
  - covid programmer_id 컬럼 index 추가
  - covid member_id 컬럼 index 추가
  - covid stay 컬럼 index 추가 
  - hospital name 컬럼 index 추가
  - programmer country 컬럼 index 추가
  - member age 컬럼 index 추가

- 인덱스 추가 후 실행계획 & Visual Explain
![image](https://user-images.githubusercontent.com/52458039/209555320-c850d55f-7fde-4c50-8e24-2bee175ce607.png)
![image](https://user-images.githubusercontent.com/52458039/209554932-e6f92752-6554-48e2-b23a-48d33b6f8517.png)
- 약 0.145초

#### [서울대병원에 다닌 30대 환자들을 운동 횟수별로 집계하세요. (user.Exercise)]
```mysql
select
  p.exercise,
  count(p.exercise)
from programmer as p
       inner join covid as c on c.programmer_id = p.id
       inner join (select id from hospital where name = '서울대병원') as h on h.id = c.hospital_id
       inner join (select id from member where age between 30 and 39) as m on m.id = c.member_id
group by p.exercise;
```
- 인덱스 걸기 전 실행계획 & Visual Explain
![image](https://user-images.githubusercontent.com/52458039/209557690-33514efa-c333-42b7-8bb7-0658c03c07db.png)
  ![image](https://user-images.githubusercontent.com/52458039/209557728-ac75034a-6809-4fa8-a08e-098c1d12a6c3.png)

- 30초 초과 에러 발생
- 아래와 같은 인덱스 추가
  - programmer id 컬럼 pk 추가
  - hospital id 컬럼 pk 추가
  - covid hospital_id 컬럼 index 추가
  - covid programmer_id 컬럼 index 추가
  - covid member_id 컬럼 index 추가
  - hospital name 컬럼 index 추가
  - member age 컬럼 index 추가
  - programmer exercise 컬럼 index 추가

- 인덱스 추가 후 실행계획 & Visual Explain
![image](https://user-images.githubusercontent.com/52458039/209557210-a2dde7b0-ebd6-41f2-b7ba-51b5242dc956.png)
![image](https://user-images.githubusercontent.com/52458039/209556543-eb84750f-1f33-4260-9e3a-60b3b7c8e75d.png)
- 약 0.145초

---

### 추가 미션

1. 페이징 쿼리를 적용한 API endpoint를 알려주세요
