/*
Query 3

 portuguese:
 Selecionar, para um estabelecimento alvo, um conjunto de 10 usuários 'influenciadores', que possuam uma quantidade relevante de fãs, avaliações realizadas e votos de "avaliação útil", na mesma cidade do estabelecimento.
 O business de id 'dLXkx82ZMsR5NLkCRtg0Dw' será usado como exemplo, pois está em uma cidade (Philadelphia) que contém 14569 negócios registrados na tabela 'business', podendo possuir um volume de dados maior de reviews.

 english:
 Select, for a target business, a set of 10 'influential' users, who have a relevant amount of fans, reviews made, and votes of "useful review", in the same city as the business.
 The business with id 'dLXkx82ZMsR5NLkCRtg0Dw' will be used as an example, as it is in a city (Philadelphia) that contains 14569 businesses registered in the 'business' table, which may have a larger volume of review data.
*/

const start = new Date();

const targetBusinessId = 'dLXkx82ZMsR5NLkCRtg0Dw';

// target_business
const targetBusiness = db.business.findOne(
  { business_id: targetBusinessId },
  { _id: 0, city: 1 }
);
const targetCity = targetBusiness.city;

// Buscando ids de negócios na mesma cidade do negócio alvo para diminuir a base utilizada na aggregation a seguir.
// Getting business ids in the same city as the target business to reduce the dataset used in the following aggregation.
const businessesInCity = db.business.distinct('business_id', {
  city: targetCity,
  business_id: { $ne: 'dLXkx82ZMsR5NLkCRtg0Dw' }
});

// user_review_count
db.review.aggregate([
  {
    $match: {
      business_id: { $in: businessesInCity }
    }
  },
  {
    $group: {
      _id: '$user_id',
      review_count: { $sum: 1 }
    }
  },
  {
    $project: {
      _id: 0,
      user_id: '$_id',
      review_count: 1
    }
  },
  {
    $out: 'user_review_counts'
  }
]);

db.user_review_counts.aggregate([
  {
    $lookup: {
      from: 'user',
      localField: 'user_id',
      foreignField: 'user_id',
      as: 'user_info'
    }
  },
  { $unwind: '$user_info' },
  {
    $project: {
      _id: 0,
      user_id: 1,
      review_count: 1,
      fans: '$user_info.fans',
      useful: '$user_info.useful'
    }
  },
  {
    $sort: {
      fans: -1,
      review_count: -1,
      useful: -1
    }
  },
  { $limit: 10 },
  { $out: 'influencers' }
]);

const end = new Date();
console.log(`Execution time: ${end - start} ms`);