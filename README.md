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

---

### 추가 미션

1. 페이징 쿼리를 적용한 API endpoint를 알려주세요
