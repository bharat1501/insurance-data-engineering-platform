{% snapshot snap_customer %}

{{
    config(
        unique_key='CUSTOMER_ID',
        strategy='check',
        check_cols=[
            'FIRST_NAME',
            'LAST_NAME',
            'DATE_OF_BIRTH',
            'EMAIL',
            'PHONE',
            'ADDRESS',
            'CITY',
            'STATE',
            'CUSTOMER_TYPE'
        ],
        schema='DBT_CURATED'
    )
}}

SELECT *
FROM {{ ref('stg_customer') }}
WHERE UPPER(STAGING_STATUS) = 'VALID'

{% endsnapshot %}
