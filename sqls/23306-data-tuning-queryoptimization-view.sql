## 피드백 적용 (2022.10.10)
explain select * from department where note = 'active';
explain select * from department where lower(note) = 'active';



## 피드백 적용 (2022.10.09)
-- 크게 두 덩어리로 나누어서 볼 것 : 활동중인(Active) 부서의 현재 부서관리자 중 연봉 상위 5위안에 드는 사람들 + 최근에 각 지역별로 언제 퇴실

# 활동중인(Active) 부서의 현재 부서관리자 중 연봉 상위 5위안에 드는 사람들
SELECT am.employee_id, s.annual_income 
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
INNER JOIN position p on p.id = am.employee_id AND p.end_date >= current_date()
INNER JOIN employee e on e.id = am.employee_id
ORDER BY annual_income desc 
limit 5;

# 최근에 각 지역별로 언제 퇴실했는지
-- region 테이블 : 한 지역에 반복적으로 갔던 케이스가 없다. 집계함수 필요 없음
select * from record;






## 연봉 상위 5위 피드백 (2022.10.06)
-- 이 구간이 너무 느린데요.
-- position 테이블을 조인하는 것보다 manager 테이블을 조인하는 것은 어떨까요?
SELECT id, annual_income 
FROM (
	SELECT employee_id, end_date FROM manager WHERE end_date >= current_date()
    ) AS m 
INNER JOIN (
	SELECT id, annual_income, end_date FROM salary
) AS s on m.employee_id = s.id AND s.end_date >= current_date()
ORDER BY annual_income desc 
limit 5;

## 피드백 결과로 재구성 (2022.10.06) / 활동중인(Active) 부서의 현재 부서관리자 중 연봉 상위 5위안에 드는 사람들
SELECT id, annual_income 
FROM (
	SELECT employee_id
		FROM manager m
		LEFT JOIN department d on d.id = m.department_id
		WHERE end_date >= current_date()
		and lower(d.note) = 'active'
    ) AS am 
INNER JOIN (
	SELECT id, annual_income, end_date FROM salary
) AS s on am.employee_id = s.id AND s.end_date >= current_date()
ORDER BY annual_income desc 
limit 5;

SELECT employee_id, end_date 
	FROM manager m
    LEFT JOIN department d on d.id = m.department_id
    WHERE end_date >= current_date()
    and lower(d.note) = 'active';
SELECT employee_id FROM manager WHERE end_date >= current_date();
select * from manager where employee_id = '111534';


## 활동중인(Active) 부서의 현재 부서관리자 중 연봉 상위 5위안에 드는 사람들이 최근에 각 지역별로 언제 퇴실했는지 조회해보세요. (사원번호, 이름, 연봉, 직급명, 지역, 입출입구분, 입출입시간)
-- 인덱스 설정을 추가하지 않고 200ms (0.2sec) 이하로 반환합니다.
-- M1의 경우엔 시간 제약사항을 달성하기 어렵습니다. 2s를 기준으로 해보시고 어렵다면, 일단 리뷰요청 부탁드려요
-- 급여 테이블의 사용여부 필드는 사용하지 않습니다. 현재 근무중인지 여부는 종료일자 필드로 판단해주세요.

# 필요한 정보
-- 사원번호, 이름, 연봉, 직급명, 지역, 입출입구분, 입출입시간
-- employee_id, first_name, annual_income, position_name, region, record_symbol, time
-- department, employee, salary, position, record

# 활동중인 부서
select * from department where lower(note) = 'active';

# 현재 근무중인 부서 관리자
select * from manager where end_date >= current_date();
select * from employee_department where end_date >= current_date();
select * 
	from manager m
	left join employee_department ep on ep.employee_id = m.employee_id
    where m.end_date >= current_date()
    and ep.end_date >= current_date();

# 직원들이 각 지역별 언제 퇴실(O)
select * from record;
select employee_id, record_symbol, max(time) as time
	from record 
    where record_symbol = 'O'
    group by employee_id;


# (사원번호, 이름, 연봉, 직급명, 지역, 입출입구분, 입출입시간)
select m.employee_id, e.last_name, p.position_name
	from manager m
	left join employee_department ep on ep.employee_id = m.employee_id
    left join department d on d.id = m.department_id
    left join position p on p.id = m.employee_id
    left join employee e on e.id = m.employee_id
    where m.end_date >= current_date()
    and ep.end_date >= current_date()
    and lower(d.note) = 'active'
    and p.end_date >= current_date();




# 연봉 상위 5위
select * from salary where id = '110228';
select id, max(start_date)
	from salary
--     where id = '110228'
	group by id;
select id, max(start_date) as recent_date
	from salary
	group by id;

select * from salary where id = 51953 order by start_date desc;
select *
	from salary s
	left join (
		select id as sal_sub_id, max(start_date) as recent_date
			from salary
			group by id        
	) as sal_sub on sal_sub.sal_sub_id = s.id and sal_sub.recent_date = s.start_date
    right join (
		select m.employee_id
			from manager m
			left join employee_department ep on ep.employee_id = m.employee_id
			left join department d on d.id = m.department_id
			left join position p on p.id = m.employee_id
			where m.end_date >= current_date()
			and ep.end_date >= current_date()
			and lower(d.note) = 'active'
			and p.end_date >= current_date()
    ) as active_managers on active_managers.employee_id = s.id
    where sal_sub.sal_sub_id = s.id and sal_sub.recent_date = s.start_date
    order by s.annual_income desc
    limit 5;
-- Error Code: 1054. Unknown column 'sal_sub.id' in 'where clause'
-- Error Code: 1054. Unknown column 'sal_sub.id' in 'where clause'

	left join employee_department ep on ep.employee_id = s.id
    left join position p on p.id = s.id
    and s.end_date >= current_date()
	and ep.end_date >= current_date()
	and p.end_date >= current_date()
    and p.position_name = 'manager';


-- '10001', '88958'
-- '10002', '72527'
-- '51952', '91918'
-- '51953', '64254'




select * 
	from manager m
	right join (
		select s.id, s.annual_income
			from salary s
			left join (
				select id, max(start_date) as recent_date
					from salary
					group by id        
			) sal_sub on sal_sub.id = s.id and sal_sub.recent_date = s.start_date
			where s.end_date >= current_date()
            order by s.annual_income desc
			limit 5
    ) as top_salary on top_salary.id = m.employee_id;




## 연봉 상위 5위안에 드는 현재 근무중인 매니저들
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
    limit 5;

-- '110022', '108407'
-- '110039', '106491'
-- '111400', '103244'
-- '111133', '101987'
-- '111035', '95873'

-- '110039', '106491'
-- '111133', '101987'
-- '110114', '83457'
-- '111534', '79393'
-- '110567', '74510'


select id
	from salary
    where (id, start_date) in (
		select id, max(start_date)
        from salary
        group by id        
    )
    and end_date >= current_date()
    order by annual_income desc
    limit 5;
-- '43624'
-- '254466'
-- '47978'
-- '253939'
-- '109334'

