/*
Query 4

portuguese:
Para cada dado de 'checkin' na base 'checkin', analisar os registros relacionando-os com os estabelecimentos da base 'business' e atualizar os documentos de estabelecimento com o horário mais movimentado e o menos movimentado. Sendo possível que não haja checkins registrados para um estabelecimento, ou que as quantidades de checkins sejam iguais para diferentes horários, podendo resultar em valores nulos ou iguais para os horários mais e menos movimentados.

english:
For each 'checkin' data in the 'checkin' table, analyze the records relating them to the businesses in the 'business' table and update the business documents with the busiest and least busy hours. It is possible that there are no check-ins registered for a business, or that the number of check-ins is the same for different hours, which may result in null or equal values for the busiest and least busy hours.
*/

const start = new Date();

// checkin_distribution | busiest_hours | least_busy_hours
db.checkin.aggregate([
  {
    $match: { business_id: "00rY5F9ltW-IWf2Ev96kOg" }
  },
  {
    $addFields: {
      checkin_hours: {
        $map: {
          input: { $split: ["$date", ","] },
          as: "dateString",
          in: { $hour: { $toDate: "$$dateString" } }
        }
      }
    }
  },
  {
    $unwind: "$checkin_hours"
  },
  {
    $group: {
      _id: {
        business_id: "$business_id",
        checkin_hour: "$checkin_hours"
      },
      checkin_count: { $sum: 1 }
    }
  },
  {
    $sort: {
      checkin_count: 1,
    }
  },
  {
    $group: {
      _id: "$_id.business_id",
      busiest_hour: { $last: { hour: "$_id.checkin_hour", count: "$checkin_count" } },
      least_busy_hour: { $first: { hour: "$_id.checkin_hour", count: "$checkin_count" } }
    }
  },
  {
    $project: {
      business_id: "$_id",
      busiest_hour: "$busiest_hour.hour",
      max_checkins: "$busiest_hour.count",
      least_busy_hour: "$least_busy_hour.hour",
      min_checkins: "$least_busy_hour.count"
    }
  },
  {
    $lookup: {
      from: "business",
      localField: "business_id",
      foreignField: "business_id",
      as: "business_doc"
    }
  },
  {
    $unwind: "$business_doc"
  },
  {
    $set: {
      "business_doc.busiest_hour": { $toString: "$busiest_hour" },
      "business_doc.least_busy_hour": { $toString: "$least_busy_hour" }
    }
  },
  {
    $replaceRoot: { newRoot: "$business_doc" }
  },
  {
    $merge: {
      into: "business",
      whenMatched: "merge",
      whenNotMatched: "discard"
    }
  }
]);

const end = new Date();
console.log(`Execution time: ${end - start} ms`);