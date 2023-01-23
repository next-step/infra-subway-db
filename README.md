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
    eid,
    name,
    income,
    position_name,
    r.time as time,
    r.region as region,
    r.record_symbol as symbol
from
    (
    select
        e.id as eid,
        e.last_name as name,
        'Manager' as position_name,
        s.annual_income as income
    from employee e
    inner join manager m on e.id = m.employee_id
    inner join department d on d.id = m.department_id
    inner join salary s on s.id = e.id
    where
        m.end_date = '9999-01-01' and
        s.end_date = '9999-01-01' and
        d.note = 'active'
    order by income desc
    limit 5
    ) t
    inner join record r on r.employee_id = t.eid
where r.record_symbol = 'O'
order by income desc;
```

---

### 2단계 - 인덱스 설계

1. 인덱스 적용해보기 실습을 진행해본 과정을 공유해주세요

- Coding as a Hobby와 같은 결과값 반환

```sql
alter table programmer
change column id bigint(20) not null,
add primary key (id);

create index 'idx_programmer_hobby'
on programmer(hobby)

select
   hobby,
   round(count(*) / (select count(id) from programmer) * 100, 1) as percent
from
    programmer
group by
    hobby;
```

- 프로그래머 별로 해당하는 병원 이름을 반환(covid.id, hospital.name)

```sql
alter table hospital
change column id int(11) not null,
add primary key (id);

alter table covid
change column hospital_id int(11),
add primary key (id),
add foreign key (hospital_id) references hospital(id),
add foreign key (programmer_id) references programmer(id);

select
    c.id,
    h.name
from covid c 
inner join hospital h on c.hospital_id = h.id
inner join programmer p on c.programmer_id = p.id;
```

- 프로그래밍이 취미인 학생 혹은 주니어(0-2년)들이 다닌 병원 이름을 반환하고, user.id 기준으로 정렬(covid.id, hospital.name, user.hobby, user.devType, user.yearsCoding)

```sql
select
    c.id,
    h.name,
    p.hobby,
    p.dev_type,
    p.years_coding
from covid c
    inner join hospital h on c.hospital_id = h.id
    inner join programmer p on c.programmer_id = p.id
where
    (p.hobby = 'yes' and p.student != 'no' and p.student != 'na') or
    p.years_coding = '0-2 years';
```

- 서울대병원에 다닌 20대 India 환자들을 병원에 머문 기간별로 집계(covid.stay)

```sql
alter table member
change column id bigint(20) not null,
add primary key(id),

create index 'idx_programmer_country'
on programmer(country)

create index 'idx_member_age'
on member(age)

create index 'idx_covid_stay'
on covic(stay)

select
    count(c.stay) as cnt,
    c.stay
from programmer p
    inner join covid c on p.id = c.programmer_id
    inner join member m on p.id = m.id
where
    p.country = 'india' and
    m.age between 20 and 29
group by c.stay;
```

- 서울대병원에 다닌 30대 환자들을 운동 횟수별로 집계(user.exercise)

```sql
create index 'idx_programmer_exercise'
on programmer(exercise)

select
    count(p.exercise) as cnt,
    p.exercise
from programmer p
    inner join covid c on p.id = c.programmer_id
    inner join hospital h on c.hospital_id = h.id
    inner join member m on m.id = p.id
where
    h.id = 9 and
    m.age between 30 and 39
group by p.exercise;
```

---

### 추가 미션

1. 페이징 쿼리를 적용한 API endpoint를 알려주세요
