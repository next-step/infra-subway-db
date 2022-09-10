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
- 개발 환경 : M1 맥북

- ```
  INDEX
  TABLE `covid` (
    UNIQUE KEY `idx_covid_id` (`id`),
    KEY `idx_covid_hospital_id_programmer_id` (`hospital_id`,`programmer_id`),
    KEY `idx_covid_hospital_id` (`hospital_id`),
    KEY `idx_covid_programmer_id` (`programmer_id`),
    KEY `idx_covid_member_id` (`member_id`)
  )
  
  TABLE `favorite` (
    PRIMARY KEY (`id`)
  )
  
  TABLE `hospital` (
    UNIQUE KEY `idx_hospital_id` (`id`),
    KEY `idx_hospital_name` (`name`)
  )
  
  TABLE `line` (
    PRIMARY KEY (`id`),
    UNIQUE KEY `UK_9ney9davbulf79nmn9vg6k7tn` (`name`)
  )
  
  TABLE `member` (
    UNIQUE KEY `idx_member_id` (`id`)
  )
  
  TABLE `programmer` (
    UNIQUE KEY `idx_programmer_id` (`id`),
    KEY `idx_programmer_hobby` (`hobby`),
    KEY `idx_programmer_student` (`student`),
    KEY `idx_programmer_years_coding` (`years_coding`),
    KEY `idx_programmer_country` (`country`)
  )
  
  TABLE `section` (
    PRIMARY KEY (`id`),
    KEY `FKtecjgrtoxbeeqpymapva62xfw` (`down_station_id`),
    KEY `FKlfhpg8lrvyr948juittt221ux` (`line_id`),
    KEY `FK18bw17tb86fh1igov96s9i6he` (`up_station_id`),
    CONSTRAINT `FK18bw17tb86fh1igov96s9i6he` FOREIGN KEY (`up_station_id`) REFERENCES `station` (`id`),
    CONSTRAINT `FKlfhpg8lrvyr948juittt221ux` FOREIGN KEY (`line_id`) REFERENCES `line` (`id`),
    CONSTRAINT `FKtecjgrtoxbeeqpymapva62xfw` FOREIGN KEY (`down_station_id`) REFERENCES `station` (`id`)
  )
  
  TABLE `station` (
    PRIMARY KEY (`id`),
    UNIQUE KEY `UK_gnneuc0peq2qi08yftdjhy7ok` (`name`)
  )
   ```


1. 인덱스 설정을 추가하지 않고 아래 요구사항에 대해 1s 이하(M1의 경우 2s)로 반환하도록 쿼리를 작성하세요.

- 활동중인(Active) 부서의 현재 부서관리자 중 연봉 상위 5위안에 드는 사람들이 최근에 각 지역별로 언제 퇴실했는지 조회해보세요. (사원번호, 이름, 연봉, 직급명, 지역, 입출입구분, 입출입시간)
  - 3.280S 나왔습니다 ㅠ
  -  ```
     SELECT  em.id AS '사원번호2',
             em.last_name AS '이름',
             user.annual_income AS '연봉',
             po.position_name AS '직급명',
             re.time AS '입출입시간',
             re.region AS '지역',
             re.record_symbol AS '입출입구분'
     FROM (  SELECT ma.employee_id id, sa.annual_income
             FROM manager ma
             INNER JOIN department de
               ON ma.department_id = de.id
             INNER JOIN salary sa
               ON ma.employee_id = sa.id
             WHERE de.note IN ('aCTIVE')
               AND ma.end_date = '9999-01-01'
               AND sa.used = 0
               AND sa.end_date = '9999-01-01'
             ORDER BY sa.annual_income DESC
             LIMIT 5
     ) user
     INNER JOIN employee em
       ON user.id = em.id
     INNER JOIN position po
       ON em.id = po.id
     INNER JOIN record re
       ON em.id = re.employee_id
     WHERE po.end_date = '9999-01-01'
       AND re.record_symbol = 'O'
     ```

### 2단계 - 인덱스 설계

1. 인덱스 적용해보기 실습을 진행해본 과정을 공유해주세요
   1) Coding as a Hobby 와 같은 결과를 반환하세요. 
      - 1 row(s) returned 4.450 sec 
      - group by 로 할 경우 속도가 더 느려져서 아래 형식으로 변경했습니다..
      - ```
         SELECT ROUND(ROUND((SUM(case when hobby = 'Yes' then cnt else 0 end) 
                            / SUM(cnt)) * 100,2),1) all_hobby_yes,
                ROUND(ROUND((SUM(case when hobby = 'No' then cnt else 0 end)
                            / SUM(cnt))*100,2),1) all_hobby_no,
                ROUND(ROUND((SUM(case when hobby = 'Yes' then pro_cnt else 0 end)
                            / SUM(pro_cnt))*100,2)) pro_hobby_yes,
                ROUND(ROUND((SUM(case when hobby = 'No' then pro_cnt else 0 end)
                            / SUM(pro_cnt))*100,2)) pro_hobby_no
         FROM ( SELECT hobby,
                       1 cnt, 
                       CASE WHEN years_coding NOT IN ('NA') THEN 1 ELSE 0 END pro_cnt
                FROM programmer
          ) data
         ```
   2) 프로그래머별로 해당하는 병원 이름을 반환하세요. (covid.id, hospital.name)
      - 1000 row(s) returned 0.061 sec 
      - ``` 
        add index
        programmer : idx_programmer_id
        covid :idx_covid_id, idx_covid_hospital_id_programmer_id, idx_covid_hospital_id
        hospital : idx_hospital_id
        ``` 
      - ``` 
        SELECT a.id programmerId, b.id covidId, c.name hospitalName
        FROM programmer a
        INNER JOIN covid b
          ON a.id = b.programmer_id
        INNER JOIN hospital c
          ON b.hospital_id = c.id
         ```
   3) 프로그래밍이 취미인 학생 혹은 주니어(0-2년)들이 다닌 병원 이름을 반환하고 user.id 기준으로 정렬하세요. 
      - 1000 row(s) returned 0.056 sec
      - ```
        add idx
        programmer : idx_programmer_hobby, idx_programmer_student, idx_programmer_years_coding
        ```
      - ```
        SELECT b.id covidId, c.name hospitalName, a.hobby, a.dev_type, a.student, a.years_coding
        FROM programmer a
        INNER JOIN covid b
          ON a.id = b.programmer_id
        INNER JOIN hospital c
          ON b.hospital_id = c.id
        WHERE ( a.student LIKE 'Yes%' or a.years_coding IN ('0-2 years') )
          AND  a.hobby IN ('Yes')
         ```
   4) 서울대병원에 다닌 20대 India 환자들을 병원에 머문 기간별로 집계하세요. 
      - 1000 row(s) returned 0.207 sec 
      - ```
         add idx
         member : idx_covid_member_id
         programmer :  idx_covid_programmer_id
         hospital : idx_hospital_name
         ```
      - ```
        SELECT a.stay, count(*)
        FROM covid a
        INNER JOIN member b
          ON a.member_id = b.id
        INNER JOIN programmer c
          ON a.programmer_id = c.id
        INNER JOIN hospital d
          ON a.hospital_id = d.id
        WHERE c.country = 'India'
          AND b.age >= 20 AND b.age <= 29
          AND d.name = '서울대병원' 
        GROUP BY a.stay
        ```
   5) 서울대병원에 다닌 30대 환자들을 운동 횟수별로 집계하세요. (user.Exercise)
      - 1000 row(s) returned 0.226 sec 
      -  ```
         add index
         member : idx_member_id
         ```
      - ```
        SELECT c.exercise, count(*)
        FROM covid a
        INNER JOIN member b
          ON a.member_id = b.id
        INNER JOIN programmer c
          ON a.programmer_id = c.id
        INNER JOIN hospital d
          ON a.hospital_id = d.id
        WHERE b.age >= 30 AND b.age <= 39
          AND d.name = '서울대병원' 
        GROUP BY c.exercise
         ```

### 추가 미션

1. 페이징 쿼리를 적용한 API endpoint를 알려주세요
