-- Query 3

-- portuguese:
-- Selecionar, para um estabelecimento alvo, um conjunto de 10 usuários 'influenciadores', que possuam uma quantidade relevante de fãs, avaliações realizadas e votos de "avaliação útil", na mesma cidade do estabelecimento.
-- O business de id 'dLXkx82ZMsR5NLkCRtg0Dw' será usado como exemplo, pois está em uma cidade (Philadelphia) que contém 14569 negócios registrados na tabela 'business', podendo possuir um volume de dados maior de reviews.

-- english:
-- Select, for a target business, a set of 10 'influential' users, who have a relevant amount of fans, reviews made, and votes of "useful review", in the same city as the business.
-- The business with id 'dLXkx82ZMsR5NLkCRtg0Dw' will be used as an example, as it is in a city (Philadelphia) that contains 14569 businesses registered in the 'business' table, which may have a larger volume of review data.

-- CTE simples para capturar a cidade do estabelecimento alvo
-- Simple CTE to get the city of the target business
WITH target_business AS (
    SELECT 
        business_id,
        business_data->>'city' AS city
    FROM business
    WHERE business_id = 'dLXkx82ZMsR5NLkCRtg0Dw'
),

-- CTE para encontrar usuários que fizeram reviews em estabelecimentos na mesma cidade do estabelecimento alvo, contando a quantidade de avaliações realizadas.
-- CTE to find users who reviewed businesses in the same city as the target business, counting the number of reviews made.
user_review_count AS (
    SELECT
        r.review_data->>'user_id' AS user_id,
        COUNT(*) AS review_count
    FROM review r
    JOIN business b ON r.review_data->>'business_id' = b.business_id
    JOIN target_business tb ON b.business_data->>'city' = tb.city
    WHERE b.business_id != tb.business_id
    GROUP BY r.review_data->>'user_id'
)

-- Consulta final para selecionar os 10 usuários 'influenciadores', baseados em fãs, quantida de reviews e votos de "avaliação útil".
-- Final query to select the 10 'influential' users, based on fans, number of reviews, and votes of "useful review".
SELECT
    y.user_id,
    (y.user_data->>'fans')::int AS fans,
    (y.user_data->>'useful')::int AS useful,
    urc.review_count
FROM yuser y
JOIN user_review_count urc ON y.user_id = urc.user_id
ORDER BY fans DESC, review_count DESC, useful DESC
LIMIT 10;