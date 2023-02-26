update "Member_dynamic"  md
set latest_poin_category = subquery.latest_poin_category
from(
SELECT
 md.latest_point, md.member_id, 
 CASE 
   WHEN md.latest_point < 10 THEN '<10'
   WHEN md.latest_point >= 10 AND md.latest_point < 20 THEN '[10,20)'
   WHEN md.latest_point >= 20 AND md.latest_point < 30 THEN '[20,30)'
   WHEN md.latest_point >= 30 AND md.latest_point < 40 THEN '[30,40)'
    WHEN md.latest_point >= 40 THEN '>=40'
 END as latest_poin_category
FROM
 "Member_dynamic" md
)as subquery where md.member_id = subquery.member_id



update "Member_static" ms
set gender = dummy.gender,
    born_date = dummy.born_date,
    province = dummy.province,
    city = dummy.city,
    sub_district = dummy.district
from(
 Select ktp_id, member_id ,
 	case
		when CAST(substring(ms.ktp_id, 8, 2) AS INT) > 40 then 'P'
		when CAST(substring(ms.ktp_id, 8, 2) AS INT) < 40 then 'L'
		else ''
	end as gender,
	TO_DATE(concat(
	case 
	  WHEN CAST(substring(ktp_id, 12, 2) AS INT) < 40 THEN CONCAT('20', SUBSTR(ktp_id , 12, 2))
     when CAST(substring(ktp_id, 12, 2) AS INT) > 40 then CONCAT('19', SUBSTR(ktp_id , 12, 2))
     ELSE ''
	end,
	substring(ms.ktp_id, 10,2),
	case 
		when cast(substring(ms.ktp_id, 8,2) as int) > 40 then cast(substring(ms.ktp_id, 8,2) as int) - 40
		else cast(substring(ms.ktp_id, 8,2) as int)
	end
	),'YYYYMMDD') as born_date ,
	substring(ms.ktp_id, 3,2) as province,
	substring(ms.ktp_id, 3, 4) as city,
	substring(ms.ktp_id, 3,6) as district,
	case 
		when ms.ktp_id is null then 'Tidak Valid'
		else 'Valid'
	end as ktp_status
FROM 
 "Member_static" ms
) as dummy where ms.member_id = dummy.member_id
    



 SELECT DATE_PART('days', current_date::date)

update "Member_dynamic" md 
set tenure_days  = subquery.tenure_days,
    tenure_weeks  = subquery.tenure_weeks,
    tenure_months  = subquery.tenure_months
from (
 select md.member_id,
 current_date - ms.register_date as tenure_days,
 (current_date - ms.register_date) / 7 as tenure_weeks,
 (current_date - ms.register_date) / 30 as tenure_months
 from
 "Member_static" ms
 inner join "Member_dynamic" md on md.member_id = ms.member_id
) as subquery where md.member_id = subquery.member_id
 
 
select current_date - 1/20/2022
from "Member_static" ms 
inner join "Member_dynamic" md on md.member_id = ms.member_id
 




update "Member_dynamic" md 
set age = subquery.age
from (
select md.member_id,
case 
	when (current_date  - born_date) / 365  > 120 then null
	else (current_date  - born_date) / 365  
end as age
from "Member_static" ms
inner join "Member_dynamic" md on md.member_id = ms.member_id 
) as subquery where md.member_id = subquery.member_id


update "Member_dynamic" md 
set card_status  = subquery.card_status
from(
select md.member_id,
case 
	when md.exp_card  is null then 'Non Aktif'
	else 'Aktif'
end as card_status 
from "Member_dynamic" md 
)as subquery where md.member_id = subquery.member_id



update  "Member_static" ms 
set first_trans = subquery.first_trans
from (
select ms.member_id,
min(ts.trx_datetime) as first_trans 
from "Member_static" ms 
inner join "Transaction_sku" ts on ms.member_id = ts.member_id 
group by ms.member_id 
)as subquery where ms.member_id = subquery.member_id

update "Member_dynamic" md 
set "total_qty_P3M" = subquery.total_qty_p3m
from (
select md.member_id,
sum(ts.qty) as total_qty_p3m
from "Transaction_sku" ts 
inner join "Member_dynamic" md on ts.member_id = md.member_id 
group by md.member_id 
)as subquery where  md.member_id = subquery.member_id


update transaction_receipt tr
set trx_datetime = subquery.trx_datetime,
   monetary_receipt = subquery.monetary_receipt,
   n_DEP = subquery.n_dep,
   n_SKU = subquery.n_SKU,
   trx_time = subquery.trx_time,
   trx_date = subquery.trx_date,
   total_amount = subquery.total_amount,
   money_changes = subquery.money_changes,
   redeem_poin = subquery.redeem_poin,
   earn_poin = subquery.earn_poin,
   redeem_rp = subquery.redeem_rp,
   earn_rp = subquery.earn_rp,
   redeem_rp_category = subquery.redeem_rp_category,
   redeem_poin_category = subquery.redeem_poin_category,
   money_changes_category = subquery.money_changes_category,
   status = subquery.status
from (
select ts.trx_datetime as trx_datetime, sum((ts.total_promo_price)-voucher_rp) as monetary_receipt, count(ts.trx_datetime) as n_DEP,
count(ts.trx_datetime) as n_SKU, date(tr.trx_datetime) as trx_date, "time"(tr.trx_datetime) as trx_time, 100 as total_amount, 
75 as money_changes, tr.redeem_poin as redeem_poin, tr.earn_poin as earn_poin, tr.redeem_poin * 500 as redeem_rp,
tr.earn_poin * 500 as earn_rp, tr.voucher_rp, tr.member_id ,
case 
	when (redeem_poin * 500) < 5000 then 'Under 5000'
	when (redeem_poin * 500) >= 5000 and (redeem_poin * 500) < 10000 then '5000-10000'
	when (redeem_poin * 500) > 10000 and (redeem_poin * 500) <= 15000 then '10000-15000'
	when (redeem_poin * 500) > 15000 and (redeem_poin * 500) <= 20000 then '15000-20000'
	when (redeem_poin * 500) > 20000 and (redeem_poin * 500) > 20000 then '20000 Lebih'
end as redeem_rp_category,
case 
	when redeem_poin < 10 then 'Under < 10'
	when redeem_poin >= 10 and redeem_poin < 20 then '10-20'
	when redeem_poin > 20 and redeem_poin <= 30 then '20-30'
	when redeem_poin > 30 and redeem_poin  <= 40 then '30-40'
	when redeem_poin > 40 then '> 40'
end as redeem_poin_category,
case
	when 0 = 0 then 'Uang Pas'
	else 'Kembali'
end as money_changes_category,
case 
	when tr.member_id in ('001','002','ajs', '000223', '085387000', '22') then 'No Member'
	else 'Member'
end as status
from transaction_receipt tr left join transaction_sku ts on tr.trx_datetime = ts.trx_datetime 
group by tr.trx_datetime, ts.trx_datetime, tr.redeem_poin, tr.earn_poin, tr.total_amount, tr.member_id, ts.total_promo_price, tr.voucher_rp
) as subquery where tr.member_id = subquery.member_id


update transaction_receipt tr
set dep = subquery.deps,
   sku = subquery.skus
   trx_time = subquery.trx_time
FROM(
select tr.trx_datetime, tr.sku, tr.dep , tr.trx_time,
count(ts.trx_datetime) as deps,
count(ts.trx_datetime) as skus,
"time"(tr.trx_datetime) as trx_times
from transaction_receipt tr inner join transaction_sku ts  on tr.trx_datetime = ts.trx_datetime
group by tr.trx_datetime, tr.member_id , tr.sku , tr.dep , tr.trx_time 
)as subquery where tr.trx_datetime  = subquery.trx_datetime

update transaction_sku ts
set disc = subquery.disc,
   promo_price = subquery.promo_price,
   total_selling_price = subquery.total_selling_price
from(
select member_id, selling_price, disc/100 as disc, 
   ((1-(disc/100))*selling_price) as promo_price, qty, selling_price*qty as total_selling_price, ((1-(disc/100))*selling_price)*qty as total_promo_price 
   from Transaction_SKU ts where promo_price is null or total_promo_price is null or total_selling_price is null
) as subquery where ts.member_id = subquery.member_id

update "Member_dynamic" md 
set redeem_poin = subquery.redeem_poin
from(
select md.member_id,
sum(tr.redeem_poin) as redeem_poin
from "Member_dynamic" md inner join transaction_receipt tr on md.member_id = tr.member_id 
group by md.member_id 
) as subquery where md.member_id = subquery.member_id


update "Member_dynamic" md 
set last_trans = subquery.last_trans
from (
select md.member_id,
max(tr.trx_date) as last_trans
from "Member_dynamic" md inner join transaction_receipt tr on md.member_id = tr.member_id
group by md.member_id 
)as subquery where md.member_id = subquery.member_id


update "Member_dynamic" md 
set "frequency_P3M"
= subquery.frequency_P3M
from (
select md.member_id,
count(tr.trx_no)  as frequency_P3M
from "Member_dynamic" md inner join transaction_receipt tr on md.member_id = tr.member_id
group by md.member_id
)as subquery where md.member_id = subquery.member_id



update "Member_dynamic" md 
set "total_monetary_P3M"  = subquery.total_monetary_P3M
from (
select md.member_id,
count(tr.monetary_receipt)  as total_monetary_P3M
from "Member_dynamic" md inner join transaction_receipt tr on md.member_id = tr.member_id
group by md.member_id
)as subquery where md.member_id = subquery.member_id


update "Member_dynamic" md 
set monthly_frequency = subquery.monthly_frequency
from(
select member_id,
"frequency_P3M" / tenure_months as monthly_frequency 
from "Member_dynamic" md 
)as subquery where md.member_id = subquery.member_id

update "Member_dynamic" md 
set monthly_monetary = subquery.monthly_monetary
from(
select member_id,
"total_monetary_P3M"  / tenure_months as monthly_monetary
from "Member_dynamic" md 
)as subquery where md.member_id = subquery.member_id

update "Member_dynamic" md 
set monthly_qty  = subquery.monthly_qty
from(
select member_id,
"total_qty_P3M"  / tenure_months as monthly_qty
from "Member_dynamic" md 
)as subquery where md.member_id = subquery.member_id

