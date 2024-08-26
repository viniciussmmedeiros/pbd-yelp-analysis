/*
Query 2

 portuguese:
 Selecionar reviews de estabelecimentos na mesma cidade e com categorias semelhantes que o nosso estabelecimento alvo. Trazendo 10 reviews mais recentes por estabelecimento, ordenados por quantidade de categorias semelhantes, data de avaliação e estrelas.
 O business de id 'dLXkx82ZMsR5NLkCRtg0Dw' será usado como exemplo, pois tem 14 categorias e está em uma cidade (Philadelphia) que contém 14569 negócios registrados na tabela 'business'.

 english:
 Select reviews from businesses in the same city and with similar categories to our target business. Bringing 10 most recent reviews per business, ordered by the number of similar categories, review date, and stars.
 The business with id 'dLXkx82ZMsR5NLkCRtg0Dw' will be used as an example, as it has 14 categories and is in a city (Philadelphia) that contains 14569 businesses registered in the 'business' table.
*/
const start = new Date();

const targetBusinessId = "dLXkx82ZMsR5NLkCRtg0Dw";

// target_business
db.business.aggregate([
  {
    $match: { business_id: targetBusinessId }
  },
  {
    $addFields: {
      categoriesArray: {
        $map: {
          input: {
            $cond: {
              if: { $ne: [{ $type: "$categories" }, "null"]},
              then: { $split: ["$categories", ", "] },
              else: []
            }
          },
          as: "category",
          in: {
            $replaceAll: {
              input: {
                $replaceAll: {
                  input: { $trim: { input: "$$category" } },
                  find: "(",
                  replacement: "\\("
                }
              },
              find: ")",
              replacement: "\\)"
            }
          }
        }
      }
    }
  },
  {
    $unwind: "$categoriesArray"
  },
  {
    $project: {
      _id: 0,
      business_id: 1,
      city: "$city",
      category: "$categoriesArray"
    }
  },
  { $out: "target_business" }
]);

// matched_business
db.business.aggregate([
  {
    $lookup: {
      from: "target_business",
      let: { city: "$city", categories: "$categories" },
      pipeline: [
        {
          $match: {
            $expr: {
              $and: [
                { $eq: ["$city", "$$city"] },
                { $regexMatch: { input: "$$categories", regex: {$trim: { input: "$category" }}, options: "i" } }
              ]
            }
          }
        }
      ],
      as: "matched"
    }
  },
  {
    $unwind: "$matched"
  },
  {
    $group: {
      _id: {
        business_id: "$business_id",
        categories: "$categories"
      },
      match_count: { $sum: 1 }
    }
  },
  {
    $project: {
      _id: 0,
      business_id: "$_id.business_id",
      categories: "$_id.categories",
      match_count: 1
    }
  },
  {
    $sort: { 
      match_count: -1,
      "categories": 1,
      "business_id": 1
    }
  },
  {
    $limit: 10
  },
  { $out: "matched_business" }
]);

// business_reviews
db.review.aggregate([
  {
    $lookup: {
      from: "matched_business",
      localField: "business_id",
      foreignField: "business_id",
      as: "matched"
    }
  },
  {
    $unwind: "$matched"
  },
  {
    $project: {
      _id: 0,
      review_id: 1,
      text: "$text",
      business_id: "$matched.business_id",
      match_count: "$matched.match_count",
      stars: "$stars",
      date: "$date"
    }
  },
  { $out: "business_reviews" }
]);

// ranked_reviews
db.business_reviews.aggregate([
  {
    $setWindowFields: {
      partitionBy: "$business_id",
      sortBy: { date: -1 },
      output: {
        rank: { $denseRank: {} }
      }
    }
  },
  {
    $match: { rank: { $lte: 10 } }
  },
  {
    $project: {
      _id: 0,
      business_id: 1,
      match_count: 1,
      review_id: 1,
      text: 1,
      stars: 1,
      date: 1
    }
  },
  {
    $sort: { match_count: -1, date: -1, stars: -1 }
  },
  { $out: "ranked_reviews" }
]);

const end = new Date();
console.log(`Execution time: ${end - start} ms`);