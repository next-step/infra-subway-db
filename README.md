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
    tt3.last_name AS 이름,
    tt1.annual_income AS 연봉,
    tt4.position_name AS 직급명,
    tt2.time AS 입출입시간,
    tt2.region AS 지역,
    tt2.record_symbol AS 입출입구분
from (
    select
        t1.employee_id,
        max(annual_income) as annual_income
    from (select * from manager where end_date = '9999-01-01') t1
    inner join (select * from department where note = 'active')t2
    on t2.id = t1.department_id
    left join (select * from salary) t3
    on t3.id = t1.employee_id
    group by t1.employee_id
    order by annual_income desc
    limit 5
) tt1
inner join (select * from record where record_symbol = 'O') tt2
on tt2.employee_id = tt1.employee_id
left join employee tt3
on tt3.id = tt1.employee_id
left join (select * from position where position_name = 'manager') tt4
on tt4.id = tt1.employee_id
order by null



---

### 2단계 - 인덱스 설계

1. 인덱스 적용해보기 실습을 진행해본 과정을 공유해주세요

- 공통 PK DDL
ALTER TABLE covid ADD PRIMARY KEY (id);
ALTER TABLE hospital ADD PRIMARY KEY (id);
ALTER TABLE member ADD PRIMARY KEY (id);
ALTER TABLE programmer ADD PRIMARY KEY (id);

- 1.1) Coding as a Hobby 와 같은 결과를 반환하세요.
  ALTER TABLE programmer ADD INDEX hobby_index (hobby);

    select hobby, round((t1.total / t2.cnt), 2) as percentage
    from (
        select hobby, count(*) as total
        from programmer
        group by hobby
    ) AS t1, (select count(*) as cnt from programmer) as t2
    order by hobby desc;

    select
        round(count(case hobby when 'YES' then 1 end) / count(*) * 100, 1) as YES_PERSENT
        , round(count(case hobby when 'NO' then 1 end) / count(*) * 100, 1) as NO_PERSENT
    from subway.programmer;

- 1.2) 프로그래머별로 해당하는 병원 이름을 반환하세요. (covid.id, hospital.name)
  ALTER TABLE programmer ADD INDEX programmer_pk_index (id);
  ALTER TABLE covid ADD INDEX covid_fk_index1 (programmer_id);
  ALTER TABLE covid ADD INDEX covid_pk_index1 (id);
  ALTER TABLE hospital ADD INDEX hospital_pk_index (id);

  select t2.id, t3.name
  from programmer t1
  left join covid t2
  on t2.programmer_id = t1.id
  left join hospital t3
  on t3.id = t2.hospital_id;

- 1.3) 프로그래밍이 취미인 학생 혹은 주니어(0-2년)들이 다닌 병원 이름을 반환하고 user.id 기준으로 정렬하세요. (covid.id, hospital.name, user.Hobby, user.DevType, user.YearsCoding)
  select t2.id, t3.name, t1.hobby, t1.dev_type, t1.years_coding
  from ( 
    select id, hobby, dev_type, years_coding 
    from programmer 
    where (hobby = 'yes' and student like 'yes%') or (years_coding = '0-2 yeares')
  ) t1
  left join covid t2
  on t2.programmer_id = t1.id
  left join hospital t3
  on t3.id = t2.hospital_id
  order by t1.id

- 1.4) 서울대병원에 다닌 20대 India 환자들을 병원에 머문 기간별로 집계하세요. (covid.Stay)
  ALTER TABLE covid ADD INDEX covid_fk_index1 (programmer_id);
  ALTER TABLE programmer ADD INDEX programmer_country_index (country);
  ALTER TABLE member ADD INDEX member_pk_index (id);
  ALTER TABLE member ADD INDEX member_age_index (age);
  ALTER TABLE covid drop INDEX stay_index;

  select stay, count(stay) 
  from (
    select stay, programmer_id 
    from covid 
    where (select id from hospital where name = '서울대병원') = hospital_id
  ) t1
  inner join (select id from programmer where country = 'india') t2
  on t2.id = t1.programmer_id
  inner join (select id from member where age between 20 and 29) t3
  on t3.id = t1.programmer_id
  group by t1.stay;

- 1.5) 서울대병원에 다닌 30대 환자들을 운동 횟수별로 집계하세요. (user.Exercise)
  ALTER TABLE member ADD INDEX member_pk_index (id);
  ALTER TABLE member ADD INDEX member_age_index (age);
  ALTER TABLE covid ADD INDEX covid_fk_index1 (programmer_id);
  ALTER TABLE covid ADD INDEX covid_hospital_index (hospital_id);
  ALTER TABLE programmer ADD INDEX programmer_pk_index (id);

  select t3.exercise, count(t3.exercise)
  from (
    select programmer_id 
    from covid 
    where (select id from hospital where name = '서울대병원') = hospital_id
  ) t1
  inner join (select id from member where age between 30 and 39) t2
  on t2.id = t1.programmer_id
  inner join programmer t3
  on t3.id = t1.programmer_id
  group by t3.exercise;
---

### 추가 미션

1. 페이징 쿼리를 적용한 API endpoint를 알려주세요
