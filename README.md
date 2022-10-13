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
``` sql
use tuning;
select temp.employee_id as 시원번호, temp.last_name as 이름, temp.annual_income as 연봉, temp.position_name as 직급명, 
	r.time as 입출입시간, r.region as 지역, r.record_symbol as 입출입구분
from record r 
inner join (
		SELECT ed.employee_id, e.last_name, p.position_name, max(s.annual_income) annual_income
		FROM employee e
		inner join manager m
			on m.employee_id = e.id
		inner join employee_department ed
			on ed.employee_id = e.id
		inner join department d
			on d.id = ed.department_id
		inner join salary s
			on e.id = s.id
		inner join position p 
			on e.id = p.id
		where p.end_date >= current_timestamp 
			and ed.end_date >= current_timestamp
			and m.end_date >= current_timestamp
            and d.note='Active' 
            and p.position_name='Manager'
        group by e.id
        order by annual_income desc
		limit 5
) temp 
on temp.employee_id = r.employee_id
where record_symbol = 'O';
```

---

### 2단계 - 인덱스 설계

1. 인덱스 적용해보기 실습을 진행해본 과정을 공유해주세요

### 프로그래머별로 해당하는 병원 이름을 반환하세요. (covid.id, hospital.name)
```sql
select covid.id, hospital.name
from programmer 
inner join covid
	on covid.programmer_id = programmer.id
inner join hospital
	on covid.hospital_id = hospital.id;
```
- EXPLAIN을 통하여 ALL SCAN을 통해 쿼리가 동작하는 것을 확인(0.359 sec)
- hospital id를 PK로 설정하고 다시 조회하니 hospital_table의 pk인덱스를 타는 것을 확인 (0.244 sec ~ 0.261 sec)
- covid의 hospital_id를 같은 타입으로 맞춘다음 fk로 설정하고 인덱스를 설정하니 기하급수적으로 느려져서 복구했습니다. (6.588 sec)
- programmer table id pk 설정 후 covid 테이블을 제외한 모든 테이블이 pk index를 타는 것을 확인했습니다. (0.0013 sec)

### 프로그래밍이 취미인 학생 혹은 주니어(0-2년)들이 다닌 병원 이름을 반환하고 user.id 기준으로 정렬하세요.  (covid.id, hospital.name, user.Hobby, user.DevType, user.YearsCoding)
```sql
select covid.id, hospital.name, programmer.hobby, programmer.dev_type, programmer.years_coding
from programmer 
inner join covid
	on covid.programmer_id = programmer.id
inner join hospital
	on covid.hospital_id = hospital.id
where programmer.years_coding = '0-2 years' or programmer.hobby='yes'
order by covid.programmer_id;
```
- 처음에 programmer.id asc 를 기준으로 정렬 (0.710 sec)
- hospital.programmer_id 를 기준으로 정렬 (0.097 sec)
- 더 많은 스캔을 하고 있는 테이블을 기준으로 정렬해야된다는 것을 알 수 있었습니다.

### 서울대병원에 다닌 20대 India 환자들을 병원에 머문 기간별로 집계하세요. (covid.Stay)
```sql
SELECT covid.stay
FROM subway.member
         INNER JOIN covid
                    ON member.id = covid.member_id
         INNER JOIN programmer
                    ON member.id = programmer.member_id
         INNER JOIN hospital
                    ON covid.hospital_id = hospital.id
WHERE member.age >= 20 and member.age < 30 and programmer.country = 'India' and hospital.name = '서울대병원'
order by covid.stay;
```
- 아무것도 설정하지 않았을 때 (22.033 sec)
- member.id로 PK로 설정 (7.136 sec)
- 쿼리 실행 결과를 보고 where 조건에 걸린 programmer 테이블이 country로 인해 fullscan을 하는 것을 확인
- programmer.country에 index 설정 (7.057 sec)
- programmer 와 covid 테이블에 존재하는 member_id를 fk로 설정 후 index 추가 (0.14 sec)
- covid.stay를 정렬하기 때문에 index 설정 (0.022sec ~ 0.038 sec)
- 목표를 달성하였지만 더 줄일 수 있을 거라 생각하고 covid hospital_id를 fk 설정 후 인덱스 설정(0.44 sec ~ 0.74 sec)
- fk 설정 후 오히려 조회성능이 저하되서 다시 해제 후 member.age 를 index 설정(0.017 sec~0.020 sec)
- 중간에 쿼리를 잘못써서 `hospital.name = '서울대병원'` 쿼리를 뒤늦게 추가하고 다시 쿼리를 확인해보니 0.156 sec가 나오는 것을 확인했습니다.
- 다시 covid에서 hospital_id를 fk를 지정하고 인덱스를 추가하니 0.038 sec로 줄어드는 것을 확인했습니다.


###  서울대병원에 다닌 30대 환자들을 운동 횟수별로 집계하세요. (user.Exercise)
```sql
SELECT programmer.exercise
FROM subway.member
         INNER JOIN covid
                    ON member.id = covid.member_id
         INNER JOIN programmer
                    ON member.id = programmer.member_id
         INNER JOIN hospital
                    ON covid.hospital_id = hospital.id
WHERE member.age >= 30 and member.age < 40 and programmer.country = 'India' and hospital.name = '서울대병원'
order by programmer.exercise;
```
- 이전에 fk, age, country를 인덱스를 설정해놓은 것이 있어서 괜찮은 성능의 조회로 동작하였습니다.(0.028 sec)


### 추가 미션

1. 페이징 쿼리를 적용한 API endpoint를 알려주세요
```http request
GET /stations
```
- 해당 API endpoint에 페이징 기능을 추가 하였습니다.

