# Projeto de Banco de Dados

Objetivo:
Estudar um caso de uso de bancos de dados relacionais e não relacionais, utilizando as bases de dados do Yelp. Analisando as implementações, e desempenho. Importante considerar que não é possível fazer uma comparação crítica entre os bancos PostgreSQL e MongoDB a partir dessas implementações, dado que as queries possuem infinitas possibilidades de otimização, um único stage diferente em uma query do mongo, por exemplo, pode mudar drasticamente o seu desempenho. O objetivo final é entender como os bancos se comportam e uma implementação "crua" seguindo conceitos relacionais sobre dados semiestruturados, observando o comportamento do postgres com dados jsonb e do mongodb com aggregations de modo a testar a sua capacidade de fazer operações semelhantes ao funcionamento de 'joins' em bancos relacionais.

MongoDB v7.0.7
PostgreSQL v16.3
Docker Engine v27.0.3

As pastas "logs" contém os dados obtidos com `EXPLAIN ANALYZE` e `.explain("executionStats")` para o PostgreSQL e MongoDB, respectivamente.

PostgreSQL sem indexação
query 1:
#1 = Execution Time: 164571.000 ms
#2 = Execution Time: 157387.880 ms
#3 = Execution Time: 153554.780 ms
Resultado: 158504.553 ms = 2.64174255 minutes

query 2:
#1 = Execution Time: 10630.110 ms
#2 = Execution Time: 5052.447 ms
#3 = Execution Time: 4920.423 ms
Resultado: 6867.66 ms = 0.114461 minutes

query 3:
#1 = Execution Time: 63959.085 ms
#2 = Execution Time: 52981.876 ms
#3 = Execution Time: 25324.384 ms
Resultado: 47421.7816667 ms = 0.7903630277783333 minutes

query 4:
#1 = Execution Time: 7.135 ms
#2 = Execution Time: 0.856 ms
#3 = Execution Time: 0.116 ms
Resultado: 2.70233333333 ms = 4.50388888888333e-5

query 5:
#1 = Execution Time: 180042.254 ms
#2 = Execution Time: 143271.363 ms
#3 = Execution Time: 150036.914 ms
Resultado: 157783.51033300001291 ms = 2.629725172216667 minutes

query 6:
#1 = Execution Time: 967827.887 ms
#2 = Execution Time: 953696.838 ms
#3 = Execution Time: 959311.701 ms
Resultado: 960278.808667 ms = 16.00464681111667 minutes

PostgreSQL com indexação
query 1:
#1 = Execution Time: 122329.463 ms
#2 = Execution Time: 93253.326 ms
#3 = Execution Time: 95340.040 ms
Resultado: 103640.943 ms = 1.72734905 minutes

query 2:
#1 = Execution Time: 14588.056 ms
#2 = Execution Time: 5837.218 ms
#3 = Execution Time: 4704.350 ms
Resultado: 8376.54133333 ms = 0.1396090222221667 minutes

query 3:
#1 = Execution Time: 60376.526 ms
#2 = Execution Time: 45517.853 ms
#3 = Execution Time: 23632.159 ms
Resultado: 43175.5126667 ms = 0.7195918777783333 minutes

query 4:
#1 = Execution Time: 3.050 ms
#2 = Execution Time: 0.068 ms
#3 = Execution Time: 0.067 ms
Resultado: 1.06166666667 ms = 1.76944444445e-5 minutes

query 5:
#1 = Execution Time: 127730.516 ms
#2 = Execution Time: 91803.907 ms
#3 = Execution Time: 91213.847 ms
Resultado: 103582.756667 ms = 1.726379277783333 minutes

MongoDB sem indexação
query 1:
#1 = Execution time: 3783405 ms
#2 = Execution time: 3872112 ms
#3 = Execution time: 3892892 ms
Resultado: 3849469.6666700001806 ms = 64.15782777783333 minutes

query 2:
#1 = Execution time: 257991 ms
#2 = Execution time: 244555 ms
#3 = Execution time: 238212 ms
Resultado: = 246919.33333299995866 ms = 4.115322222216666 minutes

query 3:
#1 = -
#2 = -
#3 = -
Resultado: A execução demorou mais de 120 minutos nas tentativas, sendo impraticável.
 
query 4:
#1 = Execution time: 1289 ms
#2 = Execution time: 149 ms
#3 = Execution time: 144 ms
Resultado: 527.33333333300004142 ms = 0.008788888888883333 minutes

query 5:
#1 = Execution time: 1211168 ms
#2 = Execution time: 1251693 ms
#3 = Execution time: 1215551 ms
Resultado: 1226137.33333 ms = 20.43562222216667 minutes

query 6:
#1 = Execution time: 575902 ms
#2 = Execution time: 545662 ms
#3 = Execution time: 539877 ms
Resultado: 553813.666667 ms = 9.230227777783334 minutes

MongoDB com indexação
query 1:
#1 = Execution time: 985602 ms
#2 = Execution time: 937187 ms
#3 = Execution time: 989927 ms
Resultado: 970905.333333 ms = 16.18175555555

query 3:
#1 = Execution time: 247104 ms
#2 = Execution time: 149378 ms
#3 = Execution time: 138921 ms
Resultado: 178467.666667 ms = 2.974461111116667 minutes

query 4:
#1 = Execution time: 892 ms
#2 = Execution time: 70 ms
#3 = Execution time: 69 ms
Resultado: 343.666666667 ms = 0.005727777777783333 minutes

query 5:
#1 = Execution time: 919562 ms
#2 = Execution time: 971416 ms
#3 = Execution time: 1009455 ms
Resultado: 966811 ms = 16.1135167 minutes

Instruções
1. Baixar a base de dados yelp, link: https://www.yelp.com/dataset
2. Instalar o docker, link: https://www.docker.com/
2. Na raiz do arquivo docker-compose.yml, executar o comando `docker-compose up -d`
3. Importar os arquivos JSON para o mongodb, substituindo o path de cada comando pelo path dos arquivos baixados.
Import business collection:
`docker exec mongo-pbd mongoimport --host localhost --db yelp --collection business --type json --file **<path>**/yelp_academic_dataset_business.json`

Import review collection:
`docker exec mongo-pbd mongoimport --host localhost --db yelp --collection review --type json --file **<path>**/yelp_academic_dataset_review.json`

Import user collection:
`docker exec mongo-pbd mongoimport --host localhost --db yelp --collection user --type json --file **<path>**/yelp_academic_dataset_user.json`

Import checkin collection:
`docker exec mongo-pbd mongoimport --host localhost --db yelp --collection checkin --type json --file **<path>**/yelp_academic_dataset_checkin.json`

Atentar-se que o compose está mapeando o mongodb para a porta 27020, que deve ser utilizada para acessar o banco de dados.

4. Importar os arquivos JSON para o postgresql, substituindo o path de cada comando pelo path dos arquivos baixados.
Executar o comando `docker exec -it postgres-pbd bash` para acessar o container e executar os comandos abaixo.

Primeiramente criamos as tabelas de preparação para as tabelas 'Business', 'Review' e 'User', dado que essas terão seu id em sua própria coluna.
`psql -U postgres -d postgres -c "CREATE TABLE staging_business (data JSONB);"`
`psql -U postgres -d postgres -c "CREATE TABLE staging_review (data JSONB);"`
`psql -U postgres -d postgres -c "CREATE TABLE staging_user (data JSONB);"`

Então, criamos as tabelas finais:
`psql -U postgres -d postgres -c "CREATE TABLE business (business_id TEXT PRIMARY KEY, business_data JSONB);"`
`psql -U postgres -d postgres -c "CREATE TABLE review (review_id TEXT PRIMARY KEY, review_data JSONB);"`
`psql -U postgres -d postgres -c "CREATE TABLE yuser (user_id TEXT PRIMARY KEY, user_data JSONB);"`
`psql -U postgres -d postgres -c "CREATE TABLE checkin (id SERIAL PRIMARY KEY, checkin_data JSONB);"`
Repare que para o checkin há uma chave serial, usada como substituta, dado que o json não possui um id específico para cada checkin.

Importamos os dados nas tabelas de preparação:
`psql -U postgres -d postgres -c "\copy staging_business(data) FROM '<path:>/yelp_academic_dataset_business.json' csv quote e'\x01' delimiter e'\x02';"`
`psql -U postgres -d postgres -c "\copy staging_review(data) FROM '<path:>/yelp_academic_dataset_review.json' csv quote e'\x01' delimiter e'\x02';"`
`psql -U postgres -d postgres -c "\copy staging_user(data) FROM '<path:>/yelp_academic_dataset_user.json' csv quote e'\x01' delimiter e'\x02';"`

Inserimos os dados das tabelas de preparação nas tabelas finais:
`psql -U postgres -d postgres -c "INSERT INTO business (business_id, business_data) SELECT data->>'business_id', data FROM staging_business;"`
`psql -U postgres -d postgres -c "INSERT INTO review (review_id, review_data) SELECT data->>'review_id', data FROM staging_review;"`
`psql -U postgres -d postgres -c "INSERT INTO yuser (user_id, user_data) SELECT data->>'user_id', data FROM staging_user;"`

Isso foi feito para que possamos extrair os ids dos arquivos json específicos para uma coluna _id de cada tabela.

Para a tabela checkin, os dados são importados diretamente, visto que utilizamos um id serial.
`psql -U postgres -d postgres -c "\copy checkin(checkin_data) FROM '**<path>**/yelp_academic_dataset_checkin.json' csv quote e'\x01' delimiter e'\x02';"`

Podemos agora deletar as tabelas de preparação:
`psql -U postgres -d postgres -c "DROP TABLE staging_business;"`
`psql -U postgres -d postgres -c "DROP TABLE staging_review;"`
`psql -U postgres -d postgres -c "DROP TABLE staging_user;"`

É possível acessar os dados importados nos bancos postgres e mongodb utilizando ferramentas como pgadmin, compass, mongosh, entre outras. Para isso é importante lembrar de usar as portas mapeadas no docker-compose, 5440 para o postgres e 27020 para o mongodb.

Indexes PostgreSQL:
`CREATE INDEX idx_review_user_id_stars_above_4 ON review ((review_data->>'user_id')) WHERE (review_data->>'stars')::decimal >= 4.0;`
`CREATE INDEX idx_review_user_id ON review ((review_data->>'user_id'));`
`CREATE INDEX idx_business_id ON business (business_id);`
`CREATE INDEX idx_business_city ON business ((business_data->>'city'));`
`CREATE INDEX idx_checkin_business_id ON checkin ((checkin_data->>'business_id'));`
`CREATE INDEX idx_user_user_id ON yuser (user_id);`

Os usos dos índices foram descobertos através do comando `EXPLAIN ANALYZE` em cada query.

índices usados na query 1:
idx_review_user_id_stars_above_4
business_pkey
idx_review_user_id

índices usados na query 2:
idx_business_id
idx_business_city

índices usados na query 3:
idx_business_id
idx_business_city

índices usados na query 4:
idx_checkin_business_id
business_pkey

índices usados na query 5:
idx_review_user_id
idx_review_user_id_stars_above_4
business_pkey
idx_user_id

índices usados na query 6:
nenhum index usado

Vale observar que nas queries 1, 4 e 5 o index `business_pkey` foi usado, isso ocorre pois o plano de execução do postgresql utilizou a chave primária da tabela ao realizar os 'joins' nessas análises. Enquanto que nas queries 2 e 3, o index 'idx_business_id' criado foi utilizado nas cláusulas de 'where', quando havia necessidade de filtrar por um valor específico.

Indexes MongoDB:
`db.user.createIndex({ user_id: 1 });`
`db.review.createIndex({ business_id: 1 });`
`db.review.createIndex({ user_id: 1, stars: 1 });`
`db.business.createIndex({ business_id: 1 });`

Os usos dos índices foram descobertos através do comando `.explain("executionStats")` em cada aggregation. Por exemplo: `db.review.explain("executionStats").aggregate([``

índices usados na query 1:
user_reviewed_business:
	'user_id_1_stars_1',
	'business_id_1'

user_reviewed_city:
	'business_id_1'

índices usados na query 2:
--

índices usados na query 3:
user_review_count:
  `business_id_1`

final_query:
  `user_id_1`

índices usados na query 4:
  `business_id_1`

índices usados na query 5:
Mesmo fluxo da query 1.

índices usados na query 6:
--

