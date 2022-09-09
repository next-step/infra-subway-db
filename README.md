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
-- 활동중인(Active) 부서의 현재 부서관리자(manager) 중 연봉 상위 5위안에 드는 사람들이 최근에 각 지역별로 언제 퇴실(O)했는지 조회해보세요.
-- (사원번호, 이름, 연봉, 직급명, 지역, 입출입구분, 입출입시간)
SELECT manager_info.사원번호,
       manager_info.이름,
       manager_info.연봉,
       manager_info.직급명,
       r.time AS 입출입시간,
       r.region AS 지역,
       r.record_symbol AS 입출입구분
  FROM (
        SELECT e.id AS 사원번호, e.last_name AS 이름, s.annual_income AS 연봉, p.position_name AS 직급명
          FROM department d
         INNER JOIN manager m
            ON d.id = m.department_id
         INNER JOIN employee e
            ON m.employee_id = e.id
         INNER JOIN position p
            ON e.id = p.id
         INNER JOIN salary s
            ON e.id = s.id
         WHERE d.note = 'Active'
           AND m.end_date = '9999-01-01'
           AND s.end_date = '9999-01-01'
           AND p.end_date = '9999-01-01'
         ORDER BY s.annual_income DESC
         LIMIT 5
    ) AS manager_info
 INNER JOIN record r
    ON manager_info.사원번호 = r.employee_id
   AND r.record_symbol = 'O'
```

![쿼리결과](step1-쿼리결과.png)
![실행계획](step1-실행계획(Visual).png)
![실행계획](실행계획.png)
소요시간: 0.163s

---

### 2단계 - 인덱스 설계

1. 인덱스 적용해보기 실습을 진행해본 과정을 공유해주세요

- Coding as a Hobby
  - 작성한 쿼리
    - ```mysql
      -- Coding as a Hobby
      -- e.g.) Yes 80.8%, No 19.2%
      SELECT hobby,
             CONCAT(ROUND(COUNT(*) / (SELECT COUNT(*) FROM programmer) * 100, 1), '%') as 'percentage'
        FROM programmer
       GROUP BY hobby
       ORDER BY hobby DESC;
      ```
    - Visual 실행계획
      - ![img.png](step2-mission1-실행계획(Visual).png)
    - ![실행 결과](step2-mission1-실행결과.png)
      - 0.420s 소요
    - 인덱스 추가
      - ```sql
        CREATE INDEX `idx_programmer_hobby` ON `subway`.`programmer` (hobby) COMMENT '' ALGORITHM DEFAULT LOCK DEFAULT
        ``` 
      - 실행계획
        - ![img.png](step2-mission1-튜닝후-실행계획(Visual).png)
        - ![img.png](step2-mission1-튜닝후-실행계획.png)
      - 0.074s 소요
- 프로그래머별로 해당하는 병원 이름을 반환하세요. (covid.id, hospital.name)
- 프로그래밍이 취미인 학생 혹은 주니어(0-2년)들이 다닌 병원 이름을 반환하고 user.id 기준으로 정렬하세요. (covid.id, hospital.name, user.Hobby, user.DevType, user.YearsCoding)
- 서울대병원에 다닌 20대 India 환자들을 병원에 머문 기간별로 집계하세요. (covid.Stay)
- 서울대병원에 다닌 30대 환자들을 운동 횟수별로 집계하세요. (user.Exercise)

---

### 추가 미션

1. 페이징 쿼리를 적용한 API endpoint를 알려주세요
