{{ config(
    materialized='incremental',
    unique_key='ChargeCodeSPK',
    on_schema_change='ignore'
) }}


with
    stg_chargecodemap as (
        select
            cast(
                case
                    when rowsourcesystem = 'SWAY Yardi'
                    then chargecodehmy * - 1
                    else chargecodehmy
                end as smallint
            ) as chargecodespk,
            rowsourcesystem,
            lower(rtrim(chargecode_source)) as chargecode,
            coalesce(
                chargename_consolidated, chargename_source, 'Unavailable'
            ) as chargename
        from {{ ref("chargecodemap") }}
    ),
    dimcharge_lookup as (select chargecodespk from {{ this }})
select
    row_number() over (order by tgt.chargecodespk) as dimchargewid,
    tgt.chargecodespk,
    tgt.chargecode,
    cast(tgt.chargename as varchar(16777216)) as chargename,
    tgt.rowsourcesystem,
    cast(current_timestamp as datetime) as insertdatetime, 
    cast(current_timestamp as datetime) as updatedatetime
from stg_chargecodemap tgt
left join dimcharge_lookup dl on dl.chargecodespk = tgt.chargecodespk
where dl.chargecodespk is null