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

1. 인덱스 설정을 추가하지 않고 아래 요구사항에 대해 1s 이하(M1의 경우 2s)로 반환하도록 쿼리를 작성하세요.

- 활동중인(Active) 부서의 현재 부서관리자 중 연봉 상위 5위안에 드는 사람들이 최근에 각 지역별로 언제 퇴실했는지 조회해보세요. (사원번호, 이름, 연봉, 직급명, 지역, 입출입구분, 입출입시간)

```sql
USE tuning;

SELECT top_5_manager.id as "사원번호", e.last_name as "이름", top_5_manager.annual_income as "연봉", p.position_name as "직급명", r.time as "입출입시간", r.region as "지역", r.record_symbol as "입출입구분"
FROM (SELECT id, start_date, annual_income
      FROM salary s
      WHERE id IN
            (SELECT m.employee_id
             FROM department d
                      JOIN manager m ON d.id = m.department_id and UPPER(d.note) = "ACTIVE"
             WHERE m.start_date < now()
               and m.end_date > now()
            )
        and s.end_date > now()
      ORDER BY annual_income desc LIMIT 5) top_5_manager
         JOIN employee e on e.id = top_5_manager.id
         JOIN position p ON p.id = top_5_manager.id and p.end_date > now()
         JOIN record r ON r.employee_id = top_5_manager.id and r.record_symbol = "O";
```

```sql
14 row(s) returned	0.172 sec / 0.000011 sec
```

<img width="538" alt="result" src="https://user-images.githubusercontent.com/34808501/178293317-6b3696c9-e217-49c7-9d08-54030d6d3dd6.png">

![explain](https://user-images.githubusercontent.com/34808501/178293084-ba908499-f14e-408a-b88a-5f1aa8d88b43.png)
---

### 2단계 - 인덱스 설계

1. 인덱스 적용해보기 실습을 진행해본 과정을 공유해주세요

- [x] Coding as a Hobby 와 같은 결과를 반환하세요.
```sql
USE subway;

SELECT hobby, concat(round((count(id) / (SELECT count(1) FROM programmer)) * 100, 1), "%")
FROM programmer
GROUP BY hobby
ORDER BY hobby desc
```
- 인덱스 추가
```sql
alter table programmer add primary key (id);
create index idx_programmer_hobby on programmer (hobby);
```
<img width="798" alt="p1_explain" src="https://user-images.githubusercontent.com/34808501/178304703-a0f1d600-b82a-46aa-8351-c74c0c7a01fc.png">
<img width="293" alt="p1_explain_img" src="https://user-images.githubusercontent.com/34808501/178304690-41459b78-31f4-41f3-8e84-d22e484b8614.png">

- [x] 프로그래머별로 해당하는 병원 이름을 반환하세요. (covid.id, hospital.name)
```sql
USE subway;

SELECT c.id, h.name
FROM programmer p
    JOIN covid c ON c.programmer_id = p.id
    JOIN hospital h ON h.id = c.hospital_id
```
- 인덱스 추가 (covid 테이블에 programmer_id에는 인덱스 추가를 안해도 성능상 차이가 없어서 추가하지 않았습니다.)
```sql
alter table programmer add primary key (id);
alter table hospital add primary key (id);
alter table covid add primary key (id);
```

- [x] 프로그래밍이 취미인 학생 혹은 주니어(0-2년)들이 다닌 병원 이름을 반환하고 user.id 기준으로 정렬하세요. (covid.id, hospital.name, user.Hobby, user.DevType, user.YearsCoding)
```sql
USE subway;

SELECT c.id, h.name, p.hobby, p.dev_type, p.years_coding_prof
FROM (
         SELECT p.id, p.hobby, p.dev_type, p.years_coding_prof FROM programmer p
         WHERE p.hobby = "YES" and (p.student LIKE "YES*" or p.years_coding_prof = "0-2 years")
         ORDER BY p.id) p
JOIN covid c ON c.programmer_id = p.id
JOIN hospital h ON h.id = c.hospital_id
```
- 인덱스 추가 (covid 테이블에 programmer_id에는 인덱스 추가를 안해도 성능상 차이가 없어서 추가하지 않았습니다.)
```sql
alter table programmer add primary key (id);
alter table hospital add primary key (id);
alter table covid add primary key (id);
create index idx_programmer_hobby on programmer (hobby);
```
<img width="865" alt="p3_explain" src="https://user-images.githubusercontent.com/34808501/178472036-c3a822f6-8a3e-410e-9830-52bb9e9cbec1.png">
<img width="498" alt="p3_explain_img" src="https://user-images.githubusercontent.com/34808501/178472045-99c669f5-e0a0-4071-86f6-fcac6505e644.png">


- [x] 서울대병원에 다닌 20대 India 환자들을 병원에 머문 기간별로 집계하세요. (covid.Stay)
```sql
USE subway;

SELECT c.stay, count(1)
FROM (
         SELECT p.id, p.country
         FROM programmer p
         WHERE upper(p.country) = "INDIA"
     ) p
         JOIN covid c ON c.programmer_id = p.id
         JOIN member m ON m.id = c.member_id and m.age >= 20 and m.age < 30
         JOIN hospital h ON h.id = c.hospital_id and h.name = "서울대병원"
GROUP BY c.stay;
```
- 인덱스 추가
```sql
alter table programmer add primary key (id);
alter table covid add primary key (id);
alter table member add primary key (id);
alter table hospital add primary key (id);
create index idx_covid_hospital_id on covid (hospital_id);
create index idx_hospital_name on hospital (name);
create index idx_member_age on hospital (age);
```
<img width="1017" alt="p4_explain" src="https://user-images.githubusercontent.com/34808501/178471899-fdf30148-d055-4aa1-afa4-186cba2b5cb8.png">
<img width="684" alt="p4_explain_img" src="https://user-images.githubusercontent.com/34808501/178471900-09c12765-8d60-48cc-8000-7aae8cd0874d.png">


- [x] 서울대병원에 다닌 30대 환자들을 운동 횟수별로 집계하세요. (user.Exercise)
```sql
USE subway;

explain SELECT p.exercise, count(1)
FROM programmer p 
    JOIN covid c ON c.programmer_id = p.id 
    JOIN member m ON m.id = c.member_id and m.age >= 21 and m.age < 40
    JOIN hospital h ON h.id = c.hospital_id and h.name = "서울대병원"
GROUP BY p.exercise;
```
- 인덱스 추가
```sql
alter table programmer add primary key (id);
alter table covid add primary key (id);
alter table member add primary key (id);
alter table hospital add primary key (id);
create index idx_hospital_name on hospital (name);
```
<img width="1180" alt="pg5_explain_img" src="https://user-images.githubusercontent.com/34808501/178471890-c88f330e-2026-4216-a450-a33d13a996f1.png">
<img width="676" alt="pg5_explain" src="https://user-images.githubusercontent.com/34808501/178471885-a843ce4c-ceb9-468d-a3d0-6ef29b0d9853.png">



---

### 추가 미션

1. 페이징 쿼리를 적용한 API endpoint를 알려주세요
