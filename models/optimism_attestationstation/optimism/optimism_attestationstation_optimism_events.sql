{{ config(
    alias = 'events',
    partition_by = ['block_date'],
    materialized = 'incremental',
    file_format = 'delta',
    incremental_strategy = 'merge',
    unique_key = ['block_time', 'tx_hash', 'evt_index'],
    post_hook='{{ expose_spells(\'["optimism"]\',
                                "project",
                                "optimism_attestationstation",
                                \'["chuxin"]\') }}'
    )
}}
select 
    date_trunc('day', evt_block_time) as block_date
    ,evt_tx_hash as tx_hash
    ,evt_block_number as block_number
    ,evt_block_time as block_time
    ,evt_index
    ,about as recipient
    ,creator as issuer
    ,contract_address
    ,key as key_raw
    ,decode(
        unhex(
          if (
            substring(key, 1, 6) in ("0xab7e", "0x9e43"),
            hex(key),
            substring(key, 3)
          )
        ),
        "utf8"
      ) as key
    ,val as val_raw
    ,split(unhex(substring(val, 3)), ",") as val
from {{source('attestationstation_optimism','AttestationStation_evt_AttestationCreated')}}
where 
    true
    {% if is_incremental() %}
    and evt_block_time >= date_trunc('day', now() - interval '1 week')
    {% endif %}