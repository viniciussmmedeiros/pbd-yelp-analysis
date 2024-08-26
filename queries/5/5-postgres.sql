-- Query 5

-- portuguese:
-- Essa query representa a mesma ideia da query 1, porém com a adição de que as recomendações são inseridas no documento do usuário, representando a diferença de apenas uma consulta para consulta com atualização de dados.

-- english:
-- This query represents the same idea as query 1, but with the addition that the recommendations are inserted into the user document, representing the difference of just one query to query with data update.


-- CTE para capturar os estabelecimentos avaliados pelo usuário, com uma linha para cada estabelecimento x categoria, com estrelas >= 4.0
-- CTE to get businesses reviewed by user, with a row for each business x category, with stars >= 4.0
WITH user_reviewed_business AS (
    SELECT 
        business_id, 
        b.business_data->>'city' AS city, 
        unnest(string_to_array(trim(b.business_data->>'categories'), ', ')) AS category
    FROM review r
    JOIN business b ON b.business_id = r.review_data->>'business_id'
    WHERE r.review_data->>'user_id' = '_BcWyKQL16ndpBdggh2kNA' 
        AND (r.review_data->>'stars')::decimal >= 4.0
),

-- CTE para capturar as cidades dos estabelecimentos avaliados pelo usuário
-- CTE to get the cities of businesses reviewed by the user
user_reviewed_city AS (
    SELECT
        b.business_data->>'city' AS city,
        COUNT(*) AS review_count
    FROM review r
    JOIN business b ON b.business_id = r.review_data->>'business_id'
    WHERE r.review_data->>'user_id' = '_BcWyKQL16ndpBdggh2kNA'
    GROUP BY city
),

-- CTE para capturar os estabelecimentos recomendados, aqueles em cidades iguais e com categorias semelhantes aos bem avaliados pelo usuário.
-- CTE to get recommended businesses, those in the same cities and with similar categories to those well reviewed by the user.
recommended_businesses AS (
    SELECT 
        b.business_id,
        b.business_data->>'city' AS city,
        b.business_data->>'categories' AS categories,
        COUNT(*) AS match_count
    FROM business b
    JOIN user_reviewed_business urb 
        ON b.business_data->>'city' = urb.city 
        AND b.business_data->>'categories' ILIKE '%' || trim(urb.category) || '%'
    WHERE b.business_id NOT IN (
        SELECT review_data->>'business_id'
        FROM review
        WHERE review_data->>'user_id' = '_BcWyKQL16ndpBdggh2kNA'
    )
    GROUP BY b.business_id, city, categories
),

-- CTE para ranquear as recomendações por cidade, priorizando aquelas com maior quantidade de categorias semelhantes.
-- CTE to rank recommendations by city, prioritizing those with the highest number of similar categories.
ranked_recommendations AS (
    SELECT 
        rb.business_id,
        rb.city,
        rb.categories,
        rb.match_count,
        urc.review_count,
        ROW_NUMBER() OVER (PARTITION BY rb.city ORDER BY rb.match_count DESC) AS rank
    FROM 
        recommended_businesses rb
    JOIN 
        user_reviewed_city urc ON rb.city = urc.city
)

-- CTE para salvar as recomendações do usuário, ordenadas por quantidade de avaliações, priorizando as cidades mais avaliadas.
-- CTE to save user recommendations, ordered by number of reviews, prioritizing the most reviewed cities.
, top_recommendations AS (
    SELECT 
        business_id,
        categories,
        match_count
    FROM ranked_recommendations
    WHERE rank = 1
    ORDER BY review_count DESC
    LIMIT 10
)

-- Atualiza o usuário com as recomendações.
-- Update user with recommendations.
UPDATE yuser
SET user_data = jsonb_set(
    user_data, 
    '{recommendations}', 
    to_jsonb(
        (SELECT array_agg(business_id) 
         FROM top_recommendations)
    )
)
WHERE user_id = '_BcWyKQL16ndpBdggh2kNA';