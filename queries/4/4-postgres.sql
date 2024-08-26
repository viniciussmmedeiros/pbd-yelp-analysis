-- Query 4

-- portuguese:
-- Para cada dado de 'checkin' na base 'checkin', analisar os registros relacionando-os com os estabelecimentos da base 'business' e atualizar os documentos de estabelecimento com o horário mais movimentado e o menos movimentado. Sendo possível que não haja checkins registrados para um estabelecimento, ou que as quantidades de checkins sejam iguais para diferentes horários, podendo resultar em valores nulos ou iguais para os horários mais e menos movimentados.
-- O negócio de id '00rY5F9ltW-IWf2Ev96kOg' foi escolhido para exemplificar a atualização dos horários mais e menos movimentados, pois possui centenas de checkins registrados.

-- english:
-- For each 'checkin' data in the 'checkin' table, analyze the records relating them to the businesses in the 'business' table and update the business documents with the busiest and least busy hours. It is possible that there are no check-ins registered for a business, or that the number of check-ins is the same for different hours, which may result in null or equal values for the busiest and least busy hours.
-- The business with id '00rY5F9ltW-IWf2Ev96kOg' was chosen to exemplify the update of the busiest and least busy hours, as it has hundreds of check-ins registered.

-- CTE para agrupar e contar os checkins por estabelecimento e horário
-- CTE to group and count the checkins by business and hour
WITH checkin_distribution AS (
    SELECT
        checkin_data->>'business_id' AS business_id,
        EXTRACT(HOUR FROM (unnest(string_to_array(checkin_data->>'date', ',')))::timestamp) AS checkin_hour,
        COUNT(*) AS checkin_count
    FROM checkin
    WHERE checkin_data->>'business_id' = '00rY5F9ltW-IWf2Ev96kOg'
    GROUP BY checkin_data->>'business_id', checkin_hour
),

-- CTE para encontrar o horário mais movimentado por estabelecimento
-- CTE to find the busiest hour by business
busiest_hours AS (
    SELECT
        business_id,
        checkin_hour AS busiest_hour,
        checkin_count AS max_checkins
    FROM (
        SELECT 
            business_id, 
            checkin_hour, 
            checkin_count,
            ROW_NUMBER() OVER (PARTITION BY business_id ORDER BY checkin_count DESC) AS rn
        FROM checkin_distribution
    )
    WHERE rn = 1
),

-- CTE para encontrar o horário menos movimentado por estabelecimento
-- CTE to find the least busy hour by business
least_busy_hours AS (
    SELECT
        business_id,
        checkin_hour AS least_busy_hour,
        checkin_count AS min_checkins
    FROM (
        SELECT 
            business_id, 
            checkin_hour, 
            checkin_count,
            ROW_NUMBER() OVER (PARTITION BY business_id ORDER BY checkin_count ASC) AS rn
        FROM checkin_distribution
    )
    WHERE rn = 1
),

-- CTE para unir os horários mais e menos movimentados por estabelecimento
-- CTE to join the busiest and least busy hours by business
busiest_least_busy_hours AS (
    SELECT
        b.business_id,
        b.busiest_hour,
        b.max_checkins,
        l.least_busy_hour,
        l.min_checkins
    FROM busiest_hours b
    JOIN least_busy_hours l ON b.business_id = l.business_id
)

-- Atualização dos estabelecimento com os horários mais e menos movimentados
-- Update the business with the busiest and least busy hours
UPDATE business
SET business_data = jsonb_set(
    jsonb_set(
        business_data, 
        '{busiest_hour}', 
        to_jsonb(busiest_least_busy_hours.busiest_hour::text)
    ),
    '{least_busy_hour}', 
    to_jsonb(busiest_least_busy_hours.least_busy_hour::text)
)
FROM busiest_least_busy_hours
WHERE business.business_id = busiest_least_busy_hours.business_id;