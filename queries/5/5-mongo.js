/*
 Query 5

 portuguese:
 Essa query representa a mesma ideia da query 1, porém com a adição de que as recomendações são inseridas no documento do usuário, representando a diferença de apenas uma consulta para consulta com atualização de dados.

 english:
 This query represents the same idea as query 1, but with the addition that the recommendations are inserted into the user document, representing the difference of just one query to query with data update.
*/

const start = new Date();

const userId = "_BcWyKQL16ndpBdggh2kNA";

// user_reviewed_business
db.review.aggregate([
  {
    $match: {
      user_id: userId,
      stars: { $gte: 4.0 }
    }
  },
  {
    $lookup: {
      from: "business",
      localField: "business_id",
      foreignField: "business_id",
      as: "business_info"
    }
  },
  {
    $addFields: {
      "business_info.categoriesArray": {
        $map: {
          input: {
            $cond: {
              if: { $ne: [{ $type: { $arrayElemAt: ["$business_info.categories", 0] } }, "null"] },
              then: { $split: [{ $arrayElemAt: ["$business_info.categories", 0] }, ", "] },
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
    $unwind: "$business_info"
  },
  {
    $unwind: "$business_info.categoriesArray"
  },
  {
    $project: {
      _id: 0,
      business_id: 1,
      city: "$business_info.city",
      category: "$business_info.categoriesArray"
    }
  },
  { $out: "user_reviewed_business" }
]);

// user_reviewed_city
db.review.aggregate([
  {
    $match: { user_id: userId }
  },
  {
    $lookup: {
      from: "business",
      localField: "business_id",
      foreignField: "business_id",
      as: "business"
    }
  },
  { $unwind: "$business" },
  {
    $group: {
      _id: "$business.city",
      review_count: { $sum: 1 }
    }
  },
  {
    $project: {
      city: "$_id",
      review_count: 1
    }
  },
  { $out: "user_reviewed_city" }
]);

// recommended_businesses
db.business.aggregate([
  {
    $lookup: {
      from: "user_reviewed_business",
      let: { city: "$city", categories: "$categories" },
      pipeline: [
        {
          $match: {
            $expr: {
              $and: [
                { $eq: ["$city", "$$city"] },
                { $regexMatch: { input: "$$categories", regex: { $trim: { input: "$category" } }, options: "i" } }
              ]
            }
          }
        }
      ],
      as: "matched_businesses"
    }
  },
  {
    $match: {
      "business_id": { $nin: db.review.distinct("business_id", { user_id: userId }) }
    }
  },
  {
    $unwind: "$matched_businesses"
  },
  {
    $group: {
      _id: {
        business_id: "$business_id",
        city: "$city",
        categories: "$categories"
      },
      match_count: { $sum: 1 }
    }
  },
  {
    $project: {
      _id: 0,
      business_id: "$_id.business_id",
      city: "$_id.city",
      categories: "$_id.categories",
      match_count: 1
    }
  },
  { $out: "recommended_businesses" }
]);

// ranked_recommendations
db.recommended_businesses.aggregate([
  {
    $lookup: {
      from: "user_reviewed_city",
      localField: "city",
      foreignField: "city",
      as: "city_info"
    }
  },
  {
    $unwind: "$city_info"
  },
  {
    $setWindowFields: {
      partitionBy: "$city",
      sortBy: { match_count: -1 },
      output: {
        rank: { $denseRank: {} }
      }
    }
  },
  {
    $match: { rank: 1 }
  },
  {
    $project: {
      _id: 0,
      city: 1,
      business_id: 1,
      categories: 1,
      match_count: 1,
      review_count: "$city_info.review_count"
    }
  },
  {
    $sort: { review_count: -1 }
  },
  {
    $limit: 10
  },
  { $out: "ranked_recommendations" }
], { allowDiskUse: true });

// Atualizar o usuário com as recomendações
// Update the user with the recommendations
const recommendations = db.ranked_recommendations.find().toArray().map(doc => doc.business_id);

db.user.updateOne(
  { user_id: userId },
  { $set: { "recommendations": recommendations } }
);

const end = new Date();
console.log(`Execution time: ${end - start} ms`);