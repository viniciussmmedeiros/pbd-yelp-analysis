-- Query 2

-- portuguese:
-- Selecionar reviews de estabelecimentos na mesma cidade e com categorias semelhantes que o nosso estabelecimento alvo. Trazendo 10 reviews mais recentes por estabelecimento, ordenados por quantidade de categorias semelhantes, data de avaliação e estrelas.
-- O business de id 'dLXkx82ZMsR5NLkCRtg0Dw' será usado como exemplo, pois tem 14 categorias e está em uma cidade (Philadelphia) que contém 14569 negócios registrados na tabela 'business'.

-- english:
-- Select reviews from businesses in the same city and with similar categories to our target business. Bringing 10 most recent reviews per business, ordered by the number of similar categories, review date, and stars.
-- The business with id 'dLXkx82ZMsR5NLkCRtg0Dw' will be used as an example, as it has 14 categories and is in a city (Philadelphia) that contains 14569 businesses registered in the 'business' table.

-- CTE pra capturar a cidade e categorias do estabelecimento alvo, sendo uma linha para cada categoria (unnest).
-- CTE to get the city and categories of the target business, with a row for each category (unnest).
WITH target_business AS (
    SELECT 
        business_id,
        business_data->>'city' AS city,
        unnest(string_to_array(business_data->>'categories', ',')) AS category
    FROM business
    WHERE business_id = 'dLXkx82ZMsR5NLkCRtg0Dw'
),

-- CTE para encontrar estabelecimentos que estão na mesma cidade e têm categorias semelhantes ao estabelecimento alvo.
-- CTE to find businesses that are in the same city and have similar categories to the target business.
matched_business AS (
    SELECT 
        b.business_id,
        b.business_data->>'categories' AS categories,
        COUNT(*) AS match_count
    FROM business b
    JOIN target_business tb 
        ON b.business_data->>'city' = tb.city 
        AND b.business_data->>'categories' ILIKE '%' || trim(tb.category) || '%'
    GROUP BY b.business_id, b.business_data->>'categories'
    ORDER BY match_count DESC, b.business_data->>'categories', b.business_id
    LIMIT 10
),

-- CTE para selecionar as reviews relacionadas aos estabelecimentos encontrados
-- CTE to select the reviews related to the matched businesses
business_reviews AS (
    SELECT 
        r.review_id,
        r.review_data->>'text' AS text,
        mb.business_id,
        mb.match_count,
        (r.review_data->>'stars')::decimal AS stars,
        r.review_data->>'date' AS date
    FROM review r
    JOIN matched_business mb ON r.review_data->>'business_id' = mb.business_id
),

-- CTE para ranquear as reviews por estabelecimento, priorizando as mais recentes
-- CTE to rank reviews by business, prioritizing the most recent ones
ranked_reviews AS (
    SELECT 
        br.review_id,
        br.text,
        br.business_id,
        br.match_count,
        br.stars,
        br.date,
        ROW_NUMBER() OVER (PARTITION BY br.business_id ORDER BY br.date DESC) AS rank
    FROM business_reviews br
)

-- Consulta final para retornar as reviews, ordenadas por quantidade de categorias semelhantes, data de avaliação e estrelas.
-- Final query to return the reviews, ordered by the number of similar categories, review date, and stars.
SELECT 
    rr.business_id,
    rr.match_count,
    rr.review_id,
    rr.text,
    rr.stars,
    rr.date
FROM ranked_reviews rr
WHERE rr.rank <= 10
ORDER BY rr.match_count DESC, rr.date DESC, rr.stars DESC;