# index column 은 가공하지 말 것
EXPLAIN 
SELECT *
	FROM tuning.employee
WHERE SUBSTRING(id, 1, 4) = 1100
AND LENGTH(id) = 5;

EXPLAIN 
SELECT *
	FROM tuning.employee
WHERE id BETWEEN 11000 AND 11009;


# 인덱스 순서를 고려할 것
EXPLAIN
SELECT first_name, sex, COUNT(1) AS 카운트
	FROM tuning.employee
GROUP BY first_name, sex;

EXPLAIN
SELECT first_name, sex, COUNT(1) AS 카운트
	FROM tuning.employee
GROUP BY sex, first_name;


# 인덱스를 제대로 사용하는지 확인할 것! 
EXPLAIN 
SELECT id
	FROM tuning.employee
	WHERE join_date LIKE '1989%'
	AND id > 100000;

SELECT 
	(SELECT COUNT(1) FROM tuning.employee WHERE join_date LIKE '1989%') AS '입사일자 필터',
	(SELECT COUNT(1) FROM tuning.employee WHERE id > 100000) AS '사원번호 필터';

EXPLAIN 
SELECT id
	FROM tuning.employee
	WHERE join_date >= '1989-01-01' AND join_date < '1990-01-01'
	AND id > 100000;

## covered index
EXPLAIN 
SELECT a.*
FROM (
	-- 서브쿼리에서 커버링 인덱스로만 데이터 조건과 select column을 지정하여 조인
	SELECT id 
    FROM subway.member 
    WHERE age BETWEEN 30 AND 39
) AS b 
JOIN programmer a ON b.id = a.id;



# 복합 인덱스에서는 범위 검색 컬럼은 뒤로 두는 것이 좋다. 
CREATE INDEX `idx_employee_id_time`  ON `tuning`.`record` (employee_id,time);
DROP INDEX `idx_employee_id_time` ON `tuning`.`record`;

CREATE INDEX `idx_time_employee_id`  ON `tuning`.`record` (time,employee_id);
DROP INDEX `idx_time_employee_id` ON `tuning`.`record`;
-- EXPLAIN 
SELECT * FROM tuning.record WHERE employee_id = 110183 AND time BETWEEN '2020-01-01' AND '2020-08-30';


# 인덱스 구성 확인하기
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


# 데이터가 적은 테이블을 랜덤 엑세스 해야한다. 
select * from employee_department;
select * from department;

EXPLAIN
SELECT 
	mapping.employee_id,
	department.id
    FROM tuning.employee_department mapping,
		department
	WHERE mapping.department_id = department.id;

-- EXPLAIN
SELECT STRAIGHT_JOIN
	mapping.employee_id,
	department.id
    FROM tuning.employee_department mapping,
		department
	WHERE mapping.department_id = department.id;

# 모수 테이블의 수를 줄이자
-- EXPLAIN
SELECT employee.id, employee.last_name, employee.first_name, employee.join_date
	FROM tuning.employee, tuning.salary
    WHERE employee.id = salary.id
    AND employee.id BETWEEN 10001 AND 50000
    GROUP BY employee.id
    ORDER BY SUM(salary.annual_income) DESC
    LIMIT 150,10;

-- EXPLAIN    
SELECT employee.id, employee.last_name, employee.first_name, employee.join_date
	FROM (
		SELECT id
			FROM tuning.salary
            WHERE id BETWEEN 10001 AND 50000
            GROUP BY id
            ORDER BY SUM(salary.annual_income) DESC
            LIMIT 150,10
	) salary,
	employee
WHERE employee.id = salary.id;



# 웬만하면 서브쿼리보다는 조인문을 쓰자
EXPLAIN EXTENDED
SELECT *
	FROM tuning.employee
    WHERE id IN (SELECT id FROM salary);    

SHOW WARNINGS;    
-- /* select#1 */ select `tuning`.`employee`.`id` AS `id`,`tuning`.`employee`.`birth` AS `birth`,`tuning`.`employee`.`last_name` AS `last_name`,`tuning`.`employee`.`first_name` AS `first_name`,`tuning`.`employee`.`sex` AS `sex`,`tuning`.`employee`.`join_date` AS `join_date` from `tuning`.`employee` semi join (`tuning`.`salary`) where (`tuning`.`salary`.`id` = `tuning`.`employee`.`id`)
