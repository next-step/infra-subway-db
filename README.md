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

다음처럼 쿼리를 짜 보았습니다.
제 로컬 환경에서 작동시켰을 때 쿼리 시간은 0.16758204입니다.
쿼리 요구사항을 제대로 이해했는지 피드백 부탁드립니다.
특히 지역별로 언제 퇴실했는지 부분이 정확히 어떤 의미인지 모르겠어서
일단 강의노트에 있는 결과에 가능한 비슷한 결과가 나오도록 쿼리 작성했습니다.
지역별로 언제 퇴실했는지라는 말이 혹시 지역별로 grouping하라는 말일까요?
감사합니다!!

```text
SELECT 
		 FIRST_QUERY.employee_id AS 사원번호
    ,FIRST_QUERY.employee_name AS 이름
    ,FIRST_QUERY.employee_income AS 연봉 
    ,FIRST_QUERY.employee_position AS 직급명
    ,SECOND_QUERY.time AS 입출입시간
    ,SECOND_QUERY.region AS 지역
    ,SECOND_QUERY.record_symbol AS 입출입구분
FROM 
(
SELECT 
	mng.employee_id
	,(SELECT LAST_NAME FROM employee WHERE id = mng.employee_id) AS employee_name
    ,sal.annual_income AS employee_income
    ,(SELECT POSITION_NAME FROM position WHERE id = mng.employee_id AND SUBSTR(end_date, 1,4) = '9999') AS employee_position
FROM 
(
 SELECT * FROM department WHERE UPPER(note) = 'ACTIVE'
) AS dpt INNER JOIN 
(
 SELECT * FROM manager WHERE SUBSTR(end_date, 1,4) = '9999'
) AS mng on dpt.id = mng.department_id 
  INNER JOIN
(
 SELECT * FROM salary
) AS sal on mng.employee_id = sal.id
		 AND SUBSTR(sal.end_date, 1,4) = '9999'
ORDER BY annual_income desc limit 5
) FIRST_QUERY INNER JOIN 
(
  SELECT * FROM record WHERE record_symbol = 'O' ORDER BY region
) AS SECOND_QUERY ON FIRST_QUERY.employee_id = SECOND_QUERY.employee_id

;


```


---

### 2단계 - 인덱스 설계

1. 인덱스 적용해보기 실습을 진행해본 과정을 공유해주세요

---

### 추가 미션

1. 페이징 쿼리를 적용한 API endpoint를 알려주세요
