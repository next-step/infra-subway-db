## 테이블 / 인덱스 크기 확인
SELECT
    table_name,
    table_rows,
    round(data_length/(1024*1024),2) as 'DATA_SIZE(MB)',
    round(index_length/(1024*1024),2) as 'INDEX_SIZE(MB)'
FROM information_schema.TABLES
where table_schema = 'subway';

## 미사용 인덱스 확인
SELECT * FROM sys.schema_unused_indexes;

## 중복 인덱스 확인
SELECT * FROM sys.schema_redundant_indexes;


select * from covid;
select * from favorite;
select * from hospital;
select * from line;
select * from member;
explain select * from programmer;
select * from section;
select * from station;

# 주어진 데이터셋을 활용하여 아래 조회 결과를 100ms 이하로 반환 - M1의 경우엔 시간 제약사항을 달성하기 어렵습니다. 200ms를 기준으로 해보시고 어렵다면, 일단 리뷰요청 부탁드려요
# 1. Coding as a Hobby 와 같은 결과를 반환하세요. : 0.211 -> 0.035
EXPLAIN
SELECT 
	hobby,
	TRUNCATE(count(1) / (SELECT count(1) FROM programmer) * 100, 1)
FROM programmer
GROUP BY hobby;

SELECT count(1) FROM programmer;


# 2. 프로그래머별로 해당하는 병원 이름을 반환하세요. (covid.id, hospital.name)
-- 0.0040 -> 0.0027 (pk만 적용)->  0.0015 (covid에 id+hospital_id index 적용)
EXPLAIN;
SELECT 
	c.id,
    h.name
FROM hospital h
INNER JOIN covid c ON c.hospital_id = h.id;

SELECT * FROM programmer;
select count(1) from covid;
SELECT count(DISTINCT programmer_id) FROM covid;
SELECT * FROM hospital;

# 3. 프로그래밍이 취미인 학생 혹은 주니어(0-2년)들이 다닌 병원 이름을 반환하고 user.id 기준으로 정렬하세요. (covid.id, hospital.name, user.Hobby, user.DevType, user.YearsCoding)
-- v1
EXPLAIN;
SELECT 
	c.programmer_id,
	h.name
FROM hospital h
INNER JOIN covid c ON c.hospital_id = h.id
INNER JOIN (SELECT id FROM programmer WHERE hobby = 'Yes' AND (dev_type LIKE 'Student%' OR years_coding_prof = '0-2 years')) AS p ON p.id = c.programmer_id
ORDER BY c.programmer_id;

-- v2
-- EXPLAIN
SELECT
	covid.programmer_id,
	h.name 
FROM hospital h
INNER JOIN (
	SELECT c.hospital_id, c.programmer_id
	FROM covid c
	INNER JOIN (
		SELECT id FROM programmer WHERE hobby = 'Yes' AND (dev_type LIKE 'Student%' OR years_coding_prof = '0-2 years')
	) AS p ON p.id = c.programmer_id
) AS covid ON covid.hospital_id = h.id
ORDER BY covid.programmer_id;


-- v3
-- EXPLAIN;
SELECT 
	covid.programmer_id,
	h.name 
FROM hospital h
INNER JOIN (
	SELECT c.hospital_id, c.programmer_id
	FROM covid c
	WHERE c.programmer_id in (SELECT id FROM programmer WHERE hobby = 'Yes' AND (dev_type LIKE 'Student%' OR years_coding_prof = '0-2 years'))
) covid ON covid.hospital_id = h.id
ORDER BY covid.programmer_id;


SELECT c.hospital_id, c.programmer_id
FROM covid c
INNER JOIN (
	SELECT id FROM programmer WHERE hobby = 'Yes' AND (dev_type LIKE 'Student%' OR years_coding_prof = '0-2 years')
) AS p ON p.id = c.programmer_id;

SELECT c.hospital_id, c.programmer_id
FROM covid c
WHERE c.programmer_id in (SELECT id FROM programmer WHERE hobby = 'Yes' AND (dev_type LIKE 'Student%' OR years_coding_prof = '0-2 years'));



# 4. 서울대병원에 다닌 20대 India 환자들을 병원에 머문 기간별로 집계하세요. (covid.Stay)
-- hospital name, member age, programmer country, covid stay 

EXPLAIN
SELECT
	stay,
	count(1) as cnt
FROM (SELECT id FROM hospital WHERE name = '서울대병원') AS h
INNER JOIN (SELECT hospital_id, member_id, programmer_id, stay FROM covid) as c ON c.hospital_id = h.id
INNER JOIN (SELECT id FROM member WHERE age between 20 and 29) AS m ON c.member_id = m.id
INNER JOIN (SELECT id FROM programmer WHERE country = 'India') AS p ON c.programmer_id = p.id
GROUP BY stay;



# [강의예제] 5. 서울대병원에 다닌 30대 환자들을 운동 횟수별로 집계하세요. (user.Exercise) 
-- covid: , hospital: name, member: age, programmer: exercise
SELECT id FROM member where age between 30 and 39;
SELECT id FROM hospital where name = '서울대병원';
SELECT id, hospital_id FROM covid;
SELECT id, exercise FROM programmer;

EXPLAIN;
SELECT 
	exercise,
    count(A.id)
FROM (SELECT id FROM hospital where name = '서울대병원') AS B
INNER JOIN (SELECT id, hospital_id FROM covid) AS C ON C.hospital_id = B.id 
INNER JOIN (SELECT id FROM member where age between 30 and 39) AS M ON M.id = C.id 
INNER JOIN (SELECT id, exercise FROM programmer) AS A ON A.id = C.id 
GROUP BY exercise
ORDER BY null;


