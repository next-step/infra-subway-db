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

```sql
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

```

---

### 2단계 - 인덱스 설계

1. 인덱스 적용해보기 실습을 진행해본 과정을 공유해주세요

---

### 추가 미션

1. 페이징 쿼리를 적용한 API endpoint를 알려주세요
