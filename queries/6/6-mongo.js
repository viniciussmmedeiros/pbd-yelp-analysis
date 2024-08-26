/*
Query 6

 portuguese:
 O objetivo dessa query é analisar os reviews dos estabelecimentos e identificar os atributos mencionados pelos usuários, classificando-os como atributos em "destaque" ou "ausentes" dependendo da quantidade de estrelas atribuídas à avaliação (> 3 ou <= 3).
 Os atributos de base para análise foram pré-processados e mapeados manualmente para palavras-chave que representam o atributo, dado que é improvável um usuário mencionar palavras exatas como "AcceptsInsurance" em uma avaliação. Os 24 atributos mapeados são todos aqueles atributos distintos presentes em todos os negócios registrados no banco de dados, sem considerar os atributos aninhados, apenas os de primeiro nível.

 english:
 The purpose of this query is to analyze the reviews of businesses and identify the attributes mentioned by users, classifying them as "featured" or "missing" attributes depending on the number of stars assigned to the review (> 3 or <= 3). The base attributes for analysis were pre-processed and manually mapped to keywords that represent the attribute, given that it is unlikely for a user to mention exact words like "AcceptsInsurance" in a review. The 24 mapped attributes are all distinct attributes present in all businesses registered in the database, without considering nested attributes, only the first-level ones.
*/

const start = new Date();

const keywordMapping = [
  { attribute_key: 'AcceptsInsurance', keywords: ['insurance'] },
  { attribute_key: 'BikeParking', keywords: ['bike', 'bicycle'] },
  { attribute_key: 'BusinessAcceptsBitcoin', keywords: ['bitcoin', 'crypto'] },
  { attribute_key: 'BusinessAcceptsCreditCards', keywords: ['credit'] },
  { attribute_key: 'ByAppointmentOnly', keywords: ['appointment'] },
  { attribute_key: 'BYOB', keywords: ['byob'] },
  { attribute_key: 'Caters', keywords: ['catering'] },
  { attribute_key: 'CoatCheck', keywords: ['coat'] },
  { attribute_key: 'Corkage', keywords: ['corkage'] },
  { attribute_key: 'DogsAllowed', keywords: ['dogs'] },
  { attribute_key: 'DriveThru', keywords: ['drive'] },
  { attribute_key: 'GoodForDancing', keywords: ['dancing'] },
  { attribute_key: 'GoodForKids', keywords: ['kids'] },
  { attribute_key: 'HappyHour', keywords: ['happy'] },
  { attribute_key: 'HasTV', keywords: ['tv'] },
  { attribute_key: 'Open24Hours', keywords: ['24 hours', '24-hour'] },
  { attribute_key: 'OutdoorSeating', keywords: ['outdoor'] },
  { attribute_key: 'RestaurantsCounterService', keywords: ['counter'] },
  { attribute_key: 'RestaurantsDelivery', keywords: ['delivery'] },
  { attribute_key: 'RestaurantsGoodForGroups', keywords: ['groups'] },
  { attribute_key: 'RestaurantsReservations', keywords: ['reservation'] },
  { attribute_key: 'RestaurantsTableService', keywords: ['table'] },
  { attribute_key: 'RestaurantsTakeOut', keywords: ['takeout'] },
  { attribute_key: 'WheelchairAccessible', keywords: ['wheelchair'] }
];

// matched_reviews | categorized_reviews
db.review.aggregate([
  {
      $addFields: {
          matchedAttributes: {
              $filter: {
                  input: keywordMapping,
                  as: "kw",
                  cond: {
                      $anyElementTrue: {
                          $map: {
                              input: "$$kw.keywords",
                              as: "keyword",
                              in: {
                                  $regexMatch: {
                                      input: "$text",
                                      regex: {$concat: ["\\b", "$$keyword", "\\b"]},
                                      options: "i"
                                  }
                              }
                          }
                      }
                  }
              }
          }
      }
  },
  {
      $unwind: "$matchedAttributes"
  },
  {
      $addFields: {
          attribute_category: {
              $cond: { if: { $gt: ["$stars", 3] }, then: "featuredAttribute", else: "missingAttribute" }
          }
      }
  },
  {
      $project: {
          _id: 0,
          review_id: 1,
          business_id: 1,
          data: {
              attribute_key: "$matchedAttributes.attribute_key",
              review_text: "$text",
              stars: "$stars",
              attribute_category: "$attribute_category"
          }
      }
  },
  {
    $out: "business_attribute_review"
  }
], { allowDiskUse: true });

const end = new Date();
console.log(`Execution time: ${end - start} ms`);