{{ config(materialized='table', tag = ['edw_staging']) }}

with
    charges as (
        select
            cast(chargtyp.hmy as smallint) as chargecodehmy,
            chargtyp.scode,
            chargtyp.sname,
            rtrim(acct.scode) as accountscode,
            'NewCo Yardi' as rowsourcesystem
        from {{ source('edw_staging', 'CHARGTYP') }} as chargtyp
        inner join {{ source('edw_staging', 'ACCT') }} as acct
            on chargtyp.hchargebackacct = acct.hmy
    ),

    charge_lookup as (
        select chargecodehmy, rowsourcesystem
        from {{ this }}
        where lower(rowsourcesystem) = lower('NewCo Yardi')
    )

select
    c.chargecodehmy,
    c.rowsourcesystem,
    c.scode as chargecode_source,
    c.sname as chargename_source,
    cast(null as varchar(25)) as chargecode_consolidated,
    cast(null as varchar(50)) as chargename_consolidated,
    cast(current_timestamp as datetime) as insertdatetime,
    cast(current_timestamp as datetime) as updatedatetime,
    rtrim(c.accountscode) as generalledgeraccount
from charges c
left join
    charge_lookup cl
    on cl.chargecodehmy = c.chargecodehmy
    and cl.rowsourcesystem = c.rowsourcesystem
where cl.chargecodehmy is null
