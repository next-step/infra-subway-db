## 활동중인(Active) 부서의 현재 부서관리자 중 연봉 상위 5위안에 드는 사람들이 최근에 각 지역별로 언제 퇴실했는지 조회해보세요. (사원번호, 이름, 연봉, 직급명, 지역, 입출입구분, 입출입시간)
-- 인덱스 설정을 추가하지 않고 200ms (0.2sec) 이하로 반환합니다.
-- M1의 경우엔 시간 제약사항을 달성하기 어렵습니다. 2s를 기준으로 해보시고 어렵다면, 일단 리뷰요청 부탁드려요
-- 급여 테이블의 사용여부 필드는 사용하지 않습니다. 현재 근무중인지 여부는 종료일자 필드로 판단해주세요.


# v4 (2022.10.06)
SELECT 
	top_m.id as '사원번호',
    e.last_name as '이름',
    top_m.annual_income as '연봉',
    p.position_name as '직급명', 
    recent_record.region as '지역', 
    recent_record.record_symbol as '입출입구분', 
    recent_record.time as '입출입시간'
FROM (
	SELECT id, annual_income 
	FROM (
		SELECT employee_id
			FROM manager m
			LEFT JOIN department d on d.id = m.department_id
			WHERE end_date >= current_date()
			and lower(d.note) = 'active'
		) AS am 
	INNER JOIN (
		SELECT id, annual_income, end_date 
        FROM salary
	) AS s on am.employee_id = s.id AND s.end_date >= current_date()
	ORDER BY annual_income desc 
	limit 5
) AS top_m
LEFT JOIN position p on p.id = top_m.id AND p.end_date >= current_date()
LEFT JOIN employee e on e.id = top_m.id
LEFT JOIN (
	SELECT employee_id, region, record_symbol, max(time) as time
		from record 
		where record_symbol = 'O'
		group by employee_id, region
) AS recent_record on top_m.id = recent_record.employee_id;




# v3
select 
	top_salary_managers.id, 
	top_salary_managers.last_name, 
    top_salary_managers.annual_income, 
    top_salary_managers.position_name, 
    recent_record.region,
    recent_record.record_symbol,
    recent_record.time
	from (
	select *
		from salary s
		left join (
			select id as sal_sub_id, max(start_date) as recent_date
				from salary
				group by id        
		) as sal_sub on sal_sub.sal_sub_id = s.id and sal_sub.recent_date = s.start_date
		right join (
			select m.employee_id, e.last_name, p.position_name
				from manager m
				left join employee_department ep on ep.employee_id = m.employee_id
				left join department d on d.id = m.department_id
				left join position p on p.id = m.employee_id
				left join employee e on e.id = m.employee_id
				where m.end_date >= current_date()
				and ep.end_date >= current_date()
				and lower(d.note) = 'active'
				and p.end_date >= current_date()
		) as active_managers on active_managers.employee_id = s.id
		where sal_sub.sal_sub_id = s.id and sal_sub.recent_date = s.start_date
		order by s.annual_income desc
		limit 5
    ) as top_salary_managers
    left join (
		select employee_id, region, record_symbol, max(time) as time
			from record 
			where record_symbol = 'O'
			group by employee_id, region
    ) as recent_record on top_salary_managers.id = recent_record.employee_id;
-- Error Code: 1060. Duplicate column name 'id'
-- Error Code: 1060. Duplicate column name 'id'
-- Error Code: 1054. Unknown column 'top_salary_managers.lastname' in 'field list'



# v2
-- select m.employee_id, e.last_name, top_salary.annual_income, p.position_name, recent_record.region, recent_record.time
select *
	from manager m
	left join employee_department ep on ep.employee_id = m.employee_id
    left join department d on d.id = m.department_id
    left join position p on p.id = m.employee_id
--     right join (
-- 		select employee_id, region, max(time) as time
-- 			from record 
-- 			where record_symbol = 'O'
-- 			group by employee_id, region
--     ) as recent_record on recent_record.employee_id = m.employee_id
     -- left join (
-- 		select s.id, s.annual_income
-- 			from salary s
-- 			left join (
-- 				select id, max(start_date) as recent_date
-- 					from salary
-- 					group by id        
-- 			) sal_sub on sal_sub.id = s.id and sal_sub.recent_date = s.start_date
-- 			left join position p on p.id = s.id
-- 			where s.end_date >= current_date()
-- 			and p.end_date >= current_date()
-- 			and p.position_name = 'manager'
-- 			order by s.annual_income desc
-- 			limit 5
-- 	) as top_salary on top_salary.id = m.employee_id
--     left join employee e on e.id = m.employee_id
    where m.end_date >= current_date()
    and ep.end_date >= current_date()
    and lower(d.note) = 'active'
    and p.end_date >= current_date();
    



# v1
select *
	from department d
    left join manager m on m.department_id = d.id
    left join (
		select s.id, s.annual_income
			from salary s
			left join (
				select id, max(start_date) as recent_date
					from salary
					group by id        
			) sal_sub on sal_sub.id = s.id and sal_sub.recent_date = s.start_date
			left join position p on p.id = s.id
			where s.end_date >= current_date()
			and p.end_date >= current_date()
			and p.position_name = 'manager'
			order by s.annual_income desc
			limit 5
    ) as recent_salary on recent_salary.id = m.employee_id
    where lower(d.note) = 'active';


## trouble shooting
-- Error Code: 1235. This version of MySQL doesn't yet support 'LIMIT & IN/ALL/ANY/SOME subquery'


   
