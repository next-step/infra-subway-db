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

<img width="1492" alt="스크린샷 2022-10-10 오후 8 05 55" src="https://user-images.githubusercontent.com/29122916/194852995-1aadee65-2900-45ce-8e4e-9f035a6d0c46.png">
<img width="1348" alt="스크린샷 2022-10-10 오후 8 07 23" src="https://user-images.githubusercontent.com/29122916/194853083-10cc13b9-32b2-42d1-9e03-dac788948130.png">

SELECT 	total.employee_id as "사원번호"
        , total.last_name as "이름"
        , total.position_name as "직급명"
        , total.annual_income as "연봉"
        , r.time as "입출입시간"
        , r.region as "지역"
        , r.record_symbol as "입출입시간"
FROM (
        SELECT m.employee_id
        , e.last_name
        , p.position_name
        , s.annual_income
        FROM tuning.department d
        INNER JOIN tuning.manager m
        ON d.id = m.department_id
        INNER JOIN tuning.employee e
        ON m.employee_id = e.id
        INNER JOIN tuning.employee_department de
        ON e.id = de.employee_id
        INNER JOIN tuning.position p
        ON de.employee_id = p.id
        INNER JOIN tuning.salary s
        ON p.id = s.id
        WHERE d.note = "Active"
        AND m.end_date >= curdate()
        AND de.end_date >= curdate()
        AND p.position_name = "manager"
        AND p.end_date >= curdate()
        AND s.end_date >= curdate()
        ORDER BY s.annual_income DESC
        LIMIT 5
) AS total
INNER JOIN record r
ON total.employee_id = r.employee_id
AND r.record_symbol = 'O';

### 2단계 - 인덱스 설계

1. 인덱스 적용해보기 실습을 진행해본 과정을 공유해주세요
#### Coding as a Hobby 와 같은 결과를 반환하세요.
  - 인덱스 적용 (2.305 sec / 0.000040 sec) -> (0.045 sec / 0.0000081 sec)
    - programmer 테이블 hobby 인덱스 추가;
    - SELECT ROUND(COUNT(*) / (select COUNT(*) from programmer) * 100, 1) AS hobby_rate FROM programmer
  GROUP BY hobby;
<img width="1347" alt="스크린샷 2022-10-15 오후 8 35 12" src="https://user-images.githubusercontent.com/29122916/195984389-b6446480-f433-4ca6-897e-849afe2b18b2.png">
<img width="168" alt="스크린샷 2022-10-15 오후 8 35 23" src="https://user-images.githubusercontent.com/29122916/195984421-d99a748f-4c85-49a9-85d6-7f2fd885c811.png">
---
#### 프로그래머별로 해당하는 병원 이름을 반환하세요. (covid.id, hospital.name)
  - SELECT c.id, h.name
    FROM hospital h
    INNER JOIN covid c
    ON h.id = c.hospital_id
    INNER JOIN programmer p
    ON c.programmer_id = p.id;
  - covid, hospital, programmer primary key(pk nn uq) 추가
  - hospital 테이블 name 인덱스 추가
  - covid 테이블 hospital_id + programmer_id + id 인덱스 추가
<img width="1539" alt="스크린샷 2022-10-15 오후 11 30 17" src="https://user-images.githubusercontent.com/29122916/195991913-ae3dbba5-0e20-44b7-b944-4a09d1acaf33.png">
<img width="540" alt="스크린샷 2022-10-15 오후 11 30 09" src="https://user-images.githubusercontent.com/29122916/195991939-286c2b0b-2879-4df2-8a0e-7097b87ebfd1.png">
  - 결과 0.0072 sec / 0.0017 sec
---
#### 프로그래밍이 취미인 학생 혹은 주니어(0-2년)들이 다닌 병원 이름을 반환하고 user.id 기준으로 정렬하세요. (covid.id, hospital.name, user.Hobby, user.DevType, user.YearsCoding)
- SELECT
  p.id
  , h.name
  FROM (  SELECT p.id
  FROM programmer p
  WHERE p.hobby = 'Yes'
  AND (p.student LIKE 'Yes%' OR p.years_coding = '0-2 years')
  ORDER BY p.id
  ) as p
  INNER JOIN covid c
  ON p.id = c.programmer_id
  INNER JOIN hospital h
  ON c.hospital_id = h.id;
- covid 테이블 programmer_id 인덱스 추가
<img width="1547" alt="스크린샷 2022-10-16 오전 12 41 09" src="https://user-images.githubusercontent.com/29122916/195995296-1cace8b0-207a-4e2c-a01a-6ea70207d9fc.png">
<img width="584" alt="스크린샷 2022-10-16 오전 12 43 04" src="https://user-images.githubusercontent.com/29122916/195995368-51b3f6c1-9e35-439a-8add-52412a7727bb.png">
- 결과 2.469 sec / 0.00019 sec -> 0.012 sec / 0.0055 sec
---
#### 서울대병원에 다닌 20대 India 환자들을 병원에 머문 기간별로 집계하세요. (covid.Stay)
- SELECT
  hc.stay,
  COUNT(1) as cnt
  FROM (
  SELECT c.hospital_id, c.programmer_id, c.member_id, c.stay
  FROM hospital h
  INNER JOIN covid as c
  ON h.id = c.hospital_id
  WHERE name = "서울대병원"
  ) AS hc
  INNER JOIN (
  SELECT p.id
  FROM programmer p
  WHERE p.country = 'India'
  ) as p
  ON hc.programmer_id = p.id
  INNER JOIN (
  SELECT m.id
  FROM member AS m
  WHERE m.age between 20 and 29
  ) as m
  ON hc.member_id = m.id
  GROUP BY hc.stay;
- covid 테이블 hospital_id + programmer_id + member_id + stay 인덱스 추가
- programmer 테이블 country + id 인덱스 추가
- member 테이블 추가 age 인덱스 추가
<img width="1694" alt="스크린샷 2022-10-16 오전 2 29 30" src="https://user-images.githubusercontent.com/29122916/196000002-9c8997ce-80f1-44d4-84b3-ef79a0bdd382.png">
<img width="758" alt="스크린샷 2022-10-16 오전 2 30 04" src="https://user-images.githubusercontent.com/29122916/196000019-f1d5c6cb-c35d-462d-bfe4-e71c09428ca8.png">
- 결과 0.074 sec / 0.000014 sec
---
#### 서울대병원에 다닌 30대 환자들을 운동 횟수별로 집계하세요. (user.Exercise)
- SELECT
  p.exercise,
  COUNT(p.id)
  FROM (
  SELECT c.programmer_id, c.member_id
  FROM hospital h
  INNER JOIN covid c
  ON h.id = c.hospital_id
  WHERE h.name = '서울대병원'
  ) as hc
  INNER JOIN programmer p
  ON hc.programmer_id = p.id
  INNER JOIN (
  SELECT m.id
  FROM member m
  WHERE m.age BETWEEN 30 AND 39
  ) as m
  ON hc.member_id = m.id
  GROUP BY p.exercise;
<img width="1696" alt="스크린샷 2022-10-16 오전 2 40 27" src="https://user-images.githubusercontent.com/29122916/196000464-865c8d96-bf01-4526-b761-5d1f2b3a5a9e.png">
<img width="761" alt="스크린샷 2022-10-16 오전 2 40 19" src="https://user-images.githubusercontent.com/29122916/196000473-c66a07e9-11a8-4339-81c7-83eea4d09d96.png">
- 측정 결과 0.020 sec / 0.000011 sec
---

### 추가 미션

1. 페이징 쿼리를 적용한 API endpoint를 알려주세요
