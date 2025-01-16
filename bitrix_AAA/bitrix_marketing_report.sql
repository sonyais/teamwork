select distinct 
*
from (
select 
distinct
-- activity.external_id as activity_id,
case 
when department_responsible.name in ('Внедрение Синтека МСК', 'Внедрение Синтека СПб', 'Внедрение Синтека', 'Группа Внедрения ФК МСК', 'Группа Внедрения ФК СПб') then coalesce(prices_without_duplicates.pay_voucher_date, prices_without_duplicates_all.pay_voucher_date)
else to_char(activity.created, 'YYYY-MM-DD')
end as meeting_plan_date,
case 
when department_responsible.name in ('Внедрение Синтека МСК', 'Внедрение Синтека СПб', 'Внедрение Синтека', 'Группа Внедрения ФК МСК', 'Группа Внедрения ФК СПб') then coalesce(to_char(prices_without_duplicates.pay_voucher_date::date, 'MM'), to_char(prices_without_duplicates_all.pay_voucher_date::date, 'MM'))
else to_char(activity.created, 'MM')
end as meeting_plan_month,
case 
when department_responsible.name in ('Внедрение Синтека МСК', 'Внедрение Синтека СПб', 'Внедрение Синтека', 'Группа Внедрения ФК МСК', 'Группа Внедрения ФК СПб') then to_char(coalesce(prices_without_duplicates.pay_voucher_date, prices_without_duplicates_all.pay_voucher_date)::date, 'YYYY')
else to_char(activity.created, 'YYYY')
end as meeting_plan_year,
case 
when department_responsible.name in ('Внедрение Синтека МСК', 'Внедрение Синтека СПб', 'Внедрение Синтека', 'Группа Внедрения ФК МСК', 'Группа Внедрения ФК СПб') then null
when invoice_with_money_with_incorrect_deal.invoice_external_id is not null then invoice_with_money_with_incorrect_deal.last_name
else activiry_creator.last_name
end as meeting_creator,
user_assigned.last_name as assigned_person,
deal.title as deal_title,
deal.external_id as deal_external_id,
concat('https://treesolution.bitrix24.ru/crm/deal/details/', deal.external_id, '/') as url,
case 
when activiry_creator.last_name is not null then 
    case 
    when department_responsible.name in ('Внедрение Синтека МСК', 'Внедрение Синтека СПб', 'Внедрение Синтека', 'Группа Внедрения ФК МСК', 'Группа Внедрения ФК СПб') then null
    else case 
        when lower(activity.location) in ('онлайн', 'звонок') then 'Онлайн'
        else 'Встреча'
    end end
else null
end as location,
case 
when TRIM(split_part(dealcategory.name, '-', 1)) = 'Поставщик' then 'Закупай'
else TRIM(split_part(dealcategory.name, '-', 1))
end as product,
case 
when department_responsible.name in ('Внедрение Синтека МСК', 'Внедрение Синтека СПб', 'Внедрение Синтека', 'Группа Внедрения ФК МСК', 'Группа Внедрения ФК СПб') then null
else to_char(activity.deadline, 'YYYY-MM-DD')
end as meeting_fact_date,
case 
when department_responsible.name in ('Внедрение Синтека МСК', 'Внедрение Синтека СПб', 'Внедрение Синтека', 'Группа Внедрения ФК МСК', 'Группа Внедрения ФК СПб') then null
else (activity.deadline + interval '3 HOUR')
end as meeting_fact_datetime,
dealcategory_stage.name as dealcategory_stage_name,
(case 
when department_responsible.name in ('Внедрение Синтека МСК', 'Внедрение Синтека СПб', 'Внедрение Синтека', 'Группа Внедрения ФК МСК', 'Группа Внедрения ФК СПб') then null
else case when (select 
dealcategory_stage.name
from deal_stagehistory
left join dealcategory_stage on dealcategory_stage.status_id::text = deal_stagehistory.stage_id::text and dealcategory_stage.category_id::bigint = deal_stagehistory.category_id::bigint
left join public.status on dealcategory_stage.status_id = status.status_id
where deal_stagehistory.owner_id = deal.external_id and deal_stagehistory.created_time + interval '3 hour' - INTERVAL '2 MINUTE' > (activity.start_time + interval '3 HOUR')
order by created_time ASC
limit 1
) is not null then (select 
dealcategory_stage.name
from deal_stagehistory
left join dealcategory_stage on dealcategory_stage.status_id::text = deal_stagehistory.stage_id::text and dealcategory_stage.category_id::bigint = deal_stagehistory.category_id::bigint
left join public.status on dealcategory_stage.status_id = status.status_id
where deal_stagehistory.owner_id = deal.external_id and deal_stagehistory.created_time + interval '3 hour' - INTERVAL '2 MINUTE' > (activity.start_time + interval '3 HOUR')
order by created_time ASC
limit 1
)
else (select 
dealcategory_stage.name
from deal_stagehistory
left join dealcategory_stage on dealcategory_stage.status_id::text = deal_stagehistory.stage_id::text and dealcategory_stage.category_id::bigint = deal_stagehistory.category_id::bigint
left join public.status on dealcategory_stage.status_id = status.status_id
where deal_stagehistory.owner_id = deal.external_id and deal_stagehistory.created_time + interval '3 hour' - INTERVAL '2 MINUTE' > (activity.created + interval '4 HOUR')
order by created_time ASC
limit 1
) end
end) as dealcategory_stage_name_history,
dealcategory_stage.external_id as dealcategory_stage_external_id,
case
when status.name is null then 'Прочее'
else status.name
end as deal_type,
case
when status.name like '%Рекомендация%' then null
else
case 
when department_responsible.name in ('Внедрение Синтека МСК', 'Внедрение Синтека СПб', 'Внедрение Синтека', 'Группа Внедрения ФК МСК', 'Группа Внедрения ФК СПб') then null
when activity.deadline + interval '3 HOUR' > now() then 'Запланирована'
when activity.deleted = true then 'Удалена'
else coalesce((select case when status = true then 'Состоялась' else 'Не состоялась' end as status from activity_status where activity.external_id = activity_status.external_id),(select 
case
   when (activity.deadline + interval '3 HOUR') > now() then 'Запланирована'
   else case
        when activity.completed = 'N' then 'Требует внимания'
       when activity.deleted = true then 'Удалена'
       when dealcategory.external_id in (0, 14, 21, 27, 43) and dealcategory_stage.external_id in (143155765, 166643006, 508971364, 266188974, 183164335, 390627843, 421765209, 376240355, 347625181, 867028305, 353444384, 296119337, 406142322, 175445540, 103326737, 391101203, 310474062, 296119337, 143155765, 152010674, 150482595, 372689215, 362829961, 399900605, 305732812, 264087650, 536239320, 239586655, 399747706, 189303590, 900168313, 310199051, 393700248, 714707281, 211091281, 197074812, 376806040, 336100805, 166643006, 413166457, 175445540) then 'Не состоялась'
       when dealcategory.external_id in (21, 43) and dealcategory_stage.external_id in (287975271, 265814213, 606586632, 754111997, 409989064, 111670877, 215951352, 302942547, 362396047, 186299416, 193439272, 416311385, 336565364, 428450726, 275716818, 301404773, 171942459, 117252070, 221675922, 397435915, 371764294, 382291224, 176891461) then 'Состоялась'
       else 'Состоялась'
   end
end
from deal_stagehistory
left join dealcategory_stage on dealcategory_stage.status_id::text = deal_stagehistory.stage_id::text and dealcategory_stage.category_id::bigint = deal_stagehistory.category_id::bigint
where deal_stagehistory.owner_id = deal.external_id and deal_stagehistory.created_time + interval '3 HOUR' - INTERVAL '2 MINUTE' > (activity.start_time + interval '3 HOUR')
order by created_time asc
limit 1
),(select 
case
   when (activity.deadline + interval '3 HOUR') > now() then 'Запланирована'
   else case
        when activity.completed = 'N' then 'Требует внимания'
       when activity.deleted = true then 'Удалена'
       when dealcategory.external_id in (0, 14, 21, 27, 43) and dealcategory_stage.external_id in (143155765, 166643006, 508971364, 266188974, 183164335, 390627843, 421765209, 376240355, 347625181, 867028305, 353444384, 296119337, 406142322, 175445540, 103326737, 391101203, 310474062, 296119337, 143155765, 152010674, 150482595, 372689215, 362829961, 399900605, 305732812, 264087650, 536239320, 239586655, 399747706, 189303590, 900168313, 310199051, 393700248, 714707281, 211091281, 197074812, 376806040, 336100805, 166643006, 413166457, 175445540) then 'Не состоялась'
       when dealcategory.external_id in (21, 43) and dealcategory_stage.external_id in (287975271, 265814213, 606586632, 754111997, 409989064, 111670877, 215951352, 302942547, 362396047, 186299416, 193439272, 416311385, 336565364, 428450726, 275716818, 301404773, 171942459, 117252070, 221675922, 397435915, 371764294, 382291224, 176891461) then 'Состоялась'
       else 'Состоялась'
   end
end
from deal_stagehistory
left join dealcategory_stage on dealcategory_stage.status_id::text = deal_stagehistory.stage_id::text and dealcategory_stage.category_id::bigint = deal_stagehistory.category_id::bigint
where deal_stagehistory.owner_id = deal.external_id and deal_stagehistory.created_time + interval '3 HOUR' - INTERVAL '2 MINUTE' > (activity.created + interval '3 HOUR')
order by created_time asc
limit 1
), case when activity.completed = 'Y' and dealcategory.external_id in (0, 14, 21, 27, 43) and dealcategory_stage.external_id in (143155765, 166643006, 508971364, 266188974, 183164335, 390627843, 421765209, 376240355, 347625181, 867028305, 353444384, 296119337, 406142322, 175445540, 103326737, 391101203, 310474062, 296119337, 143155765, 152010674, 150482595, 372689215, 362829961, 399900605, 305732812, 264087650, 536239320, 239586655, 399747706, 189303590, 900168313, 310199051, 393700248, 714707281, 211091281, 197074812, 376806040, 336100805, 166643006, 413166457, 175445540) then 'Не состоялась'
when activity.completed = 'Y' and dealcategory_stage.external_id not in (316220655, 355798727, 263361884, 353150184, 166593526, 223859750) then 'Состоялась'
else 'Требует внимания' end) END end as deal_history,
deal.opportunity as deal_opportunity,
coalesce(prices_without_duplicates.price, prices_without_duplicates_all.price) as price,
coalesce(prices_without_duplicates.invoice_external_id, prices_without_duplicates_all.invoice_external_id) as invoice_external_id,
coalesce(prices_without_duplicates.pay_voucher_date, prices_without_duplicates_all.pay_voucher_date) as pay_voucher_date,
case
when department.name in ('Внедрение Синтека МСК', 'Внедрение Синтека СПб', 'Внедрение Синтека', 'Группа Внедрения ФК МСК', 'Группа Внедрения ФК СПб') then NULL
when invoice_with_money_with_incorrect_deal.invoice_external_id is not null then invoice_with_money_with_incorrect_deal.departament_name
else department.name
end as department_name,
case
when status.name like '%Рекомендация%' and TRIM(split_part(dealcategory.name, '-', 1)) = 'Синтека' then 'Продажи Синтека СПб'
when status.name like '%Рекомендация%' and TRIM(split_part(dealcategory.name, '-', 1)) = 'FaceKIT' then 'Продажи FaceKIT/Face'
when status.name like '%Рекомендация%' and TRIM(split_part(dealcategory.name, '-', 1)) = 'FACE' then 'Продажи FaceKIT/Face'
when status.name like '%Рекомендация%' and TRIM(split_part(dealcategory.name, '-', 1)) = 'MySnab' then 'Продажи Закупай/mySnab'
else department_responsible.name 
end AS department_responsible_name,
case 
when deal.utm_campaign = 'Неизвестно' then null
else deal.utm_campaign
end as deal_utm_campaign,
coalesce(deal.uf_crm_1556694126, lead.uf_crm_1556694091) as roistat_id,
CASE 
    WHEN strpos(activity.description, 'Регион: ') > 0 THEN
      substring(
        activity.description 
        FROM strpos(activity.description, 'Регион: ') + length('Регион: ') 
        FOR COALESCE(
          NULLIF(strpos(substring(activity.description FROM strpos(activity.description, 'Регион: ') + length('Регион: ')), E'\n'), 0),
          NULLIF(strpos(substring(activity.description FROM strpos(activity.description, 'Регион: ') + length('Регион: ')), E'\r\n'), 0),
          NULLIF(strpos(substring(activity.description FROM strpos(activity.description, 'Регион: ') + length('Регион: ')), E'\r'), 0),
          15
        ) - 1
      )
    ELSE 
      NULL
  END as extracted_region,
  CASE 
    WHEN strpos(activity.description, 'Контактное лицо+должность: ') > 0 THEN
      substring(
        activity.description 
        FROM strpos(activity.description, 'Контактное лицо+должность: ') + length('Контактное лицо+должность: ') 
        FOR COALESCE(
          NULLIF(strpos(substring(activity.description FROM strpos(activity.description, 'Контактное лицо+должность: ') + length('Контактное лицо+должность: ')), E'\n'), 0),
          NULLIF(strpos(substring(activity.description FROM strpos(activity.description, 'Контактное лицо+должность: ') + length('Контактное лицо+должность: ')), E'\r\n'), 0),
          NULLIF(strpos(substring(activity.description FROM strpos(activity.description, 'Контактное лицо+должность: ') + length('Контактное лицо+должность: ')), E'\r'), 0),
          50
        ) - 1
      )
    ELSE 
      NULL
  END as extracted_job_title,
to_char(lead.date_create, 'YYYY-MM-DD') as lead_date_create,
to_char(coalesce(prices_without_duplicates.pay_voucher_date, prices_without_duplicates_all.pay_voucher_date)::date, 'YYYY') as pay_voucher_year,
to_char(coalesce(prices_without_duplicates.pay_voucher_date, prices_without_duplicates_all.pay_voucher_date)::date, 'MM') as pay_voucher_month,
company.comments as company_comments,
deal.date_create as deal_date_create,
coalesce(prices_without_duplicates.invoice_status_name, prices_without_duplicates_all.invoice_status_name) as invoice_status_name,
case
when status.name like '%Рекомендация%' then null
else
case 
when department_responsible.name in ('Внедрение Синтека МСК', 'Внедрение Синтека СПб', 'Внедрение Синтека', 'Группа Внедрения ФК МСК', 'Группа Внедрения ФК СПб') then null
when activity.deadline + interval '3 HOUR' > now() then 0
when activity.deleted = true then 4
else coalesce((select case when status = true then 1 else 2 end as status from activity_status where activity.external_id = activity_status.external_id),(select 
-- external_id
case
   when (activity.deadline + interval '3 HOUR') > now() then 0 --'Запланирована'
   else case
       when activity.completed = 'N' then 3
       when activity.deleted = true then 4 --'Удалена'
       when dealcategory.external_id in (0, 14, 21, 27, 43) and dealcategory_stage.external_id in (143155765, 166643006, 508971364, 266188974, 183164335, 390627843, 421765209, 376240355, 347625181, 867028305, 353444384, 296119337, 406142322, 175445540, 103326737, 391101203, 310474062, 296119337, 143155765, 152010674, 150482595, 372689215, 362829961, 399900605, 305732812, 264087650, 536239320, 239586655, 399747706, 189303590, 900168313, 310199051, 393700248, 714707281, 211091281, 197074812, 376806040, 336100805, 166643006, 413166457, 175445540, 103326737, 406142322) then 2 --'Не состоялась'
       when dealcategory.external_id in (21, 43) and dealcategory_stage.external_id in (287975271, 265814213, 606586632, 754111997, 409989064, 111670877, 215951352, 302942547, 362396047, 186299416, 193439272, 416311385, 336565364, 428450726, 275716818, 301404773, 171942459, 117252070, 221675922, 397435915, 371764294, 382291224, 176891461) then 1
       else 1 --'Состоялась'
   end
end
from deal_stagehistory
left join dealcategory_stage on dealcategory_stage.status_id::text = deal_stagehistory.stage_id::text and dealcategory_stage.category_id::bigint = deal_stagehistory.category_id::bigint
where deal_stagehistory.owner_id = deal.external_id and deal_stagehistory.created_time + interval '3 HOUR' - INTERVAL '2 MINUTE' > (activity.start_time + interval '3 HOUR')
order by created_time asc
limit 1
),(select 
-- external_id
case
   when (activity.deadline + interval '3 HOUR') > now() then 0 --'Запланирована'
   else case
       when activity.completed = 'N' then 3
       when activity.deleted = true then 4 --'Удалена'
       when dealcategory.external_id in (0, 14, 21, 27, 43) and dealcategory_stage.external_id in (143155765, 166643006, 508971364, 266188974, 183164335, 390627843, 421765209, 376240355, 347625181, 867028305, 353444384, 296119337, 406142322, 175445540, 103326737, 391101203, 310474062, 296119337, 143155765, 152010674, 150482595, 372689215, 362829961, 399900605, 305732812, 264087650, 536239320, 239586655, 399747706, 189303590, 900168313, 310199051, 393700248, 714707281, 211091281, 197074812, 376806040, 336100805, 166643006, 413166457, 175445540, 103326737, 406142322) then 2 --'Не состоялась'
       when dealcategory.external_id in (21, 43) and dealcategory_stage.external_id in (287975271, 265814213, 606586632, 754111997, 409989064, 111670877, 215951352, 302942547, 362396047, 186299416, 193439272, 416311385, 336565364, 428450726, 275716818, 301404773, 171942459, 117252070, 221675922, 397435915, 371764294, 382291224, 176891461) then 1
       else 1 --'Состоялась'
   end
end
from deal_stagehistory
left join dealcategory_stage on dealcategory_stage.status_id::text = deal_stagehistory.stage_id::text and dealcategory_stage.category_id::bigint = deal_stagehistory.category_id::bigint
where deal_stagehistory.owner_id = deal.external_id and deal_stagehistory.created_time + interval '3 HOUR' - INTERVAL '2 MINUTE' > (activity.created + interval '3 HOUR')
order by created_time asc
limit 1
),  case when activity.completed = 'Y' and dealcategory.external_id in (0, 14, 21, 27, 43) and dealcategory_stage.external_id in (143155765, 166643006, 508971364, 266188974, 183164335, 390627843, 421765209, 376240355, 347625181, 867028305, 353444384, 296119337, 406142322, 175445540, 103326737, 391101203, 310474062, 296119337, 143155765, 152010674, 150482595, 372689215, 362829961, 399900605, 305732812, 264087650, 536239320, 239586655, 399747706, 189303590, 900168313, 310199051, 393700248, 714707281, 211091281, 197074812, 376806040, 336100805, 166643006, 413166457, 175445540) then 2
when activity.completed = 'Y' and dealcategory_stage.external_id not in (316220655, 355798727, 263361884, 353150184, 166593526, 223859750) then 1
else 3 end  --требует внимания
) end end as deal_history_bool,
case
when coalesce(prices_without_duplicates.pay_voucher_date, prices_without_duplicates_all.pay_voucher_date) is null then 0
else 1 
end as pay_voucher_bool,
dealcategory.name as funnel
from public.deal
left join public."user" on case when deal.uf_crm_1522603723 = '' then NULL else deal.uf_crm_1522603723::bigint end = "user".external_id
left join public.dealcategory on deal.category_id::bigint = dealcategory.external_id
left join public.activity on deal.external_id = activity.owner_id and activity.provider_type_id = 'MEETING' and activity.owner_type_id::numeric = 2
left join public."user" as activiry_creator on activity.author_id::bigint = activiry_creator.external_id
left join public.dealcategory_stage on deal.stage_id = dealcategory_stage.status_id
left join public."user" as user_assigned on activity.responsible_id::bigint = user_assigned.external_id
left join public.status on deal.type_id = status.status_id and status.entity_id = 'DEAL_TYPE'
left join public.deal_stagehistory on deal.external_id::bigint = deal_stagehistory.owner_id
left join public.invoice on deal.external_id = invoice.uf_deal_id and invoice.responsible_id = user_assigned.external_id 
left join (
select * from
(select distinct
"user".external_id as external_id,
"user".last_name as last_name,
case 
when "user".last_name = 'Горелова' then 'Внедрение Синтека СПб'
when "user".last_name = 'Зюков' then 'Продажи Синтека СПб'
when "user".last_name = 'Алаторцев' then 'Группа Внедрения ФК СПб'
when department.name = 'Онлайн Внедрение FaceKIT' then 'Группа Внедрения ФК СПб'
when department.name = 'Внедрение Синтека МСК' then 'Внедрение Синтека МСК'
when department.name in ('Группа Внедрения МСК 1', 'Группа Внедрения МСК 2', 'Группа Внедрения МСК 3', 'Группа Внедрения МСК 4') then 'Группа Внедрения ФК МСК'
when department.name in ('Внедрения Синтека СПб 1', 'Внедрения Синтека СПб 2', 'Внедрения Синтека СПб 3', 'Внедрения Синтека СПб 4') then 'Внедрение Синтека СПб'
when department.name in ('Группа Внедрения СПб 1', 'Группа Внедрения СПб 2', 'Группа Внедрения СПб 3', 'Группа Внедрения СПб 4') then 'Группа Внедрения ФК СПб'
else case 
when department_root_2.name is NOT null then department_root_2.name
else case 
when department_root.name is NOT null then department_root.name
else department.name
end
end
end as name
from "user"
left join user_multiple_relations on "user".external_id = user_multiple_relations.parent_id
left join public.department on user_multiple_relations.value::bigint = department.external_id
left join public.department as department_root on department.parent::integer = department_root.external_id and department_root.external_id != 1
left join public.department as department_root_2 on department_root_2.external_id = department_root.parent::integer and department_root_2.external_id != 1) as departmant_person
where departmant_person.name is not null
) as department on activiry_creator.external_id = department.external_id
left join (
select * from
(select distinct
"user".external_id as external_id,
"user".last_name as last_name,
case 
when "user".last_name = 'Горелова' then 'Внедрение Синтека СПб'
when "user".last_name = 'Зюков' then 'Продажи Синтека СПб'
when "user".last_name = 'Алаторцев' then 'Группа Внедрения ФК СПб'
when department.name = 'Онлайн Внедрение FaceKIT' then 'Группа Внедрения ФК СПб'
when department.name = 'Внедрение Синтека МСК' then 'Внедрение Синтека МСК'
when department.name in ('Группа Внедрения МСК 1', 'Группа Внедрения МСК 2', 'Группа Внедрения МСК 3', 'Группа Внедрения МСК 4') then 'Группа Внедрения ФК МСК'
when department.name in ('Внедрения Синтека СПб 1', 'Внедрения Синтека СПб 2', 'Внедрения Синтека СПб 3', 'Внедрения Синтека СПб 4') then 'Внедрение Синтека СПб'
when department.name in ('Группа Внедрения СПб 1', 'Группа Внедрения СПб 2', 'Группа Внедрения СПб 3', 'Группа Внедрения СПб 4') then 'Группа Внедрения ФК СПб'
else case 
when department_root_2.name is NOT null then department_root_2.name
else case 
when department_root.name is NOT null then department_root.name
else department.name
end
end
end as name
from "user"
left join user_multiple_relations on "user".external_id = user_multiple_relations.parent_id
left join public.department on user_multiple_relations.value::bigint = department.external_id
left join public.department as department_root on department.parent::integer = department_root.external_id and department_root.external_id != 1
left join public.department as department_root_2 on department_root_2.external_id = department_root.parent::integer and department_root_2.external_id != 1) as departmant_person
where departmant_person.name is not null
) as department_responsible on activity.responsible_id::bigint = department_responsible.external_id
left join (
select 
t0.invoice_external_id,
t0.activity_external_id,
t0.price as price,
t0.deal_external_id,
t0.pay_voucher_date,
t0.invoice_status_name
from (select
invoice.external_id as invoice_external_id,
max(activity.external_id) as activity_external_id,
((json_array_elements((invoice.uf_crm_1707306084::json ->> 'payments')::json)::json) ->> 'amount') as price,
deal.external_id as deal_external_id,
((json_array_elements((invoice.uf_crm_1707306084::json ->> 'payments')::json)::json) ->> 'date') as pay_voucher_date,
status.name as invoice_status_name
from public.deal
left join public.activity on deal.external_id = activity.owner_id and activity.provider_type_id = 'MEETING' and activity.owner_type_id::numeric = 2
left join public."user" as user_assigned on activity.responsible_id::bigint = user_assigned.external_id
left join public.invoice on deal.external_id = invoice.uf_deal_id 
left join public."user" as activiry_creator on activity.author_id::bigint = activiry_creator.external_id
left join public.user_multiple_relations on activiry_creator.external_id = user_multiple_relations.parent_id
left join (
select * from
(select distinct
"user".external_id as external_id,
"user".last_name as last_name,
case 
when "user".last_name = 'Горелова' then 'Внедрение Синтека СПб'
when "user".last_name = 'Зюков' then 'Продажи Синтека СПб'
when "user".last_name = 'Алаторцев' then 'Группа Внедрения ФК СПб'
when department.name = 'Онлайн Внедрение FaceKIT' then 'Группа Внедрения ФК СПб'
when department.name = 'Внедрение Синтека МСК' then 'Внедрение Синтека МСК'
when department.name in ('Группа Внедрения МСК 1', 'Группа Внедрения МСК 2', 'Группа Внедрения МСК 3', 'Группа Внедрения МСК 4') then 'Группа Внедрения ФК МСК'
when department.name in ('Внедрения Синтека СПб 1', 'Внедрения Синтека СПб 2', 'Внедрения Синтека СПб 3', 'Внедрения Синтека СПб 4') then 'Внедрение Синтека СПб'
when department.name in ('Группа Внедрения СПб 1', 'Группа Внедрения СПб 2', 'Группа Внедрения СПб 3', 'Группа Внедрения СПб 4') then 'Группа Внедрения ФК СПб'
else case 
when department_root_2.name is NOT null then department_root_2.name
else case 
when department_root.name is NOT null then department_root.name
else department.name
end
end
end as name
from "user"
left join user_multiple_relations on "user".external_id = user_multiple_relations.parent_id
left join public.department on user_multiple_relations.value::bigint = department.external_id
left join public.department as department_root on department.parent::integer = department_root.external_id and department_root.external_id != 1
left join public.department as department_root_2 on department_root_2.external_id = department_root.parent::integer and department_root_2.external_id != 1) as departmant_person
where departmant_person.name is not null
) as department on activiry_creator.external_id = department.external_id
left join status on invoice.status_id = status.status_id and status.entity_id = 'INVOICE_STATUS'
where 
status.name in ('Оплачен', 'Частично оплачен', 'Отклонён')
and activity.deleted is not true
and department.name in ('Телемаркетинг', 'Маркетинг')
and invoice.responsible_id = user_assigned.external_id
group by deal.external_id, invoice.external_id, status.name, invoice.uf_crm_1706529993, invoice.date_status, invoice.uf_crm_1707306084
) as t0
where price is not null
) as prices_without_duplicates on activity.external_id = prices_without_duplicates.activity_external_id
left join (
select 
t0.invoice_external_id,
t0.activity_external_id,
t0.price as price,
t0.deal_external_id,
t0.pay_voucher_date,
t0.invoice_status_name
from (
select
invoice.external_id as invoice_external_id,
max(activity.external_id) as activity_external_id,
((json_array_elements((invoice.uf_crm_1707306084::json ->> 'payments')::json)::json) ->> 'amount') as price,
deal.external_id as deal_external_id,
((json_array_elements((invoice.uf_crm_1707306084::json ->> 'payments')::json)::json) ->> 'date') as pay_voucher_date,
status.name as invoice_status_name
from public.deal
left join public.activity on deal.external_id = activity.owner_id and activity.provider_type_id = 'MEETING' and activity.owner_type_id::numeric = 2
left join public."user" as user_assigned on activity.responsible_id::bigint = user_assigned.external_id
left join public.invoice on deal.external_id = invoice.uf_deal_id 
left join public."user" as activiry_creator on activity.author_id::bigint = activiry_creator.external_id
left join public.user_multiple_relations on activiry_creator.external_id = user_multiple_relations.parent_id
left join public.department on user_multiple_relations.value::bigint = department.external_id
left join status on invoice.status_id = status.status_id and status.entity_id = 'INVOICE_STATUS'
where 
status.name in ('Оплачен', 'Частично оплачен', 'Отклонён')
and activity.deleted is not true
and invoice.responsible_id = user_assigned.external_id
and deal.external_id not in (
select 
distinct
t0.deal_external_id
from (
select
max(activity.external_id) as activity_external_id,
((json_array_elements((invoice.uf_crm_1707306084::json ->> 'payments')::json)::json) ->> 'amount') as price,
deal.external_id as deal_external_id,
((json_array_elements((invoice.uf_crm_1707306084::json ->> 'payments')::json)::json) ->> 'date') as pay_voucher_date
from public.deal
left join public.activity on deal.external_id = activity.owner_id and activity.provider_type_id = 'MEETING' and activity.owner_type_id::numeric = 2
left join public."user" as user_assigned on activity.responsible_id::bigint = user_assigned.external_id
left join public.invoice on deal.external_id = invoice.uf_deal_id 
left join public."user" as activiry_creator on activity.author_id::bigint = activiry_creator.external_id
left join public.user_multiple_relations on activiry_creator.external_id = user_multiple_relations.parent_id
left join (
select * from
(select distinct
"user".external_id as external_id,
"user".last_name as last_name,
case 
when "user".last_name = 'Горелова' then 'Внедрение Синтека СПб'
when "user".last_name = 'Зюков' then 'Продажи Синтека СПб'
when "user".last_name = 'Алаторцев' then 'Группа Внедрения ФК СПб'
when department.name = 'Онлайн Внедрение FaceKIT' then 'Группа Внедрения ФК СПб'
when department.name = 'Внедрение Синтека МСК' then 'Внедрение Синтека МСК'
when department.name in ('Группа Внедрения МСК 1', 'Группа Внедрения МСК 2', 'Группа Внедрения МСК 3', 'Группа Внедрения МСК 4') then 'Группа Внедрения ФК МСК'
when department.name in ('Внедрения Синтека СПб 1', 'Внедрения Синтека СПб 2', 'Внедрения Синтека СПб 3', 'Внедрения Синтека СПб 4') then 'Внедрение Синтека СПб'
when department.name in ('Группа Внедрения СПб 1', 'Группа Внедрения СПб 2', 'Группа Внедрения СПб 3', 'Группа Внедрения СПб 4') then 'Группа Внедрения ФК СПб'
else case 
when department_root_2.name is NOT null then department_root_2.name
else case 
when department_root.name is NOT null then department_root.name
else department.name
end
end
end as name
from "user"
left join user_multiple_relations on "user".external_id = user_multiple_relations.parent_id
left join public.department on user_multiple_relations.value::bigint = department.external_id
left join public.department as department_root on department.parent::integer = department_root.external_id and department_root.external_id != 1
left join public.department as department_root_2 on department_root_2.external_id = department_root.parent::integer and department_root_2.external_id != 1) as departmant_person
where departmant_person.name is not null
) as department on activiry_creator.external_id = department.external_id
where 
invoice.pay_voucher_date >= activity.deadline
and department.name in ('Телемаркетинг', 'Маркетинг')
and invoice.responsible_id = user_assigned.external_id 
group by deal.external_id, invoice.pay_voucher_date, invoice.uf_crm_1707306084
) as t0
where price is not null 
group by activity_external_id, deal_external_id, pay_voucher_date
)
group by deal.external_id, invoice.external_id, invoice.pay_voucher_date, invoice.price, status.name, invoice.uf_crm_1706529993, invoice.date_status, invoice.uf_crm_1707306084
) as t0
where price is not null 
) as prices_without_duplicates_all on activity.external_id = prices_without_duplicates_all.activity_external_id
left join company on deal.company_id::integer = company.external_id
left join lead on case when company.lead_id = '' then null else company.lead_id::integer end = lead.external_id

left join (
WITH RankedActivities AS (
    SELECT 
        invoice.external_id as invoice_external_id,
        regexp_replace(
            case when uf_crm_1732516279 like '%deal%' then uf_crm_1732516279 else null end, 
            '^https://treesolution\.bitrix24\.ru/crm/deal/details/(\d+)/.*$', 
            '\1'
        ) AS extracted_deal_external_id,
        activiry_creator.last_name,
        activiry_creator.external_id as activiry_creator_external_id,
        activity.external_id as activity_external_id,
        departament.name as departament_name,
        ROW_NUMBER() OVER (PARTITION BY invoice.external_id ORDER BY activity.external_id DESC) AS rn
    FROM invoice 
    LEFT JOIN public.deal ON regexp_replace(case when uf_crm_1732516279 like '%deal%' then uf_crm_1732516279 else null end, '^https://treesolution\.bitrix24\.ru/crm/deal/details/(\d+)/.*$', '\1')::bigint = deal.external_id
    LEFT JOIN public."user" ON case when deal.uf_crm_1522603723 = '' then NULL else deal.uf_crm_1522603723::bigint end = "user".external_id
    LEFT JOIN public.dealcategory ON deal.category_id::bigint = dealcategory.external_id
    LEFT JOIN public.activity ON deal.external_id = activity.owner_id AND activity.provider_type_id = 'MEETING' AND activity.owner_type_id::numeric = 2
    LEFT JOIN public."user" AS activiry_creator ON activity.author_id::bigint = activiry_creator.external_id
    left join (
    select * from
(select distinct
"user".external_id as external_id,
"user".last_name as last_name,
case 
when "user".last_name = 'Горелова' then 'Внедрение Синтека СПб'
when "user".last_name = 'Зюков' then 'Продажи Синтека СПб'
when "user".last_name = 'Алаторцев' then 'Группа Внедрения ФК СПб'
when department.name = 'Онлайн Внедрение FaceKIT' then 'Группа Внедрения ФК СПб'
when department.name = 'Внедрение Синтека МСК' then 'Внедрение Синтека МСК'
when department.name in ('Группа Внедрения МСК 1', 'Группа Внедрения МСК 2', 'Группа Внедрения МСК 3', 'Группа Внедрения МСК 4') then 'Группа Внедрения ФК МСК'
when department.name in ('Внедрения Синтека СПб 1', 'Внедрения Синтека СПб 2', 'Внедрения Синтека СПб 3', 'Внедрения Синтека СПб 4') then 'Внедрение Синтека СПб'
when department.name in ('Группа Внедрения СПб 1', 'Группа Внедрения СПб 2', 'Группа Внедрения СПб 3', 'Группа Внедрения СПб 4') then 'Группа Внедрения ФК СПб'
else case 
when department_root_2.name is NOT null then department_root_2.name
else case 
when department_root.name is NOT null then department_root.name
else department.name
end
end
end as name
from "user"
left join user_multiple_relations on "user".external_id = user_multiple_relations.parent_id
left join public.department on user_multiple_relations.value::bigint = department.external_id
left join public.department as department_root on department.parent::integer = department_root.external_id and department_root.external_id != 1
left join public.department as department_root_2 on department_root_2.external_id = department_root.parent::integer and department_root_2.external_id != 1) as departmant_person
where departmant_person.name is not null
    ) as departament on activiry_creator.external_id = departament.external_id
    WHERE case when uf_crm_1732516279 like '%deal%' then uf_crm_1732516279 else null end IS NOT NULL and departament.name in ('Телемаркетинг', 'Маркетинг')
)
SELECT 
    invoice_external_id,
    extracted_deal_external_id,
    last_name,
    activiry_creator_external_id,
    activity_external_id,
    departament_name
FROM RankedActivities
WHERE rn = 1
ORDER BY invoice_external_id
) invoice_with_money_with_incorrect_deal on invoice_with_money_with_incorrect_deal.invoice_external_id = coalesce(prices_without_duplicates.invoice_external_id, prices_without_duplicates_all.invoice_external_id)

where 
activity.deadline >= '2024-01-01 00:00:00'





union







select 
distinct 
-- activity.external_id as activity_id,
to_char(prices_without_duplicates_all.pay_voucher_date::date, 'YYYY-MM-DD') as meeting_plan_date,
to_char(prices_without_duplicates_all.pay_voucher_date::date, 'MM') as meeting_plan_month,
to_char(prices_without_duplicates_all.pay_voucher_date::date, 'YYYY') as meeting_plan_year,
case 
when department_responsible.department_responsible_root_name in ('Внедрение Синтека МСК', 'Внедрение Синтека СПб', 'Внедрение Синтека', 'Группа Внедрения ФК МСК', 'Группа Внедрения ФК СПб') then null
when invoice_with_money_with_incorrect_deal.invoice_external_id is not null then invoice_with_money_with_incorrect_deal.last_name
else activiry_creator.last_name
end as meeting_creator,
payment_creator_name.payment_creator_last_name as assigned_person,
deal.title as deal_title,
deal.external_id as deal_external_id,
concat('https://treesolution.bitrix24.ru/crm/deal/details/', deal.external_id, '/') as url,
case 
when activiry_creator.last_name is not null then 
    case 
    when department_responsible.department_responsible_root_name in ('Внедрение Синтека МСК', 'Внедрение Синтека СПб', 'Внедрение Синтека', 'Группа Внедрения ФК МСК', 'Группа Внедрения ФК СПб') then null
    else case 
        when lower(activity.location) in ('онлайн', 'звонок') then 'Онлайн'
        else 'Встреча'
    end end
else null
end as location,
case 
when TRIM(split_part(dealcategory.name, '-', 1)) = 'Поставщик' then 'Закупай'
else TRIM(split_part(dealcategory.name, '-', 1))
end as product,
case 
when department_responsible.department_responsible_root_name in ('Внедрение Синтека МСК', 'Внедрение Синтека СПб', 'Внедрение Синтека', 'Группа Внедрения ФК МСК', 'Группа Внедрения ФК СПб') then null
else to_char(activity.deadline, 'YYYY-MM-DD')
end as meeting_fact_date,
case 
when department_responsible.department_responsible_root_name in ('Внедрение Синтека МСК', 'Внедрение Синтека СПб', 'Внедрение Синтека', 'Группа Внедрения ФК МСК', 'Группа Внедрения ФК СПб') then null
else (activity.deadline + interval '3 HOUR')
end as meeting_fact_datetime,
dealcategory_stage.name as dealcategory_stage_name,
(case 
when department_responsible.department_responsible_root_name in ('Внедрение Синтека МСК', 'Внедрение Синтека СПб', 'Внедрение Синтека', 'Группа Внедрения ФК МСК', 'Группа Внедрения ФК СПб') then null
else case when (select 
dealcategory_stage.name
from deal_stagehistory
left join dealcategory_stage on dealcategory_stage.status_id::text = deal_stagehistory.stage_id::text and dealcategory_stage.category_id::bigint = deal_stagehistory.category_id::bigint
left join public.status on dealcategory_stage.status_id = status.status_id
where deal_stagehistory.owner_id = deal.external_id and deal_stagehistory.created_time + interval '3 hour' - INTERVAL '2 MINUTE' > (activity.start_time + interval '3 HOUR')
order by created_time ASC
limit 1
) is not null then (select 
dealcategory_stage.name
from deal_stagehistory
left join dealcategory_stage on dealcategory_stage.status_id::text = deal_stagehistory.stage_id::text and dealcategory_stage.category_id::bigint = deal_stagehistory.category_id::bigint
left join public.status on dealcategory_stage.status_id = status.status_id
where deal_stagehistory.owner_id = deal.external_id and deal_stagehistory.created_time + interval '3 hour' - INTERVAL '2 MINUTE' > (activity.start_time + interval '3 HOUR')
order by created_time ASC
limit 1
)
else (select 
dealcategory_stage.name
from deal_stagehistory
left join dealcategory_stage on dealcategory_stage.status_id::text = deal_stagehistory.stage_id::text and dealcategory_stage.category_id::bigint = deal_stagehistory.category_id::bigint
left join public.status on dealcategory_stage.status_id = status.status_id
where deal_stagehistory.owner_id = deal.external_id and deal_stagehistory.created_time + interval '3 hour' - INTERVAL '2 MINUTE' > (activity.created + interval '4 HOUR')
order by created_time ASC
limit 1
) end
end) as dealcategory_stage_name_history,
dealcategory_stage.external_id as dealcategory_stage_external_id,
case
when status.name is null then 'Прочее'
else status.name
end as deal_type,
null as deal_history,
deal.opportunity as deal_opportunity,
prices_without_duplicates_all.price as price,
prices_without_duplicates_all.invoice_external_id as invoice_external_id,
prices_without_duplicates_all.pay_voucher_date as pay_voucher_date,
case
when department.name in ('Внедрение Синтека МСК', 'Внедрение Синтека СПб', 'Внедрение Синтека', 'Группа Внедрения ФК МСК', 'Группа Внедрения ФК СПб') then NULL
when invoice_with_money_with_incorrect_deal.invoice_external_id is not null then invoice_with_money_with_incorrect_deal.departament_name
else department.name
end as department_name,
case
when status.name like '%Рекомендация%' and TRIM(split_part(dealcategory.name, '-', 1)) = 'Синтека' then 'Продажи Синтека СПб'
when status.name like '%Рекомендация%' and TRIM(split_part(dealcategory.name, '-', 1)) = 'FaceKIT' then 'Продажи FaceKIT/Face'
when status.name like '%Рекомендация%' and TRIM(split_part(dealcategory.name, '-', 1)) = 'FACE' then 'Продажи FaceKIT/Face'
when status.name like '%Рекомендация%' and TRIM(split_part(dealcategory.name, '-', 1)) = 'MySnab' then 'Продажи Закупай/mySnab'
else payment_creator_name.department_responsible_root_name
end AS department_responsible_name,
case 
when deal.utm_campaign = 'Неизвестно' then null
else deal.utm_campaign
end as deal_utm_campaign,
coalesce(deal.uf_crm_1556694126, lead.uf_crm_1556694091) as roistat_id,
CASE 
    WHEN strpos(activity.description, 'Регион: ') > 0 THEN
      substring(
        activity.description 
        FROM strpos(activity.description, 'Регион: ') + length('Регион: ') 
        FOR COALESCE(
          NULLIF(strpos(substring(activity.description FROM strpos(activity.description, 'Регион: ') + length('Регион: ')), E'\n'), 0),
          NULLIF(strpos(substring(activity.description FROM strpos(activity.description, 'Регион: ') + length('Регион: ')), E'\r\n'), 0),
          NULLIF(strpos(substring(activity.description FROM strpos(activity.description, 'Регион: ') + length('Регион: ')), E'\r'), 0),
          15
        ) - 1
      )
    ELSE 
      NULL
  END as extracted_region,
  CASE 
    WHEN strpos(activity.description, 'Контактное лицо+должность: ') > 0 THEN
      substring(
        activity.description 
        FROM strpos(activity.description, 'Контактное лицо+должность: ') + length('Контактное лицо+должность: ') 
        FOR COALESCE(
          NULLIF(strpos(substring(activity.description FROM strpos(activity.description, 'Контактное лицо+должность: ') + length('Контактное лицо+должность: ')), E'\n'), 0),
          NULLIF(strpos(substring(activity.description FROM strpos(activity.description, 'Контактное лицо+должность: ') + length('Контактное лицо+должность: ')), E'\r\n'), 0),
          NULLIF(strpos(substring(activity.description FROM strpos(activity.description, 'Контактное лицо+должность: ') + length('Контактное лицо+должность: ')), E'\r'), 0),
          50
        ) - 1
      )
    ELSE 
      NULL
  END as extracted_job_title,
to_char(lead.date_create, 'YYYY-MM-DD') as lead_date_create,
to_char(prices_without_duplicates_all.pay_voucher_date::date, 'YYYY') as pay_voucher_year,
to_char(prices_without_duplicates_all.pay_voucher_date::date, 'MM') as pay_voucher_month,
company.comments as company_comments,
deal.date_create as deal_date_create,
prices_without_duplicates_all.invoice_status_name as invoice_status_name,
null::numeric as deal_history_bool,
case
when prices_without_duplicates_all.pay_voucher_date is null then 0
else 1 
end as pay_voucher_bool,
dealcategory.name as funnel
from public.deal
left join public."user" on case when deal.uf_crm_1522603723 = '' then NULL else deal.uf_crm_1522603723::bigint end = "user".external_id
left join public.dealcategory on deal.category_id::bigint = dealcategory.external_id
left join public.activity on deal.external_id = activity.owner_id and activity.provider_type_id = 'MEETING' and activity.owner_type_id::numeric = 2
left join public."user" as activiry_creator on activity.author_id::bigint = activiry_creator.external_id
left join public.dealcategory_stage on deal.stage_id = dealcategory_stage.status_id
left join public."user" as user_assigned on activity.responsible_id::bigint = user_assigned.external_id
left join public.status on deal.type_id = status.status_id and status.entity_id = 'DEAL_TYPE'
left join public.deal_stagehistory on deal.external_id::bigint = deal_stagehistory.owner_id
left join public.invoice on deal.external_id = invoice.uf_deal_id and invoice.responsible_id = user_assigned.external_id 
left join (
select * from
(select distinct
"user".external_id as external_id,
"user".last_name as last_name,
case 
when "user".last_name = 'Горелова' then 'Внедрение Синтека СПб'
when "user".last_name = 'Зюков' then 'Продажи Синтека СПб'
when "user".last_name = 'Алаторцев' then 'Группа Внедрения ФК СПб'
when department.name = 'Онлайн Внедрение FaceKIT' then 'Группа Внедрения ФК СПб'
when department.name = 'Внедрение Синтека МСК' then 'Внедрение Синтека МСК'
when department.name in ('Группа Внедрения МСК 1', 'Группа Внедрения МСК 2', 'Группа Внедрения МСК 3', 'Группа Внедрения МСК 4') then 'Группа Внедрения ФК МСК'
when department.name in ('Внедрения Синтека СПб 1', 'Внедрения Синтека СПб 2', 'Внедрения Синтека СПб 3', 'Внедрения Синтека СПб 4') then 'Внедрение Синтека СПб'
when department.name in ('Группа Внедрения СПб 1', 'Группа Внедрения СПб 2', 'Группа Внедрения СПб 3', 'Группа Внедрения СПб 4') then 'Группа Внедрения ФК СПб'
else case 
when department_root_2.name is NOT null then department_root_2.name
else case 
when department_root.name is NOT null then department_root.name
else department.name
end
end
end as name
from "user"
left join user_multiple_relations on "user".external_id = user_multiple_relations.parent_id
left join public.department on user_multiple_relations.value::bigint = department.external_id
left join public.department as department_root on department.parent::integer = department_root.external_id and department_root.external_id != 1
left join public.department as department_root_2 on department_root_2.external_id = department_root.parent::integer and department_root_2.external_id != 1) as departmant_person
where departmant_person.name is not null
) as department on activiry_creator.external_id = department.external_id
left join (
select distinct
user_multiple_relations_responsible.parent_id,
case
when department_responsible_root.external_id is null then department_responsible.external_id
else department_responsible_root.external_id
end as department_responsible_external_id,
case 
when department_responsible_root.name is null then department_responsible.name
else department_responsible_root.name
end as department_responsible_root_name
from public.deal
left join public."user" on case when deal.uf_crm_1522603723 = '' then NULL else deal.uf_crm_1522603723::bigint end = "user".external_id
left join public.dealcategory on deal.category_id::bigint = dealcategory.external_id
left join public.activity on deal.external_id = activity.owner_id and activity.provider_type_id = 'MEETING' and activity.owner_type_id::numeric = 2
left join public."user" as activiry_creator on activity.author_id::bigint = activiry_creator.external_id
left join public.dealcategory_stage on deal.stage_id = dealcategory_stage.status_id
left join public."user" as user_assigned on activity.responsible_id::bigint = user_assigned.external_id
left join public.status on deal.type_id = status.status_id and status.entity_id = 'DEAL_TYPE'
left join public.deal_stagehistory on deal.external_id::bigint = deal_stagehistory.owner_id
left join public.invoice on deal.external_id = invoice.uf_deal_id and invoice.responsible_id = user_assigned.external_id 
left join public.user_multiple_relations on activiry_creator.external_id = user_multiple_relations.parent_id
left join public.department on user_multiple_relations.value::bigint = department.external_id
left join public.user_multiple_relations as user_multiple_relations_responsible on activity.responsible_id::bigint = user_multiple_relations_responsible.parent_id
left join public.department as department_responsible on user_multiple_relations_responsible.value::bigint = department_responsible.external_id
left join public.department as department_responsible_root on department_responsible_root.external_id = department_responsible.parent::integer and department_responsible_root.external_id != 1
) as department_responsible on activity.responsible_id::bigint = department_responsible.parent_id
left join (
select 
t0.activity_external_id,
t0.price as price,
t0.deal_external_id,
t0.pay_voucher_date,
t0.invoice_status_name,
t0.invoice_external_id
from (select
invoice.external_id as invoice_external_id,
max(activity.external_id) as activity_external_id,
((json_array_elements((invoice.uf_crm_1707306084::json ->> 'payments')::json)::json) ->> 'amount') as price,
deal.external_id as deal_external_id,
((json_array_elements((invoice.uf_crm_1707306084::json ->> 'payments')::json)::json) ->> 'date') as pay_voucher_date,
status.name as invoice_status_name
from public.deal
left join public.activity on deal.external_id = activity.owner_id and activity.provider_type_id = 'MEETING' and activity.owner_type_id::numeric = 2
left join public."user" as user_assigned on activity.responsible_id::bigint = user_assigned.external_id
left join public.invoice on deal.external_id = invoice.uf_deal_id 
left join public."user" as activiry_creator on activity.author_id::bigint = activiry_creator.external_id
left join public.user_multiple_relations on activiry_creator.external_id = user_multiple_relations.parent_id
left join public.department on user_multiple_relations.value::bigint = department.external_id
left join status on invoice.status_id = status.status_id and status.entity_id = 'INVOICE_STATUS'
where status.name in ('Оплачен', 'Частично оплачен', 'Отклонён')
and activity.deleted is not true
group by deal.external_id, invoice.external_id, status.name, invoice.uf_crm_1706529993, invoice.date_status, invoice.uf_crm_1707306084
) as t0
where price is not null
) as prices_without_duplicates_all on deal.external_id = prices_without_duplicates_all.deal_external_id
left join (
select 
t0.activity_external_id,
t0.price as price,
t0.deal_external_id,
t0.pay_voucher_date,
t0.payment_creator_last_name,
t0.payment_creator_external_id,
t0.department_responsible_root_name
from (
select
max(activity.external_id) as activity_external_id,
((json_array_elements((invoice.uf_crm_1707306084::json ->> 'payments')::json)::json) ->> 'amount') as price,
deal.external_id as deal_external_id,
((json_array_elements((invoice.uf_crm_1707306084::json ->> 'payments')::json)::json) ->> 'date') as pay_voucher_date,
payment_creator.last_name as payment_creator_last_name,
payment_creator.external_id as payment_creator_external_id,
case 
when payment_creator.last_name = 'Горелова' then 'Внедрение Синтека СПб'
when payment_creator.last_name = 'Зюков' then 'Внедрение Синтека СПб'
when payment_creator.last_name = 'Алаторцев' then 'Группа Внедрения ФК СПб'
when department_responsible.name = 'Онлайн Внедрение FaceKIT' then 'Группа Внедрения ФК СПб'
when department_responsible.name = 'Внедрение Синтека МСК' then 'Внедрение Синтека МСК'
when department_responsible.name in ('Группа Внедрения МСК 1', 'Группа Внедрения МСК 2', 'Группа Внедрения МСК 3', 'Группа Внедрения МСК 4') then 'Группа Внедрения ФК МСК'
when department_responsible.name in ('Внедрения Синтека СПб 1', 'Внедрения Синтека СПб 2', 'Внедрения Синтека СПб 3', 'Внедрения Синтека СПб 4') then 'Внедрение Синтека СПб'
when department_responsible.name in ('Группа Внедрения СПб 1', 'Группа Внедрения СПб 2', 'Группа Внедрения СПб 3', 'Группа Внедрения СПб 4') then 'Группа Внедрения ФК СПб'
else case 
when department_responsible_root_2.name is NOT null then department_responsible_root_2.name
else case 
when department_responsible_root.name is NOT null then department_responsible_root.name
else department_responsible.name
end
end
end as department_responsible_root_name
from public.deal
left join public.activity on deal.external_id = activity.owner_id and activity.provider_type_id = 'MEETING' and activity.owner_type_id::numeric = 2
left join public."user" as user_assigned on activity.responsible_id::bigint = user_assigned.external_id
left join public.invoice on deal.external_id = invoice.uf_deal_id
left join public."user" as payment_creator on invoice.responsible_id = payment_creator.external_id 
left join public.user_multiple_relations as user_multiple_relations_responsible on payment_creator.external_id = user_multiple_relations_responsible.parent_id
left join public.department as department_responsible on user_multiple_relations_responsible.value::bigint = department_responsible.external_id
left join public.department as department_responsible_root on department_responsible_root.external_id = department_responsible.parent::integer and department_responsible_root.external_id != 1
left join public.department as department_responsible_root_2 on department_responsible_root_2.external_id = department_responsible_root.parent::integer and department_responsible_root_2.external_id != 1
group by deal.external_id, invoice.pay_voucher_date, invoice.price, payment_creator.last_name, payment_creator.external_id, department_responsible_root.external_id, department_responsible.external_id, department_responsible_root.name, department_responsible.name, department_responsible_root_2.external_id, department_responsible_root_2.name, invoice.uf_crm_1707306084
) as t0
where price is not null and department_responsible_root_name <> 'Обработка данных'
) as payment_creator_name on payment_creator_name.deal_external_id = deal.external_id and to_char(payment_creator_name.pay_voucher_date::date, 'YYYY-MM-DD') = to_char(prices_without_duplicates_all.pay_voucher_date::date, 'YYYY-MM-DD') and payment_creator_name.price = prices_without_duplicates_all.price
left join company on deal.company_id::integer = company.external_id
left join lead on case when company.lead_id = '' then null else company.lead_id::integer end = lead.external_id



left join (
WITH RankedActivities AS (
    SELECT 
        invoice.external_id as invoice_external_id,
        regexp_replace(
            case when uf_crm_1732516279 like '%deal%' then uf_crm_1732516279 else null end, 
            '^https://treesolution\.bitrix24\.ru/crm/deal/details/(\d+)/.*$', 
            '\1'
        ) AS extracted_deal_external_id,
        activiry_creator.last_name,
        activiry_creator.external_id as activiry_creator_external_id,
        activity.external_id as activity_external_id,
        departament.name as departament_name,
        ROW_NUMBER() OVER (PARTITION BY invoice.external_id ORDER BY activity.external_id DESC) AS rn
    FROM invoice 
    LEFT JOIN public.deal ON regexp_replace(case when uf_crm_1732516279 like '%deal%' then uf_crm_1732516279 else null end, '^https://treesolution\.bitrix24\.ru/crm/deal/details/(\d+)/.*$', '\1')::bigint = deal.external_id
    LEFT JOIN public."user" ON case when deal.uf_crm_1522603723 = '' then NULL else deal.uf_crm_1522603723::bigint end = "user".external_id
    LEFT JOIN public.dealcategory ON deal.category_id::bigint = dealcategory.external_id
    LEFT JOIN public.activity ON deal.external_id = activity.owner_id AND activity.provider_type_id = 'MEETING' AND activity.owner_type_id::numeric = 2
    LEFT JOIN public."user" AS activiry_creator ON activity.author_id::bigint = activiry_creator.external_id
    left join (
    select * from
(select distinct
"user".external_id as external_id,
"user".last_name as last_name,
case 
when "user".last_name = 'Горелова' then 'Внедрение Синтека СПб'
when "user".last_name = 'Зюков' then 'Продажи Синтека СПб'
when "user".last_name = 'Алаторцев' then 'Группа Внедрения ФК СПб'
when department.name = 'Онлайн Внедрение FaceKIT' then 'Группа Внедрения ФК СПб'
when department.name = 'Внедрение Синтека МСК' then 'Внедрение Синтека МСК'
when department.name in ('Группа Внедрения МСК 1', 'Группа Внедрения МСК 2', 'Группа Внедрения МСК 3', 'Группа Внедрения МСК 4') then 'Группа Внедрения ФК МСК'
when department.name in ('Внедрения Синтека СПб 1', 'Внедрения Синтека СПб 2', 'Внедрения Синтека СПб 3', 'Внедрения Синтека СПб 4') then 'Внедрение Синтека СПб'
when department.name in ('Группа Внедрения СПб 1', 'Группа Внедрения СПб 2', 'Группа Внедрения СПб 3', 'Группа Внедрения СПб 4') then 'Группа Внедрения ФК СПб'
else case 
when department_root_2.name is NOT null then department_root_2.name
else case 
when department_root.name is NOT null then department_root.name
else department.name
end
end
end as name
from "user"
left join user_multiple_relations on "user".external_id = user_multiple_relations.parent_id
left join public.department on user_multiple_relations.value::bigint = department.external_id
left join public.department as department_root on department.parent::integer = department_root.external_id and department_root.external_id != 1
left join public.department as department_root_2 on department_root_2.external_id = department_root.parent::integer and department_root_2.external_id != 1) as departmant_person
where departmant_person.name is not null
    ) as departament on activiry_creator.external_id = departament.external_id
    WHERE case when uf_crm_1732516279 like '%deal%' then uf_crm_1732516279 else null end IS NOT NULL and departament.name in ('Телемаркетинг', 'Маркетинг')
)
SELECT 
    invoice_external_id,
    extracted_deal_external_id,
    last_name,
    activiry_creator_external_id,
    activity_external_id,
    departament_name
FROM RankedActivities
WHERE rn = 1
ORDER BY invoice_external_id
) invoice_with_money_with_incorrect_deal on invoice_with_money_with_incorrect_deal.invoice_external_id = prices_without_duplicates_all.invoice_external_id



where prices_without_duplicates_all.pay_voucher_date is not null
and activity.created is null
and to_char(prices_without_duplicates_all.pay_voucher_date::date, 'YYYY-MM-DD') >= '2024-01-01'






union





select 
distinct 
-- activity.external_id as activity_id,
case 
when department_responsible.name in ('Внедрение Синтека МСК', 'Внедрение Синтека СПб', 'Внедрение Синтека', 'Группа Внедрения ФК МСК', 'Группа Внедрения ФК СПб') then to_char(coalesce(prices_without_duplicates.pay_voucher_date, prices_without_duplicates_all.pay_voucher_date)::date, 'YYYY-MM-DD'::text)
else to_char(activity.created, 'YYYY-MM-DD')
end as meeting_plan_date,
case 
when department_responsible.name in ('Внедрение Синтека МСК', 'Внедрение Синтека СПб', 'Внедрение Синтека', 'Группа Внедрения ФК МСК', 'Группа Внедрения ФК СПб') then to_char(coalesce(prices_without_duplicates.pay_voucher_date, prices_without_duplicates_all.pay_voucher_date)::date, 'MM'::text)
else to_char(activity.created, 'MM')
end as meeting_plan_month,
case 
when department_responsible.name in ('Внедрение Синтека МСК', 'Внедрение Синтека СПб', 'Внедрение Синтека', 'Группа Внедрения ФК МСК', 'Группа Внедрения ФК СПб') then to_char(coalesce(prices_without_duplicates.pay_voucher_date, prices_without_duplicates_all.pay_voucher_date)::date, 'YYYY'::text)
else to_char(activity.created, 'YYYY')
end as meeting_plan_year,
case 
when department_responsible.name in ('Внедрение Синтека МСК', 'Внедрение Синтека СПб', 'Внедрение Синтека', 'Группа Внедрения ФК МСК', 'Группа Внедрения ФК СПб') then null
when invoice_with_money_with_incorrect_deal.invoice_external_id is not null then invoice_with_money_with_incorrect_deal.last_name
else activiry_creator.last_name
end as meeting_creator,
user_assigned.last_name as assigned_person,
deal.title as deal_title,
deal.external_id as deal_external_id,
concat('https://treesolution.bitrix24.ru/crm/deal/details/', deal.external_id, '/') as url,
case 
when activiry_creator.last_name is not null then 
    case 
    when department_responsible.name in ('Внедрение Синтека МСК', 'Внедрение Синтека СПб', 'Внедрение Синтека', 'Группа Внедрения ФК МСК', 'Группа Внедрения ФК СПб') then null
    else case 
        when lower(activity.location) in ('онлайн', 'звонок') then 'Онлайн'
        else 'Встреча'
    end end
else null
end as location,
case 
when TRIM(split_part(dealcategory.name, '-', 1)) = 'Поставщик' then 'Закупай'
else TRIM(split_part(dealcategory.name, '-', 1))
end as product,
case 
when department_responsible.name in ('Внедрение Синтека МСК', 'Внедрение Синтека СПб', 'Внедрение Синтека', 'Группа Внедрения ФК МСК', 'Группа Внедрения ФК СПб') then null
else to_char(activity.deadline, 'YYYY-MM-DD')
end as meeting_fact_date,
case 
when department_responsible.name in ('Внедрение Синтека МСК', 'Внедрение Синтека СПб', 'Внедрение Синтека', 'Группа Внедрения ФК МСК', 'Группа Внедрения ФК СПб') then null
else (activity.deadline + interval '3 HOUR')
end as meeting_fact_datetime,
dealcategory_stage.name as dealcategory_stage_name,
(case 
when department_responsible.name in ('Внедрение Синтека МСК', 'Внедрение Синтека СПб', 'Внедрение Синтека', 'Группа Внедрения ФК МСК', 'Группа Внедрения ФК СПб') then null
else case when (select 
dealcategory_stage.name
from deal_stagehistory
left join dealcategory_stage on dealcategory_stage.status_id::text = deal_stagehistory.stage_id::text and dealcategory_stage.category_id::bigint = deal_stagehistory.category_id::bigint
left join public.status on dealcategory_stage.status_id = status.status_id
where deal_stagehistory.owner_id = deal.external_id and deal_stagehistory.created_time + interval '3 hour' - INTERVAL '2 MINUTE' > (activity.start_time + interval '3 HOUR')
order by created_time ASC
limit 1
) is not null then (select 
dealcategory_stage.name
from deal_stagehistory
left join dealcategory_stage on dealcategory_stage.status_id::text = deal_stagehistory.stage_id::text and dealcategory_stage.category_id::bigint = deal_stagehistory.category_id::bigint
left join public.status on dealcategory_stage.status_id = status.status_id
where deal_stagehistory.owner_id = deal.external_id and deal_stagehistory.created_time + interval '3 hour' - INTERVAL '2 MINUTE' > (activity.start_time + interval '3 HOUR')
order by created_time ASC
limit 1
)
else (select 
dealcategory_stage.name
from deal_stagehistory
left join dealcategory_stage on dealcategory_stage.status_id::text = deal_stagehistory.stage_id::text and dealcategory_stage.category_id::bigint = deal_stagehistory.category_id::bigint
left join public.status on dealcategory_stage.status_id = status.status_id
where deal_stagehistory.owner_id = deal.external_id and deal_stagehistory.created_time + interval '3 hour' - INTERVAL '2 MINUTE' > (activity.created + interval '4 HOUR')
order by created_time ASC
limit 1
) end
end) as dealcategory_stage_name_history,
dealcategory_stage.external_id as dealcategory_stage_external_id,
case
when status.name is null then 'Прочее'
else status.name
end as deal_type,
case
when status.name like '%Рекомендация%' then null
else
case 
when department_responsible.name in ('Внедрение Синтека МСК', 'Внедрение Синтека СПб', 'Внедрение Синтека', 'Группа Внедрения ФК МСК', 'Группа Внедрения ФК СПб') then null
when activity.deadline + interval '3 HOUR' > now() then 'Запланирована'
when activity.deleted = true then 'Удалена'
else coalesce((select case when status = true then 'Состоялась' else 'Не состоялась' end as status from activity_status where activity.external_id = activity_status.external_id),(select 
case
   when (activity.deadline + interval '3 HOUR') > now() then 'Запланирована'
   else case
       when activity.completed = 'N' then 'Требует внимания'
       when activity.deleted = true then 'Удалена'
       when dealcategory.external_id in (0, 14, 21, 27, 43) and dealcategory_stage.external_id in (143155765, 166643006, 508971364, 266188974, 183164335, 390627843, 421765209, 376240355, 347625181, 867028305, 353444384, 296119337, 406142322, 175445540, 103326737, 391101203, 310474062, 296119337, 143155765, 152010674, 150482595, 372689215, 362829961, 399900605, 305732812, 264087650, 536239320, 239586655, 399747706, 189303590, 900168313, 310199051, 393700248, 714707281, 211091281, 197074812, 376806040, 336100805, 166643006, 413166457, 175445540) then 'Не состоялась'
       when dealcategory.external_id in (21, 43) and dealcategory_stage.external_id in (287975271, 265814213, 606586632, 754111997, 409989064, 111670877, 215951352, 302942547, 362396047, 186299416, 193439272, 416311385, 336565364, 428450726, 275716818, 301404773, 171942459, 117252070, 221675922, 397435915, 371764294, 382291224, 176891461) then 'Состоялась'
       else 'Состоялась'
   end
end
from deal_stagehistory
left join dealcategory_stage on dealcategory_stage.status_id::text = deal_stagehistory.stage_id::text and dealcategory_stage.category_id::bigint = deal_stagehistory.category_id::bigint
where deal_stagehistory.owner_id = deal.external_id and deal_stagehistory.created_time + interval '3 HOUR' - INTERVAL '2 MINUTE' > (activity.start_time + interval '3 HOUR')
order by created_time DESC
limit 1
),(select 
case
   when (activity.deadline + interval '3 HOUR') > now() then 'Запланирована'
   else case
       when activity.completed = 'N' then 'Требует внимания'
       when activity.deleted = true then 'Удалена'
       when dealcategory.external_id in (0, 14, 21, 27, 43) and dealcategory_stage.external_id in (143155765, 166643006, 508971364, 266188974, 183164335, 390627843, 421765209, 376240355, 347625181, 867028305, 353444384, 296119337, 406142322, 175445540, 103326737, 391101203, 310474062, 296119337, 143155765, 152010674, 150482595, 372689215, 362829961, 399900605, 305732812, 264087650, 536239320, 239586655, 399747706, 189303590, 900168313, 310199051, 393700248, 714707281, 211091281, 197074812, 376806040, 336100805, 166643006, 413166457, 175445540) then 'Не состоялась'
       when dealcategory.external_id in (21, 43) and dealcategory_stage.external_id in (287975271, 265814213, 606586632, 754111997, 409989064, 111670877, 215951352, 302942547, 362396047, 186299416, 193439272, 416311385, 336565364, 428450726, 275716818, 301404773, 171942459, 117252070, 221675922, 397435915, 371764294, 382291224, 176891461) then 'Состоялась'
       else 'Состоялась'
   end
end
from deal_stagehistory
left join dealcategory_stage on dealcategory_stage.status_id::text = deal_stagehistory.stage_id::text and dealcategory_stage.category_id::bigint = deal_stagehistory.category_id::bigint
where deal_stagehistory.owner_id = deal.external_id and deal_stagehistory.created_time + interval '3 HOUR' - INTERVAL '2 MINUTE' > (activity.created + interval '3 HOUR')
order by created_time DESC
limit 1
),  case when activity.completed = 'Y' and dealcategory.external_id in (0, 14, 21, 27, 43) and dealcategory_stage.external_id in (143155765, 166643006, 508971364, 266188974, 183164335, 390627843, 421765209, 376240355, 347625181, 867028305, 353444384, 296119337, 406142322, 175445540, 103326737, 391101203, 310474062, 296119337, 143155765, 152010674, 150482595, 372689215, 362829961, 399900605, 305732812, 264087650, 536239320, 239586655, 399747706, 189303590, 900168313, 310199051, 393700248, 714707281, 211091281, 197074812, 376806040, 336100805, 166643006, 413166457, 175445540) then 'Не состоялась'
when activity.completed = 'Y' and dealcategory_stage.external_id not in (316220655, 355798727, 263361884, 353150184, 166593526, 223859750) then 'Состоялась'
else 'Требует внимания' end ) end end as deal_history,
deal.opportunity as deal_opportunity,
coalesce(prices_without_duplicates.price, prices_without_duplicates_all.price) as price,
coalesce(prices_without_duplicates.invoice_external_id, prices_without_duplicates_all.invoice_external_id) as invoice_external_id,
coalesce(prices_without_duplicates.pay_voucher_date, prices_without_duplicates_all.pay_voucher_date) as pay_voucher_date,
case
when department.name in ('Внедрение Синтека МСК', 'Внедрение Синтека СПб', 'Внедрение Синтека', 'Группа Внедрения ФК МСК', 'Группа Внедрения ФК СПб') then NULL
when invoice_with_money_with_incorrect_deal.invoice_external_id is not null then invoice_with_money_with_incorrect_deal.departament_name
else department.name
end as department_name,
case
when status.name like '%Рекомендация%' and TRIM(split_part(dealcategory.name, '-', 1)) = 'Синтека' then 'Продажи Синтека СПб'
when status.name like '%Рекомендация%' and TRIM(split_part(dealcategory.name, '-', 1)) = 'FaceKIT' then 'Продажи FaceKIT/Face'
when status.name like '%Рекомендация%' and TRIM(split_part(dealcategory.name, '-', 1)) = 'FACE' then 'Продажи FaceKIT/Face'
when status.name like '%Рекомендация%' and TRIM(split_part(dealcategory.name, '-', 1)) = 'MySnab' then 'Продажи Закупай/mySnab'
else department_responsible.name
end AS department_responsible_name,
case 
when deal.utm_campaign = 'Неизвестно' then null
else deal.utm_campaign
end as deal_utm_campaign,
coalesce(deal.uf_crm_1556694126, lead.uf_crm_1556694091) as roistat_id,
CASE 
    WHEN strpos(activity.description, 'Регион: ') > 0 THEN
      substring(
        activity.description 
        FROM strpos(activity.description, 'Регион: ') + length('Регион: ') 
        FOR COALESCE(
          NULLIF(strpos(substring(activity.description FROM strpos(activity.description, 'Регион: ') + length('Регион: ')), E'\n'), 0),
          NULLIF(strpos(substring(activity.description FROM strpos(activity.description, 'Регион: ') + length('Регион: ')), E'\r\n'), 0),
          NULLIF(strpos(substring(activity.description FROM strpos(activity.description, 'Регион: ') + length('Регион: ')), E'\r'), 0),
          15
        ) - 1
      )
    ELSE 
      NULL
  END as extracted_region,
  CASE 
    WHEN strpos(activity.description, 'Контактное лицо+должность: ') > 0 THEN
      substring(
        activity.description 
        FROM strpos(activity.description, 'Контактное лицо+должность: ') + length('Контактное лицо+должность: ') 
        FOR COALESCE(
          NULLIF(strpos(substring(activity.description FROM strpos(activity.description, 'Контактное лицо+должность: ') + length('Контактное лицо+должность: ')), E'\n'), 0),
          NULLIF(strpos(substring(activity.description FROM strpos(activity.description, 'Контактное лицо+должность: ') + length('Контактное лицо+должность: ')), E'\r\n'), 0),
          NULLIF(strpos(substring(activity.description FROM strpos(activity.description, 'Контактное лицо+должность: ') + length('Контактное лицо+должность: ')), E'\r'), 0),
          50
        ) - 1
      )
    ELSE 
      NULL
  END as extracted_job_title,
to_char(lead.date_create, 'YYYY-MM-DD') as lead_date_create,
to_char(coalesce(prices_without_duplicates.pay_voucher_date, prices_without_duplicates_all.pay_voucher_date)::date, 'YYYY') as pay_voucher_year,
to_char(coalesce(prices_without_duplicates.pay_voucher_date, prices_without_duplicates_all.pay_voucher_date)::date, 'MM') as pay_voucher_month,
company.comments as company_comments,
deal.date_create as deal_date_create,
coalesce(prices_without_duplicates.invoice_status_name, prices_without_duplicates_all.invoice_status_name) as invoice_status_name,
case
when status.name like '%Рекомендация%' then null
else
case 
when department_responsible.name in ('Внедрение Синтека МСК', 'Внедрение Синтека СПб', 'Внедрение Синтека', 'Группа Внедрения ФК МСК', 'Группа Внедрения ФК СПб') then null
when activity.deadline + interval '3 HOUR' > now() then 0
when activity.deleted = true then 4
else coalesce((select case when status = true then 1 else 2 end as status from activity_status where activity.external_id = activity_status.external_id),(select 
-- external_id
case
   when (activity.deadline + interval '3 HOUR') > now() then 0 --'Запланирована'
   else case
       when activity.completed = 'N' then 3
       when activity.deleted = true then 4 --'Удалена'
       when dealcategory.external_id in (0, 14, 21, 27, 43) and dealcategory_stage.external_id in (143155765, 166643006, 508971364, 266188974, 183164335, 390627843, 421765209, 376240355, 347625181, 867028305, 353444384, 296119337, 406142322, 175445540, 103326737, 391101203, 310474062, 296119337, 143155765, 152010674, 150482595, 372689215, 362829961, 399900605, 305732812, 264087650, 536239320, 239586655, 399747706, 189303590, 900168313, 310199051, 393700248, 714707281, 211091281, 197074812, 376806040, 336100805, 166643006, 413166457, 175445540, 103326737, 406142322) then 2 --'Не состоялась'
       when dealcategory.external_id in (21, 43) and dealcategory_stage.external_id in (287975271, 265814213, 606586632, 754111997, 409989064, 111670877, 215951352, 302942547, 362396047, 186299416, 193439272, 416311385, 336565364, 428450726, 275716818, 301404773, 171942459, 117252070, 221675922, 397435915, 371764294, 382291224, 176891461) then 1
       else 1 --'Состоялась'
   end
end
from deal_stagehistory
left join dealcategory_stage on dealcategory_stage.status_id::text = deal_stagehistory.stage_id::text and dealcategory_stage.category_id::bigint = deal_stagehistory.category_id::bigint
where deal_stagehistory.owner_id = deal.external_id and deal_stagehistory.created_time + interval '3 HOUR' - INTERVAL '2 MINUTE' > (activity.start_time + interval '3 HOUR')
order by created_time DESC
limit 1
),(select 
-- external_id
case
   when (activity.deadline + interval '3 HOUR') > now() then 0 --'Запланирована'
   else case
       when activity.completed = 'N' then 3
       when activity.deleted = true then 4 --'Удалена'
       when dealcategory.external_id in (0, 14, 21, 27, 43) and dealcategory_stage.external_id in (143155765, 166643006, 508971364, 266188974, 183164335, 390627843, 421765209, 376240355, 347625181, 867028305, 353444384, 296119337, 406142322, 175445540, 103326737, 391101203, 310474062, 296119337, 143155765, 152010674, 150482595, 372689215, 362829961, 399900605, 305732812, 264087650, 536239320, 239586655, 399747706, 189303590, 900168313, 310199051, 393700248, 714707281, 211091281, 197074812, 376806040, 336100805, 166643006, 413166457, 175445540, 103326737, 406142322) then 2 --'Не состоялась'
       when dealcategory.external_id in (21, 43) and dealcategory_stage.external_id in (287975271, 265814213, 606586632, 754111997, 409989064, 111670877, 215951352, 302942547, 362396047, 186299416, 193439272, 416311385, 336565364, 428450726, 275716818, 301404773, 171942459, 117252070, 221675922, 397435915, 371764294, 382291224, 176891461) then 1
       else 1 --'Состоялась'
   end
end
from deal_stagehistory
left join dealcategory_stage on dealcategory_stage.status_id::text = deal_stagehistory.stage_id::text and dealcategory_stage.category_id::bigint = deal_stagehistory.category_id::bigint
where deal_stagehistory.owner_id = deal.external_id and deal_stagehistory.created_time + interval '3 HOUR' - INTERVAL '2 MINUTE' > (activity.created + interval '3 HOUR')
order by created_time DESC
limit 1
),  case when activity.completed = 'Y' and dealcategory.external_id in (0, 14, 21, 27, 43) and dealcategory_stage.external_id in (143155765, 166643006, 508971364, 266188974, 183164335, 390627843, 421765209, 376240355, 347625181, 867028305, 353444384, 296119337, 406142322, 175445540, 103326737, 391101203, 310474062, 296119337, 143155765, 152010674, 150482595, 372689215, 362829961, 399900605, 305732812, 264087650, 536239320, 239586655, 399747706, 189303590, 900168313, 310199051, 393700248, 714707281, 211091281, 197074812, 376806040, 336100805, 166643006, 413166457, 175445540) then 2
when activity.completed = 'Y' and dealcategory_stage.external_id not in (316220655, 355798727, 263361884, 353150184, 166593526, 223859750) then 1
else 3 end  --'Требует внимания'
) end END as deal_history_bool,
case
when coalesce(prices_without_duplicates.pay_voucher_date, prices_without_duplicates_all.pay_voucher_date) is null then 0
else 1 
end as pay_voucher_bool,
dealcategory.name as funnel
from public.deal
left join public."user" on case when deal.uf_crm_1522603723 = '' then NULL else deal.uf_crm_1522603723::bigint end = "user".external_id
left join public.dealcategory on deal.category_id::bigint = dealcategory.external_id
left join public.activity on deal.external_id = activity.owner_id and activity.provider_type_id = 'MEETING' and activity.owner_type_id::numeric = 2
left join public."user" as activiry_creator on activity.author_id::bigint = activiry_creator.external_id
left join public.dealcategory_stage on deal.stage_id = dealcategory_stage.status_id
left join public."user" as user_assigned on activity.responsible_id::bigint = user_assigned.external_id
left join public.status on deal.type_id = status.status_id and status.entity_id = 'DEAL_TYPE'
left join public.deal_stagehistory on deal.external_id::bigint = deal_stagehistory.owner_id
left join public.invoice on deal.external_id = invoice.uf_deal_id and invoice.responsible_id = user_assigned.external_id 
left join (
select * from
(select distinct
"user".external_id as external_id,
"user".last_name as last_name,
case 
when "user".last_name = 'Горелова' then 'Внедрение Синтека СПб'
when "user".last_name = 'Зюков' then 'Продажи Синтека СПб'
when "user".last_name = 'Алаторцев' then 'Группа Внедрения ФК СПб'
when department.name = 'Онлайн Внедрение FaceKIT' then 'Группа Внедрения ФК СПб'
when department.name = 'Внедрение Синтека МСК' then 'Внедрение Синтека МСК'
when department.name in ('Группа Внедрения МСК 1', 'Группа Внедрения МСК 2', 'Группа Внедрения МСК 3', 'Группа Внедрения МСК 4') then 'Группа Внедрения ФК МСК'
when department.name in ('Внедрения Синтека СПб 1', 'Внедрения Синтека СПб 2', 'Внедрения Синтека СПб 3', 'Внедрения Синтека СПб 4') then 'Внедрение Синтека СПб'
when department.name in ('Группа Внедрения СПб 1', 'Группа Внедрения СПб 2', 'Группа Внедрения СПб 3', 'Группа Внедрения СПб 4') then 'Группа Внедрения ФК СПб'
else case 
when department_root_2.name is NOT null then department_root_2.name
else case 
when department_root.name is NOT null then department_root.name
else department.name
end
end
end as name
from "user"
left join user_multiple_relations on "user".external_id = user_multiple_relations.parent_id
left join public.department on user_multiple_relations.value::bigint = department.external_id
left join public.department as department_root on department.parent::integer = department_root.external_id and department_root.external_id != 1
left join public.department as department_root_2 on department_root_2.external_id = department_root.parent::integer and department_root_2.external_id != 1) as departmant_person
where departmant_person.name is not null
) as department on activiry_creator.external_id = department.external_id
left join (
select * from
(select distinct
"user".external_id as external_id,
"user".last_name as last_name,
case 
when "user".last_name = 'Горелова' then 'Внедрение Синтека СПб'
when "user".last_name = 'Зюков' then 'Продажи Синтека СПб'
when "user".last_name = 'Алаторцев' then 'Группа Внедрения ФК СПб'
when department.name = 'Онлайн Внедрение FaceKIT' then 'Группа Внедрения ФК СПб'
when department.name = 'Внедрение Синтека МСК' then 'Внедрение Синтека МСК'
when department.name in ('Группа Внедрения МСК 1', 'Группа Внедрения МСК 2', 'Группа Внедрения МСК 3', 'Группа Внедрения МСК 4') then 'Группа Внедрения ФК МСК'
when department.name in ('Внедрения Синтека СПб 1', 'Внедрения Синтека СПб 2', 'Внедрения Синтека СПб 3', 'Внедрения Синтека СПб 4') then 'Внедрение Синтека СПб'
when department.name in ('Группа Внедрения СПб 1', 'Группа Внедрения СПб 2', 'Группа Внедрения СПб 3', 'Группа Внедрения СПб 4') then 'Группа Внедрения ФК СПб'
else case 
when department_root_2.name is NOT null then department_root_2.name
else case 
when department_root.name is NOT null then department_root.name
else department.name
end
end
end as name
from "user"
left join user_multiple_relations on "user".external_id = user_multiple_relations.parent_id
left join public.department on user_multiple_relations.value::bigint = department.external_id
left join public.department as department_root on department.parent::integer = department_root.external_id and department_root.external_id != 1
left join public.department as department_root_2 on department_root_2.external_id = department_root.parent::integer and department_root_2.external_id != 1) as departmant_person
where departmant_person.name is not null
) as department_responsible on activity.responsible_id::bigint = department_responsible.external_id
left join (
select 
t0.invoice_external_id,
t0.activity_external_id,
t0.price as price,
t0.deal_external_id,
t0.pay_voucher_date,
t0.invoice_status_name
from (select
invoice.external_id as invoice_external_id,
max(activity.external_id) as activity_external_id,
((json_array_elements((invoice.uf_crm_1707306084::json ->> 'payments')::json)::json) ->> 'amount') as price,
deal.external_id as deal_external_id,
((json_array_elements((invoice.uf_crm_1707306084::json ->> 'payments')::json)::json) ->> 'date') as pay_voucher_date,
status.name as invoice_status_name
from public.deal
left join public.activity on deal.external_id = activity.owner_id and activity.provider_type_id = 'MEETING' and activity.owner_type_id::numeric = 2
left join public."user" as user_assigned on activity.responsible_id::bigint = user_assigned.external_id
left join public.invoice on deal.external_id = invoice.uf_deal_id 
left join public."user" as activiry_creator on activity.author_id::bigint = activiry_creator.external_id
left join public.user_multiple_relations on activiry_creator.external_id = user_multiple_relations.parent_id
left join (
select * from
(select distinct
"user".external_id as external_id,
"user".last_name as last_name,
case 
when "user".last_name = 'Горелова' then 'Внедрение Синтека СПб'
when "user".last_name = 'Зюков' then 'Продажи Синтека СПб'
when "user".last_name = 'Алаторцев' then 'Группа Внедрения ФК СПб'
when department.name = 'Онлайн Внедрение FaceKIT' then 'Группа Внедрения ФК СПб'
when department.name = 'Внедрение Синтека МСК' then 'Внедрение Синтека МСК'
when department.name in ('Группа Внедрения МСК 1', 'Группа Внедрения МСК 2', 'Группа Внедрения МСК 3', 'Группа Внедрения МСК 4') then 'Группа Внедрения ФК МСК'
when department.name in ('Внедрения Синтека СПб 1', 'Внедрения Синтека СПб 2', 'Внедрения Синтека СПб 3', 'Внедрения Синтека СПб 4') then 'Внедрение Синтека СПб'
when department.name in ('Группа Внедрения СПб 1', 'Группа Внедрения СПб 2', 'Группа Внедрения СПб 3', 'Группа Внедрения СПб 4') then 'Группа Внедрения ФК СПб'
else case 
when department_root_2.name is NOT null then department_root_2.name
else case 
when department_root.name is NOT null then department_root.name
else department.name
end
end
end as name
from "user"
left join user_multiple_relations on "user".external_id = user_multiple_relations.parent_id
left join public.department on user_multiple_relations.value::bigint = department.external_id
left join public.department as department_root on department.parent::integer = department_root.external_id and department_root.external_id != 1
left join public.department as department_root_2 on department_root_2.external_id = department_root.parent::integer and department_root_2.external_id != 1) as departmant_person
where departmant_person.name is not null
) as department on activiry_creator.external_id = department.external_id
left join status on invoice.status_id = status.status_id and status.entity_id = 'INVOICE_STATUS'
where 
status.name in ('Оплачен', 'Частично оплачен', 'Отклонён')
and activity.deleted is not true
and invoice.responsible_id = user_assigned.external_id
and department.name in ('Телемаркетинг', 'Маркетинг')
group by deal.external_id, invoice.external_id, status.name, invoice.uf_crm_1706529993, invoice.date_status, invoice.uf_crm_1707306084
) as t0
where price is not null
) as prices_without_duplicates on activity.external_id = prices_without_duplicates.activity_external_id
left join (
select 
t0.invoice_external_id,
t0.activity_external_id,
t0.price as price,
t0.deal_external_id,
t0.pay_voucher_date,
t0.invoice_status_name
from (
select
invoice.external_id as invoice_external_id,
max(activity.external_id) as activity_external_id,
((json_array_elements((invoice.uf_crm_1707306084::json ->> 'payments')::json)::json) ->> 'amount') as price,
deal.external_id as deal_external_id,
((json_array_elements((invoice.uf_crm_1707306084::json ->> 'payments')::json)::json) ->> 'date') as pay_voucher_date,
status.name as invoice_status_name
from public.deal
left join public.activity on deal.external_id = activity.owner_id and activity.provider_type_id = 'MEETING' and activity.owner_type_id::numeric = 2
left join public."user" as user_assigned on activity.responsible_id::bigint = user_assigned.external_id
left join public.invoice on deal.external_id = invoice.uf_deal_id 
left join public."user" as activiry_creator on activity.author_id::bigint = activiry_creator.external_id
left join public.user_multiple_relations on activiry_creator.external_id = user_multiple_relations.parent_id
left join public.department on user_multiple_relations.value::bigint = department.external_id
left join status on invoice.status_id = status.status_id and status.entity_id = 'INVOICE_STATUS'
where 
status.name in ('Оплачен', 'Частично оплачен', 'Отклонён')
and activity.deleted is not true
and invoice.responsible_id = user_assigned.external_id
and deal.external_id not in (
select 
distinct
t0.deal_external_id
from (select
max(activity.external_id) as activity_external_id,
invoice.price as price,
deal.external_id as deal_external_id,
invoice.pay_voucher_date as pay_voucher_date
from public.deal
left join public.activity on deal.external_id = activity.owner_id and activity.provider_type_id = 'MEETING' and activity.owner_type_id::numeric = 2
left join public."user" as user_assigned on activity.responsible_id::bigint = user_assigned.external_id
left join public.invoice on deal.external_id = invoice.uf_deal_id 
left join public."user" as activiry_creator on activity.author_id::bigint = activiry_creator.external_id
left join public.user_multiple_relations on activiry_creator.external_id = user_multiple_relations.parent_id
left join (
select * from
(select distinct
"user".external_id as external_id,
"user".last_name as last_name,
case 
when "user".last_name = 'Горелова' then 'Внедрение Синтека СПб'
when "user".last_name = 'Зюков' then 'Продажи Синтека СПб'
when "user".last_name = 'Алаторцев' then 'Группа Внедрения ФК СПб'
when department.name = 'Онлайн Внедрение FaceKIT' then 'Группа Внедрения ФК СПб'
when department.name = 'Внедрение Синтека МСК' then 'Внедрение Синтека МСК'
when department.name in ('Группа Внедрения МСК 1', 'Группа Внедрения МСК 2', 'Группа Внедрения МСК 3', 'Группа Внедрения МСК 4') then 'Группа Внедрения ФК МСК'
when department.name in ('Внедрения Синтека СПб 1', 'Внедрения Синтека СПб 2', 'Внедрения Синтека СПб 3', 'Внедрения Синтека СПб 4') then 'Внедрение Синтека СПб'
when department.name in ('Группа Внедрения СПб 1', 'Группа Внедрения СПб 2', 'Группа Внедрения СПб 3', 'Группа Внедрения СПб 4') then 'Группа Внедрения ФК СПб'
else case 
when department_root_2.name is NOT null then department_root_2.name
else case 
when department_root.name is NOT null then department_root.name
else department.name
end
end
end as name
from "user"
left join user_multiple_relations on "user".external_id = user_multiple_relations.parent_id
left join public.department on user_multiple_relations.value::bigint = department.external_id
left join public.department as department_root on department.parent::integer = department_root.external_id and department_root.external_id != 1
left join public.department as department_root_2 on department_root_2.external_id = department_root.parent::integer and department_root_2.external_id != 1) as departmant_person
where departmant_person.name is not null
) as department on activiry_creator.external_id = department.external_id
where 
invoice.pay_voucher_date >= activity.deadline
and department.name in ('Телемаркетинг', 'Маркетинг')
and invoice.responsible_id = user_assigned.external_id
group by deal.external_id, invoice.pay_voucher_date, invoice.price
) as t0
where price is not null
group by activity_external_id, deal_external_id, pay_voucher_date
)
group by deal.external_id, invoice.external_id, invoice.pay_voucher_date, invoice.price, status.name, invoice.uf_crm_1706529993, invoice.date_status, invoice.uf_crm_1707306084
) as t0
where price is not null
) as prices_without_duplicates_all on activity.external_id = prices_without_duplicates_all.activity_external_id
left join company on deal.company_id::integer = company.external_id
left join lead on case when company.lead_id = '' then null else company.lead_id::integer end = lead.external_id



left join (
WITH RankedActivities AS (
    SELECT 
        invoice.external_id as invoice_external_id,
        regexp_replace(
            case when uf_crm_1732516279 like '%deal%' then uf_crm_1732516279 else null end, 
            '^https://treesolution\.bitrix24\.ru/crm/deal/details/(\d+)/.*$', 
            '\1'
        ) AS extracted_deal_external_id,
        activiry_creator.last_name,
        activiry_creator.external_id as activiry_creator_external_id,
        activity.external_id as activity_external_id,
        departament.name as departament_name,
        ROW_NUMBER() OVER (PARTITION BY invoice.external_id ORDER BY activity.external_id DESC) AS rn
    FROM invoice 
    LEFT JOIN public.deal ON regexp_replace(case when uf_crm_1732516279 like '%deal%' then uf_crm_1732516279 else null end, '^https://treesolution\.bitrix24\.ru/crm/deal/details/(\d+)/.*$', '\1')::bigint = deal.external_id
    LEFT JOIN public."user" ON case when deal.uf_crm_1522603723 = '' then NULL else deal.uf_crm_1522603723::bigint end = "user".external_id
    LEFT JOIN public.dealcategory ON deal.category_id::bigint = dealcategory.external_id
    LEFT JOIN public.activity ON deal.external_id = activity.owner_id AND activity.provider_type_id = 'MEETING' AND activity.owner_type_id::numeric = 2
    LEFT JOIN public."user" AS activiry_creator ON activity.author_id::bigint = activiry_creator.external_id
    left join (
    select * from
(select distinct
"user".external_id as external_id,
"user".last_name as last_name,
case 
when "user".last_name = 'Горелова' then 'Внедрение Синтека СПб'
when "user".last_name = 'Зюков' then 'Продажи Синтека СПб'
when "user".last_name = 'Алаторцев' then 'Группа Внедрения ФК СПб'
when department.name = 'Онлайн Внедрение FaceKIT' then 'Группа Внедрения ФК СПб'
when department.name = 'Внедрение Синтека МСК' then 'Внедрение Синтека МСК'
when department.name in ('Группа Внедрения МСК 1', 'Группа Внедрения МСК 2', 'Группа Внедрения МСК 3', 'Группа Внедрения МСК 4') then 'Группа Внедрения ФК МСК'
when department.name in ('Внедрения Синтека СПб 1', 'Внедрения Синтека СПб 2', 'Внедрения Синтека СПб 3', 'Внедрения Синтека СПб 4') then 'Внедрение Синтека СПб'
when department.name in ('Группа Внедрения СПб 1', 'Группа Внедрения СПб 2', 'Группа Внедрения СПб 3', 'Группа Внедрения СПб 4') then 'Группа Внедрения ФК СПб'
else case 
when department_root_2.name is NOT null then department_root_2.name
else case 
when department_root.name is NOT null then department_root.name
else department.name
end
end
end as name
from "user"
left join user_multiple_relations on "user".external_id = user_multiple_relations.parent_id
left join public.department on user_multiple_relations.value::bigint = department.external_id
left join public.department as department_root on department.parent::integer = department_root.external_id and department_root.external_id != 1
left join public.department as department_root_2 on department_root_2.external_id = department_root.parent::integer and department_root_2.external_id != 1) as departmant_person
where departmant_person.name is not null
    ) as departament on activiry_creator.external_id = departament.external_id
    WHERE case when uf_crm_1732516279 like '%deal%' then uf_crm_1732516279 else null end IS NOT NULL and departament.name in ('Телемаркетинг', 'Маркетинг')
)
SELECT 
    invoice_external_id,
    extracted_deal_external_id,
    last_name,
    activiry_creator_external_id,
    activity_external_id,
    departament_name
FROM RankedActivities
WHERE rn = 1
ORDER BY invoice_external_id
) invoice_with_money_with_incorrect_deal on invoice_with_money_with_incorrect_deal.invoice_external_id = coalesce(prices_without_duplicates.invoice_external_id, prices_without_duplicates_all.invoice_external_id)


where coalesce(prices_without_duplicates.pay_voucher_date, prices_without_duplicates_all.pay_voucher_date) is not null
and coalesce(prices_without_duplicates.pay_voucher_date, prices_without_duplicates_all.pay_voucher_date) >= '2024-01-01 00:00:00'




union





select 
distinct 
-- activity.external_id as activity_id,
to_char(prices_without_duplicates_all.pay_voucher_date::date, 'YYYY-MM-DD') as meeting_plan_date,
to_char(prices_without_duplicates_all.pay_voucher_date::date, 'MM') as meeting_plan_month,
to_char(prices_without_duplicates_all.pay_voucher_date::date, 'YYYY') as meeting_plan_year,
case 
when invoice_with_money_with_incorrect_deal.invoice_external_id is not null then invoice_with_money_with_incorrect_deal.last_name
else NULL
end as meeting_creator,
payment_creator_name.payment_creator_last_name as assigned_person,
deal.title as deal_title,
deal.external_id as deal_external_id,
concat('https://treesolution.bitrix24.ru/crm/deal/details/', deal.external_id, '/') as url,
null as location,
case 
when TRIM(split_part(dealcategory.name, '-', 1)) = 'Поставщик' then 'Закупай'
else TRIM(split_part(dealcategory.name, '-', 1))
end as product,
null as meeting_fact_date,
null::date as meeting_fact_datetime,
dealcategory_stage.name as dealcategory_stage_name,
NULL as dealcategory_stage_name_history,
dealcategory_stage.external_id as dealcategory_stage_external_id,
case
when status.name is null then 'Прочее'
else status.name
end as deal_type,
null as deal_history,
deal.opportunity as deal_opportunity,
prices_without_duplicates_all.price as price,
prices_without_duplicates_all.invoice_external_id as invoice_external_id,
prices_without_duplicates_all.pay_voucher_date as pay_voucher_date,
case 
when invoice_with_money_with_incorrect_deal.invoice_external_id is not null then invoice_with_money_with_incorrect_deal.departament_name
else NULL 
end as department_name,
case
when status.name like '%Рекомендация%' and TRIM(split_part(dealcategory.name, '-', 1)) = 'Синтека' then 'Продажи Синтека СПб'
when status.name like '%Рекомендация%' and TRIM(split_part(dealcategory.name, '-', 1)) = 'FaceKIT' then 'Продажи FaceKIT/Face'
when status.name like '%Рекомендация%' and TRIM(split_part(dealcategory.name, '-', 1)) = 'FACE' then 'Продажи FaceKIT/Face'
when status.name like '%Рекомендация%' and TRIM(split_part(dealcategory.name, '-', 1)) = 'MySnab' then 'Продажи Закупай/mySnab'
else payment_creator_name.department_responsible_root_name
end as department_responsible_name,
case 
when deal.utm_campaign = 'Неизвестно' then null
else deal.utm_campaign
end as deal_utm_campaign,
coalesce(deal.uf_crm_1556694126, lead.uf_crm_1556694091) as roistat_id,
null as extracted_region,
null as extracted_job_title,
to_char(lead.date_create, 'YYYY-MM-DD') as lead_date_create,
to_char(prices_without_duplicates_all.pay_voucher_date::date, 'YYYY') as pay_voucher_year,
to_char(prices_without_duplicates_all.pay_voucher_date::date, 'MM') as pay_voucher_month,
company.comments as company_comments,
deal.date_create as deal_date_create,
prices_without_duplicates_all.invoice_status_name as invoice_status_name,
null::numeric as deal_history_bool,
case
when prices_without_duplicates_all.pay_voucher_date is null then 0
else 1 
end as pay_voucher_bool,
dealcategory.name as funnel
from public.deal
left join public."user" on case when deal.uf_crm_1522603723 = '' then NULL else deal.uf_crm_1522603723::bigint end = "user".external_id
left join public.dealcategory on deal.category_id::bigint = dealcategory.external_id
left join public.activity on deal.external_id = activity.owner_id and activity.provider_type_id = 'MEETING' and activity.owner_type_id::numeric = 2
left join public."user" as activiry_creator on activity.author_id::bigint = activiry_creator.external_id
left join public.dealcategory_stage on deal.stage_id = dealcategory_stage.status_id
left join public."user" as user_assigned on activity.responsible_id::bigint = user_assigned.external_id
left join public.status on deal.type_id = status.status_id and status.entity_id = 'DEAL_TYPE'
left join public.deal_stagehistory on deal.external_id::bigint = deal_stagehistory.owner_id
left join public.invoice on deal.external_id = invoice.uf_deal_id and invoice.responsible_id = user_assigned.external_id 
left join (
select * from
(select distinct
"user".external_id as external_id,
"user".last_name as last_name,
case 
when "user".last_name = 'Горелова' then 'Внедрение Синтека СПб'
when "user".last_name = 'Зюков' then 'Продажи Синтека СПб'
when "user".last_name = 'Алаторцев' then 'Группа Внедрения ФК СПб'
when department.name = 'Онлайн Внедрение FaceKIT' then 'Группа Внедрения ФК СПб'
when department.name = 'Внедрение Синтека МСК' then 'Внедрение Синтека МСК'
when department.name in ('Группа Внедрения МСК 1', 'Группа Внедрения МСК 2', 'Группа Внедрения МСК 3', 'Группа Внедрения МСК 4') then 'Группа Внедрения ФК МСК'
when department.name in ('Внедрения Синтека СПб 1', 'Внедрения Синтека СПб 2', 'Внедрения Синтека СПб 3', 'Внедрения Синтека СПб 4') then 'Внедрение Синтека СПб'
when department.name in ('Группа Внедрения СПб 1', 'Группа Внедрения СПб 2', 'Группа Внедрения СПб 3', 'Группа Внедрения СПб 4') then 'Группа Внедрения ФК СПб'
else case 
when department_root_2.name is NOT null then department_root_2.name
else case 
when department_root.name is NOT null then department_root.name
else department.name
end
end
end as name
from "user"
left join user_multiple_relations on "user".external_id = user_multiple_relations.parent_id
left join public.department on user_multiple_relations.value::bigint = department.external_id
left join public.department as department_root on department.parent::integer = department_root.external_id and department_root.external_id != 1
left join public.department as department_root_2 on department_root_2.external_id = department_root.parent::integer and department_root_2.external_id != 1) as departmant_person
where departmant_person.name is not null
) as department on activiry_creator.external_id = department.external_id
left join (
select 
t0.invoice_external_id,
t0.activity_external_id,
t0.price as price,
t0.deal_external_id,
t0.pay_voucher_date,
t0.invoice_status_name
from (select
invoice.external_id as invoice_external_id,
max(activity.external_id) as activity_external_id,
((json_array_elements((invoice.uf_crm_1707306084::json ->> 'payments')::json)::json) ->> 'amount') as price,
deal.external_id as deal_external_id,
((json_array_elements((invoice.uf_crm_1707306084::json ->> 'payments')::json)::json) ->> 'date') as pay_voucher_date,
status.name as invoice_status_name
from public.deal
left join public.activity on deal.external_id = activity.owner_id and activity.provider_type_id = 'MEETING' and activity.owner_type_id::numeric = 2
left join public."user" as user_assigned on activity.responsible_id::bigint = user_assigned.external_id
left join public.invoice on deal.external_id = invoice.uf_deal_id 
left join public."user" as activiry_creator on activity.author_id::bigint = activiry_creator.external_id
left join public.user_multiple_relations on activiry_creator.external_id = user_multiple_relations.parent_id
left join public.department on user_multiple_relations.value::bigint = department.external_id
left join status on invoice.status_id = status.status_id and status.entity_id = 'INVOICE_STATUS'
where invoice.responsible_id != user_assigned.external_id
group by deal.external_id, invoice.external_id, status.name, invoice.uf_crm_1706529993, invoice.date_status, invoice.uf_crm_1707306084
) as t0
where price is not null 
) as prices_without_duplicates_all on deal.external_id = prices_without_duplicates_all.deal_external_id
left join (
select 
t0.activity_external_id,
t0.price as price,
t0.deal_external_id,
t0.pay_voucher_date,
t0.payment_creator_last_name,
t0.payment_creator_external_id,
t0.department_responsible_root_name
from (select
max(activity.external_id) as activity_external_id,
((json_array_elements((invoice.uf_crm_1707306084::json ->> 'payments')::json)::json) ->> 'amount') as price,
deal.external_id as deal_external_id,
((json_array_elements((invoice.uf_crm_1707306084::json ->> 'payments')::json)::json) ->> 'date') as pay_voucher_date,
payment_creator.last_name as payment_creator_last_name,
payment_creator.external_id as payment_creator_external_id,
case 
when payment_creator.last_name = 'Горелова' then 'Внедрение Синтека СПб'
when payment_creator.last_name = 'Зюков' then 'Внедрение Синтека СПб'
when payment_creator.last_name = 'Алаторцев' then 'Группа Внедрения ФК СПб'
when department_responsible.name = 'Онлайн Внедрение FaceKIT' then 'Группа Внедрения ФК СПб'
when department_responsible.name = 'Внедрение Синтека МСК' then 'Внедрение Синтека МСК'
when department_responsible.name in ('Группа Внедрения МСК 1', 'Группа Внедрения МСК 2', 'Группа Внедрения МСК 3', 'Группа Внедрения МСК 4') then 'Группа Внедрения ФК МСК'
when department_responsible.name in ('Внедрения Синтека СПб 1', 'Внедрения Синтека СПб 2', 'Внедрения Синтека СПб 3', 'Внедрения Синтека СПб 4') then 'Внедрение Синтека СПб'
when department_responsible.name in ('Группа Внедрения СПб 1', 'Группа Внедрения СПб 2', 'Группа Внедрения СПб 3', 'Группа Внедрения СПб 4') then 'Группа Внедрения ФК СПб'
else case 
when department_responsible_root_2.name is NOT null then department_responsible_root_2.name
else case 
when department_responsible_root.name is NOT null then department_responsible_root.name
else department_responsible.name
end
end
end as department_responsible_root_name
from public.deal
left join public.activity on deal.external_id = activity.owner_id and activity.provider_type_id = 'MEETING' and activity.owner_type_id::numeric = 2
left join public."user" as user_assigned on activity.responsible_id::bigint = user_assigned.external_id
left join public.invoice on deal.external_id = invoice.uf_deal_id 
left join public."user" as payment_creator on invoice.responsible_id = payment_creator.external_id
left join public.user_multiple_relations as user_multiple_relations_responsible on payment_creator.external_id = user_multiple_relations_responsible.parent_id
left join public.department as department_responsible on user_multiple_relations_responsible.value::bigint = department_responsible.external_id
left join public.department as department_responsible_root on department_responsible_root.external_id = department_responsible.parent::integer and department_responsible_root.external_id != 1
left join public.department as department_responsible_root_2 on department_responsible_root_2.external_id = department_responsible_root.parent::integer and department_responsible_root_2.external_id != 1
group by deal.external_id, invoice.pay_voucher_date, invoice.price, payment_creator.last_name, payment_creator.external_id, department_responsible_root.external_id, department_responsible.external_id, department_responsible_root.name, department_responsible.name, department_responsible_root_2.external_id, department_responsible_root_2.name, invoice.uf_crm_1707306084
) as t0
where price is not null and department_responsible_root_name <> 'Обработка данных'
) as payment_creator_name on payment_creator_name.deal_external_id = deal.external_id and to_char(payment_creator_name.pay_voucher_date::date, 'YYYY-MM-DD') = to_char(prices_without_duplicates_all.pay_voucher_date::date, 'YYYY-MM-DD')
left join (
select distinct
user_multiple_relations_responsible.parent_id,
case
when department_responsible_root.external_id is null then department_responsible.external_id
else department_responsible_root.external_id
end as department_responsible_external_id,
case 
when department_responsible_root.name is null then department_responsible.name
else department_responsible_root.name
end as department_responsible_root_name
from public.deal
left join public."user" on case when deal.uf_crm_1522603723 = '' then NULL else deal.uf_crm_1522603723::bigint end = "user".external_id
left join public.dealcategory on deal.category_id::bigint = dealcategory.external_id
left join public.activity on deal.external_id = activity.owner_id and activity.provider_type_id = 'MEETING' and activity.owner_type_id::numeric = 2
left join public."user" as activiry_creator on activity.author_id::bigint = activiry_creator.external_id
left join public.dealcategory_stage on deal.stage_id = dealcategory_stage.status_id
left join public."user" as user_assigned on activity.responsible_id::bigint = user_assigned.external_id
left join public.status on deal.type_id = status.status_id and status.entity_id = 'DEAL_TYPE'
left join public.deal_stagehistory on deal.external_id::bigint = deal_stagehistory.owner_id
left join public.invoice on deal.external_id = invoice.uf_deal_id and invoice.responsible_id = user_assigned.external_id 
left join public.user_multiple_relations on activiry_creator.external_id = user_multiple_relations.parent_id
left join public.department on user_multiple_relations.value::bigint = department.external_id
left join public.user_multiple_relations as user_multiple_relations_responsible on activity.responsible_id::bigint = user_multiple_relations_responsible.parent_id
left join public.department as department_responsible on user_multiple_relations_responsible.value::bigint = department_responsible.external_id
left join public.department as department_responsible_root on department_responsible_root.external_id = department_responsible.parent::integer and department_responsible_root.external_id != 1
) as department_responsible on payment_creator_name.payment_creator_external_id = department_responsible.parent_id
left join company on deal.company_id::integer = company.external_id
left join lead on case when company.lead_id = '' then null else company.lead_id::integer end = lead.external_id
left join (
WITH RankedActivities AS (
    SELECT 
        invoice.external_id as invoice_external_id,
        regexp_replace(
            case when uf_crm_1732516279 like '%deal%' then uf_crm_1732516279 else null end, 
            '^https://treesolution\.bitrix24\.ru/crm/deal/details/(\d+)/.*$', 
            '\1'
        ) AS extracted_deal_external_id,
        activiry_creator.last_name,
        activiry_creator.external_id as activiry_creator_external_id,
        activity.external_id as activity_external_id,
        departament.name as departament_name,
        ROW_NUMBER() OVER (PARTITION BY invoice.external_id ORDER BY activity.external_id DESC) AS rn
    FROM invoice 
    LEFT JOIN public.deal ON regexp_replace(case when uf_crm_1732516279 like '%deal%' then uf_crm_1732516279 else null end, '^https://treesolution\.bitrix24\.ru/crm/deal/details/(\d+)/.*$', '\1')::bigint = deal.external_id
    LEFT JOIN public."user" ON case when deal.uf_crm_1522603723 = '' then NULL else deal.uf_crm_1522603723::bigint end = "user".external_id
    LEFT JOIN public.dealcategory ON deal.category_id::bigint = dealcategory.external_id
    LEFT JOIN public.activity ON deal.external_id = activity.owner_id AND activity.provider_type_id = 'MEETING' AND activity.owner_type_id::numeric = 2
    LEFT JOIN public."user" AS activiry_creator ON activity.author_id::bigint = activiry_creator.external_id
    left join (
    select * from
(select distinct
"user".external_id as external_id,
"user".last_name as last_name,
case 
when "user".last_name = 'Горелова' then 'Внедрение Синтека СПб'
when "user".last_name = 'Зюков' then 'Продажи Синтека СПб'
when "user".last_name = 'Алаторцев' then 'Группа Внедрения ФК СПб'
when department.name = 'Онлайн Внедрение FaceKIT' then 'Группа Внедрения ФК СПб'
when department.name = 'Внедрение Синтека МСК' then 'Внедрение Синтека МСК'
when department.name in ('Группа Внедрения МСК 1', 'Группа Внедрения МСК 2', 'Группа Внедрения МСК 3', 'Группа Внедрения МСК 4') then 'Группа Внедрения ФК МСК'
when department.name in ('Внедрения Синтека СПб 1', 'Внедрения Синтека СПб 2', 'Внедрения Синтека СПб 3', 'Внедрения Синтека СПб 4') then 'Внедрение Синтека СПб'
when department.name in ('Группа Внедрения СПб 1', 'Группа Внедрения СПб 2', 'Группа Внедрения СПб 3', 'Группа Внедрения СПб 4') then 'Группа Внедрения ФК СПб'
else case 
when department_root_2.name is NOT null then department_root_2.name
else case 
when department_root.name is NOT null then department_root.name
else department.name
end
end
end as name
from "user"
left join user_multiple_relations on "user".external_id = user_multiple_relations.parent_id
left join public.department on user_multiple_relations.value::bigint = department.external_id
left join public.department as department_root on department.parent::integer = department_root.external_id and department_root.external_id != 1
left join public.department as department_root_2 on department_root_2.external_id = department_root.parent::integer and department_root_2.external_id != 1) as departmant_person
where departmant_person.name is not null
    ) as departament on activiry_creator.external_id = departament.external_id
    WHERE case when uf_crm_1732516279 like '%deal%' then uf_crm_1732516279 else null end IS NOT NULL and departament.name in ('Телемаркетинг', 'Маркетинг')
)
SELECT 
    invoice_external_id,
    extracted_deal_external_id,
    last_name,
    activiry_creator_external_id,
    activity_external_id,
    departament_name
FROM RankedActivities
WHERE rn = 1
ORDER BY invoice_external_id
) invoice_with_money_with_incorrect_deal on invoice_with_money_with_incorrect_deal.invoice_external_id = prices_without_duplicates_all.invoice_external_id
where prices_without_duplicates_all.pay_voucher_date is not null
and to_char(prices_without_duplicates_all.pay_voucher_date::date, 'YYYY-MM-DD') >= '2024-01-01'
and prices_without_duplicates_all.invoice_external_id not in  (
select 
distinct 
coalesce(prices_without_duplicates.invoice_external_id, prices_without_duplicates_all.invoice_external_id) as invoice_external_id
from public.deal
left join public."user" on case when deal.uf_crm_1522603723 = '' then NULL else deal.uf_crm_1522603723::bigint end = "user".external_id
left join public.dealcategory on deal.category_id::bigint = dealcategory.external_id
left join public.activity on deal.external_id = activity.owner_id and activity.provider_type_id = 'MEETING' and activity.owner_type_id::numeric = 2
left join public."user" as activiry_creator on activity.author_id::bigint = activiry_creator.external_id
left join public.dealcategory_stage on deal.stage_id = dealcategory_stage.status_id
left join public."user" as user_assigned on activity.responsible_id::bigint = user_assigned.external_id
left join public.status on deal.type_id = status.status_id and status.entity_id = 'DEAL_TYPE'
left join public.deal_stagehistory on deal.external_id::bigint = deal_stagehistory.owner_id
left join public.invoice on deal.external_id = invoice.uf_deal_id and invoice.responsible_id = user_assigned.external_id 
left join (
select * from
(select distinct
"user".external_id as external_id,
"user".last_name as last_name,
case 
when "user".last_name = 'Горелова' then 'Внедрение Синтека СПб'
when "user".last_name = 'Зюков' then 'Продажи Синтека СПб'
when "user".last_name = 'Алаторцев' then 'Группа Внедрения ФК СПб'
when department.name = 'Онлайн Внедрение FaceKIT' then 'Группа Внедрения ФК СПб'
when department.name = 'Внедрение Синтека МСК' then 'Внедрение Синтека МСК'
when department.name in ('Группа Внедрения МСК 1', 'Группа Внедрения МСК 2', 'Группа Внедрения МСК 3', 'Группа Внедрения МСК 4') then 'Группа Внедрения ФК МСК'
when department.name in ('Внедрения Синтека СПб 1', 'Внедрения Синтека СПб 2', 'Внедрения Синтека СПб 3', 'Внедрения Синтека СПб 4') then 'Внедрение Синтека СПб'
when department.name in ('Группа Внедрения СПб 1', 'Группа Внедрения СПб 2', 'Группа Внедрения СПб 3', 'Группа Внедрения СПб 4') then 'Группа Внедрения ФК СПб'
else case 
when department_root_2.name is NOT null then department_root_2.name
else case 
when department_root.name is NOT null then department_root.name
else department.name
end
end
end as name
from "user"
left join user_multiple_relations on "user".external_id = user_multiple_relations.parent_id
left join public.department on user_multiple_relations.value::bigint = department.external_id
left join public.department as department_root on department.parent::integer = department_root.external_id and department_root.external_id != 1
left join public.department as department_root_2 on department_root_2.external_id = department_root.parent::integer and department_root_2.external_id != 1) as departmant_person
where departmant_person.name is not null
) as department on activiry_creator.external_id = department.external_id
left join (
select * from
(select distinct
"user".external_id as external_id,
"user".last_name as last_name,
case 
when "user".last_name = 'Горелова' then 'Внедрение Синтека СПб'
when "user".last_name = 'Зюков' then 'Продажи Синтека СПб'
when "user".last_name = 'Алаторцев' then 'Группа Внедрения ФК СПб'
when department.name = 'Онлайн Внедрение FaceKIT' then 'Группа Внедрения ФК СПб'
when department.name = 'Внедрение Синтека МСК' then 'Внедрение Синтека МСК'
when department.name in ('Группа Внедрения МСК 1', 'Группа Внедрения МСК 2', 'Группа Внедрения МСК 3', 'Группа Внедрения МСК 4') then 'Группа Внедрения ФК МСК'
when department.name in ('Внедрения Синтека СПб 1', 'Внедрения Синтека СПб 2', 'Внедрения Синтека СПб 3', 'Внедрения Синтека СПб 4') then 'Внедрение Синтека СПб'
when department.name in ('Группа Внедрения СПб 1', 'Группа Внедрения СПб 2', 'Группа Внедрения СПб 3', 'Группа Внедрения СПб 4') then 'Группа Внедрения ФК СПб'
else case 
when department_root_2.name is NOT null then department_root_2.name
else case 
when department_root.name is NOT null then department_root.name
else department.name
end
end
end as name
from "user"
left join user_multiple_relations on "user".external_id = user_multiple_relations.parent_id
left join public.department on user_multiple_relations.value::bigint = department.external_id
left join public.department as department_root on department.parent::integer = department_root.external_id and department_root.external_id != 1
left join public.department as department_root_2 on department_root_2.external_id = department_root.parent::integer and department_root_2.external_id != 1) as departmant_person
where departmant_person.name is not null
) as department_responsible on activity.responsible_id::bigint = department_responsible.external_id
left join (
select 
t0.invoice_external_id,
t0.activity_external_id,
t0.price as price,
t0.deal_external_id,
t0.pay_voucher_date,
t0.invoice_status_name
from (select
invoice.external_id as invoice_external_id,
max(activity.external_id) as activity_external_id,
((json_array_elements((invoice.uf_crm_1707306084::json ->> 'payments')::json)::json) ->> 'amount') as price,
deal.external_id as deal_external_id,
((json_array_elements((invoice.uf_crm_1707306084::json ->> 'payments')::json)::json) ->> 'date') as pay_voucher_date,
status.name as invoice_status_name
from public.deal
left join public.activity on deal.external_id = activity.owner_id and activity.provider_type_id = 'MEETING' and activity.owner_type_id::numeric = 2
left join public."user" as user_assigned on activity.responsible_id::bigint = user_assigned.external_id
left join public.invoice on deal.external_id = invoice.uf_deal_id 
left join public."user" as activiry_creator on activity.author_id::bigint = activiry_creator.external_id
left join public.user_multiple_relations on activiry_creator.external_id = user_multiple_relations.parent_id
left join public.department on user_multiple_relations.value::bigint = department.external_id
left join status on invoice.status_id = status.status_id and status.entity_id = 'INVOICE_STATUS'
where 
status.name in ('Оплачен', 'Частично оплачен', 'Отклонён')
and activity.deleted is not true
and invoice.responsible_id = user_assigned.external_id
and department.name in ('Телемаркетинг', 'Маркетинг')
group by deal.external_id, invoice.external_id, status.name, invoice.uf_crm_1706529993, invoice.date_status, invoice.uf_crm_1707306084
) as t0
where price is not null
) as prices_without_duplicates on activity.external_id = prices_without_duplicates.activity_external_id
left join (
select 
t0.invoice_external_id,
t0.activity_external_id,
t0.price as price,
t0.deal_external_id,
t0.pay_voucher_date,
t0.invoice_status_name
from (
select
invoice.external_id as invoice_external_id,
max(activity.external_id) as activity_external_id,
((json_array_elements((invoice.uf_crm_1707306084::json ->> 'payments')::json)::json) ->> 'amount') as price,
deal.external_id as deal_external_id,
((json_array_elements((invoice.uf_crm_1707306084::json ->> 'payments')::json)::json) ->> 'date') as pay_voucher_date,
status.name as invoice_status_name
from public.deal
left join public.activity on deal.external_id = activity.owner_id and activity.provider_type_id = 'MEETING' and activity.owner_type_id::numeric = 2
left join public."user" as user_assigned on activity.responsible_id::bigint = user_assigned.external_id
left join public.invoice on deal.external_id = invoice.uf_deal_id 
left join public."user" as activiry_creator on activity.author_id::bigint = activiry_creator.external_id
left join public.user_multiple_relations on activiry_creator.external_id = user_multiple_relations.parent_id
left join public.department on user_multiple_relations.value::bigint = department.external_id
left join status on invoice.status_id = status.status_id and status.entity_id = 'INVOICE_STATUS'
where 
status.name in ('Оплачен', 'Частично оплачен', 'Отклонён')
and activity.deleted is not true
and invoice.responsible_id = user_assigned.external_id
and deal.external_id not in (
select 
distinct
t0.deal_external_id
from (select
max(activity.external_id) as activity_external_id,
invoice.price as price,
deal.external_id as deal_external_id,
invoice.pay_voucher_date as pay_voucher_date
from public.deal
left join public.activity on deal.external_id = activity.owner_id and activity.provider_type_id = 'MEETING' and activity.owner_type_id::numeric = 2
left join public."user" as user_assigned on activity.responsible_id::bigint = user_assigned.external_id
left join public.invoice on deal.external_id = invoice.uf_deal_id 
left join public."user" as activiry_creator on activity.author_id::bigint = activiry_creator.external_id
left join public.user_multiple_relations on activiry_creator.external_id = user_multiple_relations.parent_id
left join public.department on user_multiple_relations.value::bigint = department.external_id
where 
invoice.pay_voucher_date >= activity.deadline
and department.name in ('Телемаркетинг', 'Маркетинг')
and invoice.responsible_id = user_assigned.external_id
group by deal.external_id, invoice.pay_voucher_date, invoice.price
) as t0
where price is not null
group by activity_external_id, deal_external_id, pay_voucher_date
)
group by deal.external_id, invoice.external_id, invoice.pay_voucher_date, invoice.price, status.name, invoice.uf_crm_1706529993, invoice.date_status, invoice.uf_crm_1707306084
) as t0
where price is not null
) as prices_without_duplicates_all on activity.external_id = prices_without_duplicates_all.activity_external_id
left join company on deal.company_id::integer = company.external_id
left join lead on case when company.lead_id = '' then null else company.lead_id::integer end = lead.external_id
where coalesce(prices_without_duplicates.pay_voucher_date, prices_without_duplicates_all.pay_voucher_date) is not null
and coalesce(prices_without_duplicates.pay_voucher_date, prices_without_duplicates_all.pay_voucher_date) >= '2024-01-01 00:00:00'
)
and prices_without_duplicates_all.invoice_external_id not in (
select 
distinct 
coalesce(prices_without_duplicates.invoice_external_id, prices_without_duplicates_all.invoice_external_id) as invoice_external_id
from public.deal
left join public."user" on case when deal.uf_crm_1522603723 = '' then NULL else deal.uf_crm_1522603723::bigint end = "user".external_id
left join public.dealcategory on deal.category_id::bigint = dealcategory.external_id
left join public.activity on deal.external_id = activity.owner_id and activity.provider_type_id = 'MEETING' and activity.owner_type_id::numeric = 2
left join public."user" as activiry_creator on activity.author_id::bigint = activiry_creator.external_id
left join public.dealcategory_stage on deal.stage_id = dealcategory_stage.status_id
left join public."user" as user_assigned on activity.responsible_id::bigint = user_assigned.external_id
left join public.status on deal.type_id = status.status_id and status.entity_id = 'DEAL_TYPE'
left join public.deal_stagehistory on deal.external_id::bigint = deal_stagehistory.owner_id
left join public.invoice on deal.external_id = invoice.uf_deal_id and invoice.responsible_id = user_assigned.external_id 
left join (
select * from
(select distinct
"user".external_id as external_id,
"user".last_name as last_name,
case 
when "user".last_name = 'Горелова' then 'Внедрение Синтека СПб'
when "user".last_name = 'Зюков' then 'Продажи Синтека СПб'
when "user".last_name = 'Алаторцев' then 'Группа Внедрения ФК СПб'
when department.name = 'Онлайн Внедрение FaceKIT' then 'Группа Внедрения ФК СПб'
when department.name = 'Внедрение Синтека МСК' then 'Внедрение Синтека МСК'
when department.name in ('Группа Внедрения МСК 1', 'Группа Внедрения МСК 2', 'Группа Внедрения МСК 3', 'Группа Внедрения МСК 4') then 'Группа Внедрения ФК МСК'
when department.name in ('Внедрения Синтека СПб 1', 'Внедрения Синтека СПб 2', 'Внедрения Синтека СПб 3', 'Внедрения Синтека СПб 4') then 'Внедрение Синтека СПб'
when department.name in ('Группа Внедрения СПб 1', 'Группа Внедрения СПб 2', 'Группа Внедрения СПб 3', 'Группа Внедрения СПб 4') then 'Группа Внедрения ФК СПб'
else case 
when department_root_2.name is NOT null then department_root_2.name
else case 
when department_root.name is NOT null then department_root.name
else department.name
end
end
end as name
from "user"
left join user_multiple_relations on "user".external_id = user_multiple_relations.parent_id
left join public.department on user_multiple_relations.value::bigint = department.external_id
left join public.department as department_root on department.parent::integer = department_root.external_id and department_root.external_id != 1
left join public.department as department_root_2 on department_root_2.external_id = department_root.parent::integer and department_root_2.external_id != 1) as departmant_person
where departmant_person.name is not null
) as department on activiry_creator.external_id = department.external_id
left join (
select * from
(select distinct
"user".external_id as external_id,
"user".last_name as last_name,
case 
when "user".last_name = 'Горелова' then 'Внедрение Синтека СПб'
when "user".last_name = 'Зюков' then 'Продажи Синтека СПб'
when "user".last_name = 'Алаторцев' then 'Группа Внедрения ФК СПб'
when department.name = 'Онлайн Внедрение FaceKIT' then 'Группа Внедрения ФК СПб'
when department.name = 'Внедрение Синтека МСК' then 'Внедрение Синтека МСК'
when department.name in ('Группа Внедрения МСК 1', 'Группа Внедрения МСК 2', 'Группа Внедрения МСК 3', 'Группа Внедрения МСК 4') then 'Группа Внедрения ФК МСК'
when department.name in ('Внедрения Синтека СПб 1', 'Внедрения Синтека СПб 2', 'Внедрения Синтека СПб 3', 'Внедрения Синтека СПб 4') then 'Внедрение Синтека СПб'
when department.name in ('Группа Внедрения СПб 1', 'Группа Внедрения СПб 2', 'Группа Внедрения СПб 3', 'Группа Внедрения СПб 4') then 'Группа Внедрения ФК СПб'
else case 
when department_root_2.name is NOT null then department_root_2.name
else case 
when department_root.name is NOT null then department_root.name
else department.name
end
end
end as name
from "user"
left join user_multiple_relations on "user".external_id = user_multiple_relations.parent_id
left join public.department on user_multiple_relations.value::bigint = department.external_id
left join public.department as department_root on department.parent::integer = department_root.external_id and department_root.external_id != 1
left join public.department as department_root_2 on department_root_2.external_id = department_root.parent::integer and department_root_2.external_id != 1) as departmant_person
where departmant_person.name is not null
) as department_responsible on activity.responsible_id::bigint = department_responsible.external_id
left join (
select 
t0.invoice_external_id,
t0.activity_external_id,
t0.price as price,
t0.deal_external_id,
t0.pay_voucher_date,
t0.invoice_status_name
from (select
invoice.external_id as invoice_external_id,
max(activity.external_id) as activity_external_id,
((json_array_elements((invoice.uf_crm_1707306084::json ->> 'payments')::json)::json) ->> 'amount') as price,
deal.external_id as deal_external_id,
((json_array_elements((invoice.uf_crm_1707306084::json ->> 'payments')::json)::json) ->> 'date') as pay_voucher_date,
status.name as invoice_status_name
from public.deal
left join public.activity on deal.external_id = activity.owner_id and activity.provider_type_id = 'MEETING' and activity.owner_type_id::numeric = 2
left join public."user" as user_assigned on activity.responsible_id::bigint = user_assigned.external_id
left join public.invoice on deal.external_id = invoice.uf_deal_id 
left join public."user" as activiry_creator on activity.author_id::bigint = activiry_creator.external_id
left join public.user_multiple_relations on activiry_creator.external_id = user_multiple_relations.parent_id
left join public.department on user_multiple_relations.value::bigint = department.external_id
left join status on invoice.status_id = status.status_id and status.entity_id = 'INVOICE_STATUS'
where 
status.name in ('Оплачен', 'Частично оплачен', 'Отклонён')
and activity.deleted is not true
and invoice.responsible_id = user_assigned.external_id
and department.name in ('Телемаркетинг', 'Маркетинг')
group by deal.external_id, invoice.external_id, status.name, invoice.uf_crm_1706529993, invoice.date_status, invoice.uf_crm_1707306084
) as t0
where price is not null
) as prices_without_duplicates on activity.external_id = prices_without_duplicates.activity_external_id
left join (
select 
t0.invoice_external_id,
t0.activity_external_id,
t0.price as price,
t0.deal_external_id,
t0.pay_voucher_date,
t0.invoice_status_name
from (
select
invoice.external_id as invoice_external_id,
max(activity.external_id) as activity_external_id,
((json_array_elements((invoice.uf_crm_1707306084::json ->> 'payments')::json)::json) ->> 'amount') as price,
deal.external_id as deal_external_id,
((json_array_elements((invoice.uf_crm_1707306084::json ->> 'payments')::json)::json) ->> 'date') as pay_voucher_date,
status.name as invoice_status_name
from public.deal
left join public.activity on deal.external_id = activity.owner_id and activity.provider_type_id = 'MEETING' and activity.owner_type_id::numeric = 2
left join public."user" as user_assigned on activity.responsible_id::bigint = user_assigned.external_id
left join public.invoice on deal.external_id = invoice.uf_deal_id 
left join public."user" as activiry_creator on activity.author_id::bigint = activiry_creator.external_id
left join public.user_multiple_relations on activiry_creator.external_id = user_multiple_relations.parent_id
left join public.department on user_multiple_relations.value::bigint = department.external_id
left join status on invoice.status_id = status.status_id and status.entity_id = 'INVOICE_STATUS'
where 
status.name in ('Оплачен', 'Частично оплачен', 'Отклонён')
and activity.deleted is not true
and invoice.responsible_id = user_assigned.external_id
and deal.external_id not in (
select 
distinct
t0.deal_external_id
from (select
max(activity.external_id) as activity_external_id,
invoice.price as price,
deal.external_id as deal_external_id,
invoice.pay_voucher_date as pay_voucher_date
from public.deal
left join public.activity on deal.external_id = activity.owner_id and activity.provider_type_id = 'MEETING' and activity.owner_type_id::numeric = 2
left join public."user" as user_assigned on activity.responsible_id::bigint = user_assigned.external_id
left join public.invoice on deal.external_id = invoice.uf_deal_id 
left join public."user" as activiry_creator on activity.author_id::bigint = activiry_creator.external_id
left join public.user_multiple_relations on activiry_creator.external_id = user_multiple_relations.parent_id
left join public.department on user_multiple_relations.value::bigint = department.external_id
where 
invoice.pay_voucher_date >= activity.deadline
and activity.deleted is not true
and department.name in ('Телемаркетинг', 'Маркетинг')
and invoice.responsible_id = user_assigned.external_id
group by deal.external_id, invoice.pay_voucher_date, invoice.price
) as t0
where price is not null
group by activity_external_id, deal_external_id, pay_voucher_date
)
group by deal.external_id, invoice.external_id, invoice.pay_voucher_date, invoice.price, status.name, invoice.uf_crm_1706529993, invoice.date_status, invoice.uf_crm_1707306084
) as t0
where price is not null
) as prices_without_duplicates_all on activity.external_id = prices_without_duplicates_all.activity_external_id
left join company on deal.company_id::integer = company.external_id
left join lead on case when company.lead_id = '' then null else company.lead_id::integer end = lead.external_id
where coalesce(prices_without_duplicates.pay_voucher_date, prices_without_duplicates_all.pay_voucher_date) is not null
and coalesce(prices_without_duplicates.pay_voucher_date, prices_without_duplicates_all.pay_voucher_date) >= '2024-01-01 00:00:00'
)
and prices_without_duplicates_all.invoice_external_id not in (58423, 55885, 58613, 58615, 59053)
) as t1 
left join (




select distinct
(roistat.json_data::json ->> 'fields_data')::json ->> 'roistat' as roistat_id,
string_agg(((((roistat.json_data::json ->> 'visit')::json ->> 'marker_info')::jsonb)->0)::json ->> 'alias', ', ') as marker_info
from roistat
group by (roistat.json_data::json ->> 'fields_data')::json ->> 'roistat'



) as roistat_metrics on t1.roistat_id = roistat_metrics.roistat_id
where meeting_plan_date is not null 
