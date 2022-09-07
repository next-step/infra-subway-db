select
    i.manager_id as '사원번호',
    i.last_name as '이름',
    i.annual_income as '연봉',
    i.position_name as '직급명',
    j.time as '입출입시간',
    j.region as '지역',
    j.record_symbol as '입출입구분'
from
    (
        SELECT distinct(m.employee_id) as manager_id,
               e.last_name,
               s.annual_income,
               p.position_name
        FROM tuning.department d
                 inner join tuning.manager m on m.department_id = d.id
                 inner join tuning.employee e on e.id = m.employee_id
                 inner join tuning.salary s on s.id = e.id
                 inner join tuning.position p on p.id = e.id
        where d.note = 'active'
          and m.start_date < now() and m.end_date > now()
          and s.start_date < now() and s.end_date > now()
          and p.start_date < now() and p.end_date > now()
        order by s.annual_income desc
        limit 0, 5
    ) i
inner join (
        select r.employee_id, r.region, r.time, r.record_symbol
        from tuning.record r
        where r.record_symbol = 'O'
    ) j
    on j.employee_id = i.manager_id

order by i.annual_income desc, j.region, j.time desc
;
