-- Query 1

-- portuguese:
-- Gerar recomendações para um usuário, consultando estabelecimentos que estão na mesma cidade e que têm categorias semelhantes às categorias dos estabelecimentos que o usuário avaliou positivamente.
-- O usuário de id '_BcWyKQL16ndpBdggh2kNA' será usado como exemplo, pois possui 1894 reviews com estrelas >= 4.0, representando um alto volume de dados.

-- english:
-- Generate recommendations for a user by querying businesses that are in the same city and have categories similar to the categories of businesses that the user has positively reviewed.
-- The user with id '_BcWyKQL16ndpBdggh2kNA' will be used as an example, as it has 1894 reviews with stars >= 4.0, representing a high volume of data.

-- CTE para capturar os estabelecimentos avaliados pelo usuário, com uma linha para cada estabelecimento x categoria, com estrelas >= 4.0
-- CTE to get businesses reviewed by user, with a row for each business x category, with stars >= 4.0
WITH user_reviewed_business as (
    SELECT 
        business_id, 
        b.business_data->>'city' as city, 
        unnest(string_to_array(trim(b.business_data->>'categories'), ', ')) as category
    FROM review r
    JOIN business b ON b.business_id = r.review_data->>'business_id'
    WHERE r.review_data->>'user_id' = '_BcWyKQL16ndpBdggh2kNA' AND 
        (r.review_data->>'stars')::decimal >= 4.0
),
-- CTE para capturar as cidades dos estabelecimentos avaliados pelo usuário
-- CTE to get the cities of businesses reviewed by the user
user_reviewed_city as (
    SELECT
        b.business_data->>'city' as city,
        count(*) as review_count
    FROM review r
    JOIN business b ON b.business_id = r.review_data->>'business_id'
    WHERE r.review_data->>'user_id' = '_BcWyKQL16ndpBdggh2kNA'
    GROUP BY city
),
-- CTE para capturar os estabelecimentos recomendados, aqueles em cidades iguais e com categorias semelhantes aos bem avaliados pelo usuário.
-- CTE to get recommended businesses, those in the same cities and with similar categories to those well reviewed by the user.
recommended_businesses as (
    SELECT 
        b.business_id,
        b.business_data->>'city' as city,
        b.business_data->>'categories' as categories,
        count(*) as match_count
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
        rb.city,
        rb.business_id,
        rb.categories,
        rb.match_count,
        urc.review_count,
        ROW_NUMBER() OVER (PARTITION BY rb.city ORDER BY rb.match_count DESC) AS rank
    FROM 
        recommended_businesses rb
    JOIN 
        user_reviewed_city urc ON rb.city = urc.city
)
-- Consulta final para retornar as recomendações, ordenadas por quantidade de avaliações, priorizando as cidades mais avaliadas.
-- Final query to return recommendations, ordered by number of reviews, prioritizing the most reviewed cities.
SELECT 
    city,
    business_id,
    categories,
    match_count
FROM ranked_recommendations
WHERE rank = 1
ORDER BY review_count DESC
LIMIT 10;