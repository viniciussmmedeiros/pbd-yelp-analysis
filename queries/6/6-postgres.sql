-- Query 6

-- portuguese:
-- O objetivo dessa query é analisar os reviews dos estabelecimentos e identificar os atributos mencionados pelos usuários, classificando-os como atributos em "destaque" ou "ausentes" dependendo da quantidade de estrelas atribuídas à avaliação (> 3 ou <= 3).
-- Os atributos de base para análise foram pré-processados e mapeados manualmente para palavras-chave que representam o atributo, dado que é improvável um usuário mencionar palavras exatas como "AcceptsInsurance" em uma avaliação. Os 24 atributos mapeados são todos aqueles atributos distintos presentes em todos os negócios registrados no banco de dados, sem considerar os atributos aninhados, apenas os de primeiro nível.

-- english:
-- The purpose of this query is to analyze the reviews of businesses and identify the attributes mentioned by users, classifying them as "featured" or "missing" attributes depending on the number of stars assigned to the review (> 3 or <= 3). The base attributes for analysis were pre-processed and manually mapped to keywords that represent the attribute, given that it is unlikely for a user to mention exact words like "AcceptsInsurance" in a review. The 24 mapped attributes are all distinct attributes present in all businesses registered in the database, without considering nested attributes, only the first-level ones.

DROP TABLE IF EXISTS business_attribute_review;

-- Tabela para armazenar os reviews que mencionam os atributos mapeados, relacionando-os com o estabelecimento.
-- Table to store reviews that mention the mapped attributes, relating them to the business.
CREATE TABLE business_attribute_review (
    id SERIAL PRIMARY KEY,
    review_id TEXT,
    business_id TEXT,
    data JSONB
);

-- CTE para mapear os atributos e suas palavras-chave.
-- CTE to map attributes and their keywords.
WITH keyword_mapping AS (
    SELECT 'AcceptsInsurance' AS attribute_key, ARRAY['insurance'] AS keywords
    UNION ALL
    SELECT 'BikeParking', ARRAY['bike', 'bicycle'] AS keywords
    UNION ALL
    SELECT 'BusinessAcceptsBitcoin', ARRAY['bitcoin', 'crypto'] AS keywords
    UNION ALL
    SELECT 'BusinessAcceptsCreditCards', ARRAY['credit'] AS keywords
    UNION ALL
    SELECT 'ByAppointmentOnly', ARRAY['appointment'] AS keywords
    UNION ALL
    SELECT 'BYOB', ARRAY['byob'] AS keywords
    UNION ALL
    SELECT 'Caters', ARRAY['catering'] AS keywords
    UNION ALL
    SELECT 'CoatCheck', ARRAY['coat'] AS keywords
    UNION ALL
    SELECT 'Corkage', ARRAY['corkage'] AS keywords
    UNION ALL
    SELECT 'DogsAllowed', ARRAY['dogs'] AS keywords
    UNION ALL
    SELECT 'DriveThru', ARRAY['drive'] AS keywords
    UNION ALL
    SELECT 'GoodForDancing', ARRAY['dancing'] AS keywords
    UNION ALL
    SELECT 'GoodForKids', ARRAY['kids'] AS keywords
    UNION ALL
    SELECT 'HappyHour', ARRAY['happy'] AS keywords
    UNION ALL
    SELECT 'HasTV', ARRAY['tv'] AS keywords
    UNION ALL
    SELECT 'Open24Hours', ARRAY['24 hours', '24-hour'] AS keywords
    UNION ALL
    SELECT 'OutdoorSeating', ARRAY['outdoor'] AS keywords
    UNION ALL
    SELECT 'RestaurantsCounterService', ARRAY['counter'] AS keywords
    UNION ALL
    SELECT 'RestaurantsDelivery', ARRAY['delivery'] AS keywords
    UNION ALL
    SELECT 'RestaurantsGoodForGroups', ARRAY['groups'] AS keywords
    UNION ALL
    SELECT 'RestaurantsReservations', ARRAY['reservation'] AS keywords
    UNION ALL
    SELECT 'RestaurantsTableService', ARRAY['table'] AS keywords
    UNION ALL
    SELECT 'RestaurantsTakeOut', ARRAY['takeout'] AS keywords
    UNION ALL
    SELECT 'WheelchairAccessible', ARRAY['wheelchair'] AS keywords
),

-- CTE para selecionar os reviews que mencionam os atributos mapeados.
-- CTE to select reviews that mention the mapped attributes.
matched_reviews AS (
    SELECT 
        review_data->>'business_id' as business_id,
        k.attribute_key,
        r.review_id as review_id,
        r.review_data->>'text' AS review_text,
        (r.review_data->>'stars')::decimal AS stars,
        k.keywords
    FROM 
        review r
    CROSS JOIN 
        keyword_mapping k
    WHERE 
        EXISTS (
            SELECT 1 FROM unnest(k.keywords) AS kw
            WHERE
                r.review_data->>'text' ~* ('\y' || kw || '\y')
        )
),

-- CTE para classificar os reviews em "destaque" ou "ausentes" dependendo da quantidade de estrelas.
-- CTE to classify reviews as "featured" or "missing" depending on the number of stars.
categorized_reviews AS (
    SELECT
        business_id,
        review_id,
        jsonb_build_object(
            'attribute_key', attribute_key,
            'review_text', review_text,
            'stars', stars,
            'attribute_category', CASE 
                                    WHEN stars > 3 THEN 'featuredAttribute'
                                    ELSE 'missingAttribute'
                                  END
        ) AS data
    FROM 
        matched_reviews
)

-- Inserção dos reviews classificados na tabela criada.
-- Insert classified reviews into the created table.
INSERT INTO business_attribute_review (data, business_id, review_id)
SELECT data, business_id, review_id FROM categorized_reviews;

SELECT * FROM business_attribute_review;