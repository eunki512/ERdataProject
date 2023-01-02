-- 2014��~2019�� ���� ���޽� �̿��� �� ���� 10���� ���
-- ��ü������ 12���� ���޽� �̿��ڰ� ����.
select period_year "����"
       , period_month "��"
       , round(cnt, 1) "�̿��� ��"
    from er_month
    unpivot (cnt for period_month in (jan, feb, mar, apr, may, jun, jul, aug, sep, oct, nov, dece))
    where age = '�հ�'
        and sex = '��'
    order by to_number(cnt) desc fetch first 10 rows only;
    
    
with er_month_up as ( select *
                        from er_month
                        unpivot (cnt for period_month in (jan, feb, mar, apr, may, jun, jul, aug, sep, oct, nov, dece))
                        where age = '�հ�'
                            and sex = '��' )
select period_year "����"
       , period_month "��"
       , to_char(round(cnt, 1), '999,999') "�̿��� ��"
       , to_char(round(cnt, 1) - ( select min(to_number(cnt)) from er_month_up ), '999,999') "�ּڰ��� ����"
    from er_month_up
    order by to_number(cnt) desc fetch first 10 rows only;    



-- �⵵�� ���޽� �̿��� �� 1~3���� ���
with er_month_rank as ( select period_year
                               , period_month
                               , round(cnt, 1) cnt
                               , rank() over (partition by period_year
                                              order by to_number(cnt) desc) ����
                            from er_month
                            unpivot (cnt for period_month in (jan, feb, mar, apr, may, jun, jul, aug, sep, oct, nov, dece))
                            where age = '�հ�'
                                and sex = '��' )
select *
    from er_month_rank
    where ���� <= 3;
    

with er_month_rank as ( select period_year
                               , period_month
                               , round(cnt, 1) cnt
                               , rank() over (partition by period_year
                                              order by to_number(cnt) desc) ����
                            from er_month
                            unpivot (cnt for period_month in (jan, feb, mar, apr, may, jun, jul, aug, sep, oct, nov, dece))
                            where age = '�հ�'
                                and sex = '��' )
select period_year "����"
       , listagg(period_month || '(' || cnt || ')', ', ') within group (order by ���� asc) "��(�̿��� ��)"
    from er_month_rank
    where ���� <= 3
    group by period_year;   


-- 2014��~2019�� ���Ϻ� ���޽� �̿��� �� ���� 10���� ���
-- ��ü������ �ָ��� ���޽� �̿��ڰ� ����.
-- �ָ����� ���� ���� �� ���� �����̴�.
select period_year, period_day, round(cnt, 1) cnt
    from er_day
    unpivot (cnt for period_day in (mon, tue, wed, thu, fri, sat, sun))
    where age = '�հ�'
        and sex = '��'
    order by to_number(cnt) desc fetch first 10 rows only;
    
    
with er_day_up as ( select *
                        from er_day
                        unpivot (cnt for period_day in (mon, tue, wed, thu, fri, sat, sun))
                        where age = '�հ�'
                            and sex = '��' )
select period_year "����"
       , period_day "����"
       , to_char(round(cnt, 1), '999,999') "�̿��� ��"
       , to_char(round(cnt, 1) - ( select min(to_number(cnt)) from er_day_up ), '999,999') "�ּڰ��� ����"
    from er_day_up
    order by to_number(cnt) desc fetch first 10 rows only;    
    
    
-- �⵵�� ���޽� �̿��� �� 1~3���� ���
-- �ָ��� ���� ���� �� ���� ������ �����Ѵ�.
-- ��κ� ������, �ݿ���, ȭ���Ͽ� �̿��ڰ� ����.
with er_day_rank as ( select period_year
                             , period_day
                             , round(cnt, 1) cnt
                             , rank() over (partition by period_year
                                            order by to_number(cnt) desc) ����
                        from er_day
                        unpivot (cnt for period_day in (mon, tue, wed, thu, fri, sat, sun))
                        where age = '�հ�'
                            and sex = '��'
                            and period_day not in ('SAT', 'SUN'))
select *
    from er_day_rank
    where ���� <= 3;
    
    
with er_day_rank as ( select period_year
                             , period_day
                             , round(cnt, 1) cnt
                             , rank() over (partition by period_year
                                            order by to_number(cnt) desc) ����
                        from er_day
                        unpivot (cnt for period_day in (mon, tue, wed, thu, fri, sat, sun))
                        where age = '�հ�'
                            and sex = '��'
                            and period_day not in ('SAT', 'SUN'))
select period_year "����"
       , listagg(period_day || '(' || cnt || ')', ', ') within group (order by ���� asc) "����(�̿��� ��)"
    from er_day_rank
    where ���� <= 3
    group by period_year;      
    
    
-- ������ ���� ���� ���� 
with er_day_sex as ( select period_year, sex, period_day, round(to_number(cnt), 1) cnt
                        from er_day
                        unpivot (cnt for period_day in (mon, tue, wed, thu, fri, sat, sun))
                        where age = '�հ�'
                            and sex != '��' )
select sex, period_day, sum(cnt) �հ�
    from er_day_sex
    group by sex, period_day
    order by 1, 3 desc;    
 
 
-- ���ɺ� ������� ���� ���� �� ����
update er_day
    set age = '01 - 09��'
    where age = '1 - 9��';  
    
update er_day
    set age = '00 - 01��'
    where age = '1���̸�';  
    
commit;

-- ���ɺ� �̿�ð� ���� 1��
with er_day_age as ( select period_year, age, period_day, round(to_number(cnt), 1) cnt
                        from er_day
                        unpivot (cnt for period_day in (mon, tue, wed, thu, fri, sat, sun))
                        where age not in ('�հ�', '���ɹ̻�')
                            and sex = '��'
                            and period_day not in ('SAT', 'SUN')),
     er_day_rank as ( select age, period_day, sum(cnt) �հ�
                             , rank() over( partition by age
                                            order by age, sum(cnt) desc ) ����
                        from er_day_age
                        group by age, period_day )
select age "���ɴ�", period_day "����", �հ�
    from er_day_rank
    where ���� = 1;   
 
    
-- 2014��~2019�� �ð��� ���޽� �̿��� �� ���� 10���� ���
-- ��ü������ ���� 6��~���� 9�ÿ� �̿��ڰ� ����.
-- ���� ���� �ݾƼ� �׷���
select period_year, period_hour, round(cnt, 1) cnt
    from er_hour
    unpivot (cnt for period_hour in (h0to3, h3to6, h6to9, h9to12, h12to15, h15to18, h18to21, h21to24))
    where age = '�հ�'
        and sex = '��'
    order by to_number(cnt) desc fetch first 10 rows only;    
    
    
    
with er_hour_up as ( select *
                        from er_hour
                        unpivot (cnt for period_hour in (h0to3, h3to6, h6to9, h9to12, h12to15, h15to18, h18to21, h21to24))
                        where age = '�հ�'
                            and sex = '��' )
select period_year "����"
       , period_hour "�ð�"
       , to_char(round(cnt, 1), '999,999') "�̿��� ��"
       , to_char(round(cnt, 1) - ( select min(to_number(cnt)) from er_hour_up ), '999,999') "�ּڰ��� ����"
    from er_hour_up
    order by to_number(cnt) desc fetch first 10 rows only;      
    
    
-- ������ ���� �̿�ð� ����    
with er_hour_sex as ( select period_year, sex, period_hour, round(to_number(cnt), 1) cnt
                            from er_hour
                            unpivot (cnt for period_hour in (h0to3, h3to6, h6to9, h9to12, h12to15, h15to18, h18to21, h21to24))
                            where age = '�հ�'
                                and sex != '��' )
select sex, period_hour, sum(cnt) �հ�
    from er_hour_sex
    group by sex, period_hour
    order by 1, 3 desc;      
    

-- ���ɺ� ������� ���� ���� �� ����
update er_hour
    set age = '01 - 09��'
    where age = '1 - 9��';  
    
update er_hour
    set age = '00 - 01��'
    where age = '1���̸�';  
    
commit;

-- ���ɺ� �̿�ð� ���� 1��
with er_hour_age as ( select period_year, age, period_hour, round(to_number(cnt), 1) cnt
                            from er_hour
                            unpivot (cnt for period_hour in (h0to3, h3to6, h6to9, h9to12, h12to15, h15to18, h18to21, h21to24))
                            where age not in ('�հ�', '���ɹ̻�')
                                and sex = '��' ),
     er_hour_rank as ( select age, period_hour, sum(cnt) �հ�
                              , rank() over( partition by age
                                             order by age, sum(cnt) desc ) ����
                            from er_hour_age
                            group by age, period_hour )
select age "���ɴ�", period_hour "�ð�", �հ�
    from er_hour_rank
    where ���� = 1;    
    
 
-- �⵵�� ���޽� �̿��� �� 1~3���� ���  
-- ��κ� ���� 6~12�ÿ� �̿��ڰ� ����.
with er_hour_rank as ( select period_year
                             , period_hour
                             , round(cnt, 1) cnt
                             , rank() over (partition by period_year
                                            order by to_number(cnt) desc) ����
                        from er_hour
                        unpivot (cnt for period_hour in (h0to3, h3to6, h6to9, h9to12, h12to15, h15to18, h18to21, h21to24))
                        where age = '�հ�'
                            and sex = '��' )
select *
    from er_hour_rank
    where ���� <= 3;
    
    
with er_hour_rank as ( select period_year
                             , period_hour
                             , round(cnt, 1) cnt
                             , rank() over (partition by period_year
                                            order by to_number(cnt) desc) ����
                        from er_hour
                        unpivot (cnt for period_hour in (h0to3, h3to6, h6to9, h9to12, h12to15, h15to18, h18to21, h21to24))
                        where age = '�հ�'
                            and sex = '��' )
select period_year "����"
       , listagg(period_hour || '(' || cnt || ')', ', ') within group (order by ���� asc) "�ð���(�̿��� ��)"
    from er_hour_rank
    where ���� <= 3
    group by period_year;
    
    
-- 2014��~2019�� ���޽� ���������� ������������ ���
-- ������ ���� ���� �ε����ų� �̲������� �����ϴ� ����� ����
with er_reason_kr as ( select �Ⱓ, ���� r1, ������ r2, �߶� r3, �̲����� r4, �ε��� r5, ������ r6,
                              ��� r7, ȭ�� r8, �ͼ� r9, �ߵ� r10, ���� r11, ��Ÿ r12, ����ܹ湮 r13
                            from er_reason
                            where ���ɺ� = '�հ�'
                                and ���� = '��' )
select �Ⱓ "����", reason "��������", round(cnt, 1) "�̿��� ��"
    from er_reason_kr
    unpivot (cnt for reason in (r1 as '����', r2 as '������', r3 as '�߶�', r4 as '�̲�����', 
                                r5 as '�ε���', r6 as '������', r7 as '���', r8 as 'ȭ��', 
                                r9 as '�ͼ�', r10 as '�ߵ�', r11 as '����', r12 as '��Ÿ', 
                                r13 as '����ܹ湮'))
    order by to_number(cnt) desc;
    
    
-- ���������� ���� ������ �̿��ڼ� ��������   
with er_reason_kr as ( select �Ⱓ, ���� r1, ������ r2, �߶� r3, �̲����� r4, �ε��� r5, ������ r6,
                              ��� r7, ȭ�� r8, �ͼ� r9, �ߵ� r10, ���� r11, ��Ÿ r12, ����ܹ湮 r13
                            from er_reason
                            where ���ɺ� = '�հ�'
                                and ���� = '��' ),
    er_reason_cp as ( select �Ⱓ "����", reason "��������", round(cnt, 1) "�̿��ڼ�"
                             , lag(round(cnt, 1), 1) over (order by reason, �Ⱓ asc) ������
                            from er_reason_kr
                            unpivot (cnt for reason in (r1 as '����', r2 as '������', r3 as '�߶�', r4 as '�̲�����', 
                                                        r5 as '�ε���', r6 as '������', r7 as '���', r8 as 'ȭ��', 
                                                        r9 as '�ͼ�', r10 as '�ߵ�', r11 as '����', r12 as '��Ÿ', 
                                                        r13 as '����ܹ湮')) )
select cp.*, case when mod(rownum, 6) != 1 then round(((�̿��ڼ�-������)/������)*100, 3) || '%'
             else null end as ����
    from er_reason_cp cp;    
    

-- ������ ���� �����ϴ� ������ �ٸ���.
-- ���ڴ� �ε����� ���� ���� ����, ���ڴ� ����ܹ湮�� �̲������� ���� ���� �´�.
-- ���ڰ� ���ڿ� ���� ��������� ������� ���� ��찡 ����.
with er_reason_kr as ( select �Ⱓ, ����, ���� r1, ������ r2, �߶� r3, �̲����� r4, �ε��� r5, ������ r6,
                              ��� r7, ȭ�� r8, �ͼ� r9, �ߵ� r10, ���� r11, ��Ÿ r12, ����ܹ湮 r13
                            from er_reason
                            where ���ɺ� = '�հ�'
                                and ���� = '����' ),
     er_reason_eng as ( select �Ⱓ "����", ����, reason "��������", round(to_number(cnt), 1) "�̿��ڼ�"
                            from er_reason_kr
                            unpivot (cnt for reason in (r1 as '����', r2 as '������', r3 as '�߶�', r4 as '�̲�����', 
                                                        r5 as '�ε���', r6 as '������', r7 as '���', r8 as 'ȭ��', 
                                                        r9 as '�ͼ�', r10 as '�ߵ�', r11 as '����', r12 as '��Ÿ', 
                                                        r13 as '����ܹ湮'))
                            where reason != '����' )
select ����, ��������, sum(�̿��ڼ�) �հ�
       , rank() over (order by sum(�̿��ڼ�) desc) ����
    from er_reason_eng
    group by ����, ��������;
    
    
    
with er_reason_kr as ( select �Ⱓ, ����, ���� r1, ������ r2, �߶� r3, �̲����� r4, �ε��� r5, ������ r6,
                              ��� r7, ȭ�� r8, �ͼ� r9, �ߵ� r10, ���� r11, ��Ÿ r12, ����ܹ湮 r13
                            from er_reason
                            where ���ɺ� = '�հ�'
                                and ���� = '����' ),
     er_reason_eng as ( select �Ⱓ "����", ����, reason "��������", round(to_number(cnt), 1) "�̿��ڼ�"
                            from er_reason_kr
                            unpivot (cnt for reason in (r1 as '����', r2 as '������', r3 as '�߶�', r4 as '�̲�����', 
                                                        r5 as '�ε���', r6 as '������', r7 as '���', r8 as 'ȭ��', 
                                                        r9 as '�ͼ�', r10 as '�ߵ�', r11 as '����', r12 as '��Ÿ', 
                                                        r13 as '����ܹ湮'))
                            where reason != '����' )
select ����, ��������, sum(�̿��ڼ�) �հ�
       , rank() over (order by sum(�̿��ڼ�) desc) ����
    from er_reason_eng
    group by ����, ��������;
 
    

-- ���ɺ� ������� ���� ���� �� ����
update er_reason
    set ���ɺ� = '01 - 09��'
    where ���ɺ� = '1 - 9��';  
    
update er_reason
    set ���ɺ� = '00 - 01��'
    where ���ɺ� = '1���̸�';  
    
commit;


-- �� ���ɺ� ���� ���� 1���� ���
-- �߶��� �ε������� �����񸲿��� �̲����� (����ܹ湮�� ġ�� ������ �ƴϱ� ������ ����)
with er_reason_kr as ( select �Ⱓ, ���ɺ�, ���� r1, ������ r2, �߶� r3, �̲����� r4, �ε��� r5, ������ r6,
                              ��� r7, ȭ�� r8, �ͼ� r9, �ߵ� r10, ���� r11, ��Ÿ r12, ����ܹ湮 r13
                            from er_reason
                            where ���ɺ� not in ('�հ�', '���ɹ̻�')
                                and ���� = '��' ),
     er_reason_eng as ( select �Ⱓ, ���ɺ�, reason, cnt
                            from er_reason_kr
                            unpivot (cnt for reason in (r1 as '����', r2 as '������', r3 as '�߶�', r4 as '�̲�����', 
                                                        r5 as '�ε���', r6 as '������', r7 as '���', r8 as 'ȭ��', 
                                                        r9 as '�ͼ�', r10 as '�ߵ�', r11 as '����', r12 as '��Ÿ', 
                                                        r13 as '����ܹ湮'))
                            where reason not in ('����', '����ܹ湮') ),
     er_reason_rank as ( select ���ɺ�, reason ��������, sum(cnt) �հ�
                                , rank() over ( partition by ���ɺ�
                                               order by sum(cnt) desc ) ����
                             from er_reason_eng
                             group by ���ɺ�, reason )
select ���ɺ�, ��������, �հ�
    from er_reason_rank
    where ���� = 1;