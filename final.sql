-- 2014년~2019년 월별 응급실 이용자 수 상위 10개를 출력
-- 대체적으로 12월에 응급실 이용자가 많다.
select period_year "연도"
       , period_month "월"
       , round(cnt, 1) "이용자 수"
    from er_month
    unpivot (cnt for period_month in (jan, feb, mar, apr, may, jun, jul, aug, sep, oct, nov, dece))
    where age = '합계'
        and sex = '계'
    order by to_number(cnt) desc fetch first 10 rows only;
    
    
with er_month_up as ( select *
                        from er_month
                        unpivot (cnt for period_month in (jan, feb, mar, apr, may, jun, jul, aug, sep, oct, nov, dece))
                        where age = '합계'
                            and sex = '계' )
select period_year "연도"
       , period_month "월"
       , to_char(round(cnt, 1), '999,999') "이용자 수"
       , to_char(round(cnt, 1) - ( select min(to_number(cnt)) from er_month_up ), '999,999') "최솟값과 차이"
    from er_month_up
    order by to_number(cnt) desc fetch first 10 rows only;    



-- 년도별 응급실 이용자 수 1~3위만 출력
with er_month_rank as ( select period_year
                               , period_month
                               , round(cnt, 1) cnt
                               , rank() over (partition by period_year
                                              order by to_number(cnt) desc) 순위
                            from er_month
                            unpivot (cnt for period_month in (jan, feb, mar, apr, may, jun, jul, aug, sep, oct, nov, dece))
                            where age = '합계'
                                and sex = '계' )
select *
    from er_month_rank
    where 순위 <= 3;
    

with er_month_rank as ( select period_year
                               , period_month
                               , round(cnt, 1) cnt
                               , rank() over (partition by period_year
                                              order by to_number(cnt) desc) 순위
                            from er_month
                            unpivot (cnt for period_month in (jan, feb, mar, apr, may, jun, jul, aug, sep, oct, nov, dece))
                            where age = '합계'
                                and sex = '계' )
select period_year "연도"
       , listagg(period_month || '(' || cnt || ')', ', ') within group (order by 순위 asc) "월(이용자 수)"
    from er_month_rank
    where 순위 <= 3
    group by period_year;   


-- 2014년~2019년 요일별 응급실 이용자 수 상위 10개를 출력
-- 대체적으로 주말에 응급실 이용자가 많다.
-- 주말에는 병원 문을 안 열기 때문이다.
select period_year, period_day, round(cnt, 1) cnt
    from er_day
    unpivot (cnt for period_day in (mon, tue, wed, thu, fri, sat, sun))
    where age = '합계'
        and sex = '계'
    order by to_number(cnt) desc fetch first 10 rows only;
    
    
with er_day_up as ( select *
                        from er_day
                        unpivot (cnt for period_day in (mon, tue, wed, thu, fri, sat, sun))
                        where age = '합계'
                            and sex = '계' )
select period_year "연도"
       , period_day "요일"
       , to_char(round(cnt, 1), '999,999') "이용자 수"
       , to_char(round(cnt, 1) - ( select min(to_number(cnt)) from er_day_up ), '999,999') "최솟값과 차이"
    from er_day_up
    order by to_number(cnt) desc fetch first 10 rows only;    
    
    
-- 년도별 응급실 이용자 수 1~3위만 출력
-- 주말은 병원 문을 안 열기 때문에 제외한다.
-- 대부분 월요일, 금요일, 화요일에 이용자가 많다.
with er_day_rank as ( select period_year
                             , period_day
                             , round(cnt, 1) cnt
                             , rank() over (partition by period_year
                                            order by to_number(cnt) desc) 순위
                        from er_day
                        unpivot (cnt for period_day in (mon, tue, wed, thu, fri, sat, sun))
                        where age = '합계'
                            and sex = '계'
                            and period_day not in ('SAT', 'SUN'))
select *
    from er_day_rank
    where 순위 <= 3;
    
    
with er_day_rank as ( select period_year
                             , period_day
                             , round(cnt, 1) cnt
                             , rank() over (partition by period_year
                                            order by to_number(cnt) desc) 순위
                        from er_day
                        unpivot (cnt for period_day in (mon, tue, wed, thu, fri, sat, sun))
                        where age = '합계'
                            and sex = '계'
                            and period_day not in ('SAT', 'SUN'))
select period_year "연도"
       , listagg(period_day || '(' || cnt || ')', ', ') within group (order by 순위 asc) "요일(이용자 수)"
    from er_day_rank
    where 순위 <= 3
    group by period_year;      
    
    
-- 성별에 따른 요일 차이 
with er_day_sex as ( select period_year, sex, period_day, round(to_number(cnt), 1) cnt
                        from er_day
                        unpivot (cnt for period_day in (mon, tue, wed, thu, fri, sat, sun))
                        where age = '합계'
                            and sex != '계' )
select sex, period_day, sum(cnt) 합계
    from er_day_sex
    group by sex, period_day
    order by 1, 3 desc;    
 
 
-- 연령별 순서대로 보기 위해 값 변경
update er_day
    set age = '01 - 09세'
    where age = '1 - 9세';  
    
update er_day
    set age = '00 - 01세'
    where age = '1세미만';  
    
commit;

-- 연령별 이용시간 순위 1위
with er_day_age as ( select period_year, age, period_day, round(to_number(cnt), 1) cnt
                        from er_day
                        unpivot (cnt for period_day in (mon, tue, wed, thu, fri, sat, sun))
                        where age not in ('합계', '연령미상')
                            and sex = '계'
                            and period_day not in ('SAT', 'SUN')),
     er_day_rank as ( select age, period_day, sum(cnt) 합계
                             , rank() over( partition by age
                                            order by age, sum(cnt) desc ) 순위
                        from er_day_age
                        group by age, period_day )
select age "연령대", period_day "요일", 합계
    from er_day_rank
    where 순위 = 1;   
 
    
-- 2014년~2019년 시간별 응급실 이용자 수 상위 10개를 출력
-- 대체적으로 오후 6시~오후 9시에 이용자가 많다.
-- 병원 문을 닫아서 그런듯
select period_year, period_hour, round(cnt, 1) cnt
    from er_hour
    unpivot (cnt for period_hour in (h0to3, h3to6, h6to9, h9to12, h12to15, h15to18, h18to21, h21to24))
    where age = '합계'
        and sex = '계'
    order by to_number(cnt) desc fetch first 10 rows only;    
    
    
    
with er_hour_up as ( select *
                        from er_hour
                        unpivot (cnt for period_hour in (h0to3, h3to6, h6to9, h9to12, h12to15, h15to18, h18to21, h21to24))
                        where age = '합계'
                            and sex = '계' )
select period_year "연도"
       , period_hour "시간"
       , to_char(round(cnt, 1), '999,999') "이용자 수"
       , to_char(round(cnt, 1) - ( select min(to_number(cnt)) from er_hour_up ), '999,999') "최솟값과 차이"
    from er_hour_up
    order by to_number(cnt) desc fetch first 10 rows only;      
    
    
-- 성별에 따른 이용시간 차이    
with er_hour_sex as ( select period_year, sex, period_hour, round(to_number(cnt), 1) cnt
                            from er_hour
                            unpivot (cnt for period_hour in (h0to3, h3to6, h6to9, h9to12, h12to15, h15to18, h18to21, h21to24))
                            where age = '합계'
                                and sex != '계' )
select sex, period_hour, sum(cnt) 합계
    from er_hour_sex
    group by sex, period_hour
    order by 1, 3 desc;      
    

-- 연령별 순서대로 보기 위해 값 변경
update er_hour
    set age = '01 - 09세'
    where age = '1 - 9세';  
    
update er_hour
    set age = '00 - 01세'
    where age = '1세미만';  
    
commit;

-- 연령별 이용시간 순위 1위
with er_hour_age as ( select period_year, age, period_hour, round(to_number(cnt), 1) cnt
                            from er_hour
                            unpivot (cnt for period_hour in (h0to3, h3to6, h6to9, h9to12, h12to15, h15to18, h18to21, h21to24))
                            where age not in ('합계', '연령미상')
                                and sex = '계' ),
     er_hour_rank as ( select age, period_hour, sum(cnt) 합계
                              , rank() over( partition by age
                                             order by age, sum(cnt) desc ) 순위
                            from er_hour_age
                            group by age, period_hour )
select age "연령대", period_hour "시간", 합계
    from er_hour_rank
    where 순위 = 1;    
    
 
-- 년도별 응급실 이용자 수 1~3위만 출력  
-- 대부분 오후 6~12시에 이용자가 많다.
with er_hour_rank as ( select period_year
                             , period_hour
                             , round(cnt, 1) cnt
                             , rank() over (partition by period_year
                                            order by to_number(cnt) desc) 순위
                        from er_hour
                        unpivot (cnt for period_hour in (h0to3, h3to6, h6to9, h9to12, h12to15, h15to18, h18to21, h21to24))
                        where age = '합계'
                            and sex = '계' )
select *
    from er_hour_rank
    where 순위 <= 3;
    
    
with er_hour_rank as ( select period_year
                             , period_hour
                             , round(cnt, 1) cnt
                             , rank() over (partition by period_year
                                            order by to_number(cnt) desc) 순위
                        from er_hour
                        unpivot (cnt for period_hour in (h0to3, h3to6, h6to9, h9to12, h12to15, h15to18, h18to21, h21to24))
                        where age = '합계'
                            and sex = '계' )
select period_year "연도"
       , listagg(period_hour || '(' || cnt || ')', ', ') within group (order by 순위 asc) "시간대(이용자 수)"
    from er_hour_rank
    where 순위 <= 3
    group by period_year;
    
    
-- 2014년~2019년 응급실 내원사유를 내림차순으로 출력
-- 질병이 가장 많고 부딪히거나 미끄러져서 내원하는 사람이 많다
with er_reason_kr as ( select 기간, 질병 r1, 교통사고 r2, 추락 r3, 미끄러짐 r4, 부딪힘 r5, 베임찔림 r6,
                              기계 r7, 화상 r8, 익수 r9, 중독 r10, 질식 r11, 기타 r12, 진료외방문 r13
                            from er_reason
                            where 연령별 = '합계'
                                and 성별 = '계' )
select 기간 "연도", reason "내원사유", round(cnt, 1) "이용자 수"
    from er_reason_kr
    unpivot (cnt for reason in (r1 as '질병', r2 as '교통사고', r3 as '추락', r4 as '미끄러짐', 
                                r5 as '부딪힘', r6 as '베임찔림', r7 as '기계', r8 as '화상', 
                                r9 as '익수', r10 as '중독', r11 as '질식', r12 as '기타', 
                                r13 as '진료외방문'))
    order by to_number(cnt) desc;
    
    
-- 내원사유에 따른 연도별 이용자수 증감비율   
with er_reason_kr as ( select 기간, 질병 r1, 교통사고 r2, 추락 r3, 미끄러짐 r4, 부딪힘 r5, 베임찔림 r6,
                              기계 r7, 화상 r8, 익수 r9, 중독 r10, 질식 r11, 기타 r12, 진료외방문 r13
                            from er_reason
                            where 연령별 = '합계'
                                and 성별 = '계' ),
    er_reason_cp as ( select 기간 "연도", reason "내원사유", round(cnt, 1) "이용자수"
                             , lag(round(cnt, 1), 1) over (order by reason, 기간 asc) 이전행
                            from er_reason_kr
                            unpivot (cnt for reason in (r1 as '질병', r2 as '교통사고', r3 as '추락', r4 as '미끄러짐', 
                                                        r5 as '부딪힘', r6 as '베임찔림', r7 as '기계', r8 as '화상', 
                                                        r9 as '익수', r10 as '중독', r11 as '질식', r12 as '기타', 
                                                        r13 as '진료외방문')) )
select cp.*, case when mod(rownum, 6) != 1 then round(((이용자수-이전행)/이전행)*100, 3) || '%'
             else null end as 증감
    from er_reason_cp cp;    
    

-- 성별에 따라 내원하는 사유가 다르다.
-- 남자는 부딪혀서 제일 많이 오고, 여자는 진료외방문과 미끄러져서 제일 많이 온다.
-- 남자가 여자에 비해 상대적으로 교통사고로 오는 경우가 많다.
with er_reason_kr as ( select 기간, 성별, 질병 r1, 교통사고 r2, 추락 r3, 미끄러짐 r4, 부딪힘 r5, 베임찔림 r6,
                              기계 r7, 화상 r8, 익수 r9, 중독 r10, 질식 r11, 기타 r12, 진료외방문 r13
                            from er_reason
                            where 연령별 = '합계'
                                and 성별 = '여자' ),
     er_reason_eng as ( select 기간 "연도", 성별, reason "내원사유", round(to_number(cnt), 1) "이용자수"
                            from er_reason_kr
                            unpivot (cnt for reason in (r1 as '질병', r2 as '교통사고', r3 as '추락', r4 as '미끄러짐', 
                                                        r5 as '부딪힘', r6 as '베임찔림', r7 as '기계', r8 as '화상', 
                                                        r9 as '익수', r10 as '중독', r11 as '질식', r12 as '기타', 
                                                        r13 as '진료외방문'))
                            where reason != '질병' )
select 성별, 내원사유, sum(이용자수) 합계
       , rank() over (order by sum(이용자수) desc) 순위
    from er_reason_eng
    group by 성별, 내원사유;
    
    
    
with er_reason_kr as ( select 기간, 성별, 질병 r1, 교통사고 r2, 추락 r3, 미끄러짐 r4, 부딪힘 r5, 베임찔림 r6,
                              기계 r7, 화상 r8, 익수 r9, 중독 r10, 질식 r11, 기타 r12, 진료외방문 r13
                            from er_reason
                            where 연령별 = '합계'
                                and 성별 = '남자' ),
     er_reason_eng as ( select 기간 "연도", 성별, reason "내원사유", round(to_number(cnt), 1) "이용자수"
                            from er_reason_kr
                            unpivot (cnt for reason in (r1 as '질병', r2 as '교통사고', r3 as '추락', r4 as '미끄러짐', 
                                                        r5 as '부딪힘', r6 as '베임찔림', r7 as '기계', r8 as '화상', 
                                                        r9 as '익수', r10 as '중독', r11 as '질식', r12 as '기타', 
                                                        r13 as '진료외방문'))
                            where reason != '질병' )
select 성별, 내원사유, sum(이용자수) 합계
       , rank() over (order by sum(이용자수) desc) 순위
    from er_reason_eng
    group by 성별, 내원사유;
 
    

-- 연령별 순서대로 보기 위해 값 변경
update er_reason
    set 연령별 = '01 - 09세'
    where 연령별 = '1 - 9세';  
    
update er_reason
    set 연령별 = '00 - 01세'
    where 연령별 = '1세미만';  
    
commit;


-- 각 연령별 내원 사유 1위만 출력
-- 추락과 부딪힘에서 베임찔림에서 미끄러짐 (진료외방문은 치료 목적이 아니기 때문에 제외)
with er_reason_kr as ( select 기간, 연령별, 질병 r1, 교통사고 r2, 추락 r3, 미끄러짐 r4, 부딪힘 r5, 베임찔림 r6,
                              기계 r7, 화상 r8, 익수 r9, 중독 r10, 질식 r11, 기타 r12, 진료외방문 r13
                            from er_reason
                            where 연령별 not in ('합계', '연령미상')
                                and 성별 = '계' ),
     er_reason_eng as ( select 기간, 연령별, reason, cnt
                            from er_reason_kr
                            unpivot (cnt for reason in (r1 as '질병', r2 as '교통사고', r3 as '추락', r4 as '미끄러짐', 
                                                        r5 as '부딪힘', r6 as '베임찔림', r7 as '기계', r8 as '화상', 
                                                        r9 as '익수', r10 as '중독', r11 as '질식', r12 as '기타', 
                                                        r13 as '진료외방문'))
                            where reason not in ('질병', '진료외방문') ),
     er_reason_rank as ( select 연령별, reason 내원사유, sum(cnt) 합계
                                , rank() over ( partition by 연령별
                                               order by sum(cnt) desc ) 순위
                             from er_reason_eng
                             group by 연령별, reason )
select 연령별, 내원사유, 합계
    from er_reason_rank
    where 순위 = 1;