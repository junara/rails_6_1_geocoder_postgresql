# 概要

近傍の場所を検索する時に、位置情報の計算をPostGISに任せれば早くなると思ったけどそうじゃなかったということ

## 環境準備

```
docker-compose build
docker-compose up -d
dcoker-compose exec web rails db:migrate:reset
```

https://www.denvergov.org/opendata/dataset/city-and-county-of-denver-crime

Crime - Comma-Separated Values をダウンロードして  `crime.csv`  のファイル名でレポジトリの 第1階層におく

```
dcoker-compose exec web rails db:seeds
```

## やったこと

* PostGIS
    * Indexアリ → ソートなし、距離でソート、idでソート
    * Indexなし → ソートなし、距離でソート、idでソート
* Geocoder
    * ソートなし、距離でソート、idでソート

## 結果

* PostGISは近傍から何番目を検索→indexないほうが良い。 近傍全て→indexありがよい
    * ソートしないならば、indexがある方が10倍以上早い（indexなし Time 62.202 ms vs indexありTime: 1.414 ms）
    * ソートするならば、indexがない方がむしろ早い！（indexなし Time: 756.594 msvs indexありTime: 2189.692 ms）
* 距離でソートして近傍を選ぶならば Geocoderが最も早い (Geocoder Time: 690.986 ms vs indexなし Time: 756.594 msvs indexありTime: 2189.692 ms )
*
* Geocoder
* gemは、距離計算を全ての行で行って、その値でソートすることで近傍の

# 検討内容

## indexがないばあい

```sql
drop index index_crimes_on_location;
```

### ソートなし

```sql
select id, ST_Distance('SRID=4326;POINT(139.777254 35.713768)', location) as dist
from crimes
where ST_DWithin(location, ST_GeographyFromText('SRID=4326;POINT(139.777254 35.713768)'), 100000000) LIMIT 3;

```

```
   id   |       dist       
--------+------------------
 101986 | 9351180.31996026
 101987 | 9353387.11449527
 101988 | 9347753.83668578
(3 rows)

Time: 62.202 ms

```

### 距離でソート

```sql
select id, ST_Distance('SRID=4326;POINT(139.777254 35.713768)', location) as dist
from crimes
where ST_DWithin(location, ST_GeographyFromText('SRID=4326;POINT(139.777254 35.713768)'), 100000000)
ORDER BY dist LIMIT 3;

```

```
   id   |       dist       
--------+------------------
 365880 |  8992906.4603111
 328818 | 9326065.87658406
 191509 | 9327827.01973084
(3 rows)

Time: 756.594 ms
```

### idでソート

```sql
select id, ST_Distance('SRID=4326;POINT(139.777254 35.713768)', location) as dist
from crimes
where ST_DWithin(location, ST_GeographyFromText('SRID=4326;POINT(139.777254 35.713768)'), 100000000)
ORDER BY id LIMIT 3;

```

```
  id  |       dist       
------+------------------
 1091 | 9352356.26166662
 1092 | 9342478.17419527
 1093 | 9344080.70745787
(3 rows)

Time: 358.192 ms

```

## indexがある場合

```sql
create
index index_crimes_on_location on crimes using gist(location);
```

### ソートなし

```sql
 select id, ST_Distance('SRID=4326;POINT(139.777254 35.713768)', location) as dist
 from crimes
 where ST_DWithin(location, ST_GeographyFromText('SRID=4326;POINT(139.777254 35.713768)'), 100000000) LIMIT 3;
```

```
   id   |       dist       
--------+------------------
 102011 | 9341952.45247108
 102126 | 9343791.18985646
 102127 | 9345003.00591813
(3 rows)

Time: 1.414 ms

```

### 距離でソート

```sql
select id, ST_Distance('SRID=4326;POINT(139.777254 35.713768)', location) as dist
from crimes
where ST_DWithin(location, ST_GeographyFromText('SRID=4326;POINT(139.777254 35.713768)'), 100000000)
ORDER BY dist LIMIT 3;

```

```
   id   |       dist       
--------+------------------
 365880 |  8992906.4603111
 328818 | 9326065.87658406
 104611 | 9327827.01973084
(3 rows)

Time: 2189.692 ms (00:02.190)
```

```
select id,  ST_Distance('SRID=4326;POINT(139.777254 35.713768)', location) as dist from crimes                                                                                                                                                                                                                        where ST_DWithin(location, ST_GeographyFromText('SRID=4326;POINT(139.777254 35.713768)'), 100000000)ORDER BY id LIMIT 3;
```

### idでソート

```
  id  |       dist       
------+------------------
 1091 | 9352356.26166662
 1092 | 9342478.17419527
 1093 | 9344080.70745787
(3 rows)

Time: 1005.160 ms (00:01.005)


```

## GeocoderでソートするときのSQL

### ソートなし

```sql
SELECT crimes.*,
       6371.0 * 2 * ASIN(SQRT(POWER(SIN((35.713768 - crimes.latitude) * PI() / 180 / 2), 2) +
                              COS(35.713768 * PI() / 180) * COS(crimes.latitude * PI() / 180) *
                              POWER(SIN((139.777254 - crimes.longitude) * PI() / 180 / 2), 2))) AS distance,
       MOD(CAST((ATAN2(((crimes.longitude - 139.777254) / 57.2957795), ((crimes.latitude - 35.713768) / 57.2957795)) *
                 57.2957795) + 360 AS decimal), 360)                                            AS bearing
FROM "crimes"
WHERE (crimes.latitude BETWEEN -899285.8921507305 AND 899357.3196867305 AND
       crimes.longitude BETWEEN -1107476.5153560967 AND 1107756.0698640968 AND (6371.0 * 2 * ASIN(SQRT(
                POWER(SIN((35.713768 - crimes.latitude) * PI() / 180 / 2), 2) +
                COS(35.713768 * PI() / 180) * COS(crimes.latitude * PI() / 180) *
                POWER(SIN((139.777254 - crimes.longitude) * PI() / 180 / 2), 2)))) BETWEEN 0.0 AND 100000000) LIMIT 3;

```

```
   id   | incident_id | offence_id | offence_code | offence_code_extension | offence_type_id | offence_category_id | first_occurrence_date | incident_address |   longitude   |  latitude   | district_id | is_crime | is_traffic |
         created_at         |         updated_at         |                      location                      |     distance     |     bearing      
--------+-------------+------------+--------------+------------------------+-----------------+---------------------+-----------------------+------------------+---------------+-------------+-------------+----------+------------+
----------------------------+----------------------------+----------------------------------------------------+------------------+------------------
 101986 |  2015423520 |            |              |                        |                 |                     |                       | 1768 N SPRUCE ST | -104.89723300 | 39.74504550 |             | t        | f          |
 2020-12-13 04:07:52.01869  | 2020-12-13 04:07:52.018702 | 0101000020E610000016F9F5436C395AC01844A4A65DDF4340 |  9329.8328018227 | 270.943924712901
 101987 |  2015536122 |            |              |                        |                 |                     |                       |                  | -104.80595420 | 39.79251080 |             | t        | f          |
 2020-12-13 04:07:52.018799 | 2020-12-13 04:07:52.018808 | 0101000020E6100000BAC4ECC094335AC008DD6FFE70E54340 |  9332.0258531754 | 270.955393033903
 101988 |  2017127070 |            |              |                        |                 |                     |                       | 3481 S FENTON ST | -105.05844100 | 39.65453460 |             | t        | f          |
 2020-12-13 04:07:52.018907 | 2020-12-13 04:07:52.018919 | 0101000020E6100000B7EF517FBD435AC0DB8C2ECAC7D34340 | 9326.43109257001 | 270.922127813337
(3 rows)

Time: 1.063 ms
```

### 距離でソート

orderをdistace

```sql
SELECT crimes.*,
       6371.0 * 2 * ASIN(SQRT(POWER(SIN((35.713768 - crimes.latitude) * PI() / 180 / 2), 2) +
                              COS(35.713768 * PI() / 180) * COS(crimes.latitude * PI() / 180) *
                              POWER(SIN((139.777254 - crimes.longitude) * PI() / 180 / 2), 2))) AS distance,
       MOD(CAST((ATAN2(((crimes.longitude - 139.777254) / 57.2957795), ((crimes.latitude - 35.713768) / 57.2957795)) *
                 57.2957795) + 360 AS decimal), 360)                                            AS bearing
FROM "crimes"
WHERE (crimes.latitude BETWEEN -899285.8921507305 AND 899357.3196867305 AND
       crimes.longitude BETWEEN -1107476.5153560967 AND 1107756.0698640968 AND (6371.0 * 2 * ASIN(SQRT(
                POWER(SIN((35.713768 - crimes.latitude) * PI() / 180 / 2), 2) +
                COS(35.713768 * PI() / 180) * COS(crimes.latitude * PI() / 180) *
                POWER(SIN((139.777254 - crimes.longitude) * PI() / 180 / 2), 2)))) BETWEEN 0.0 AND 100000000)
order by distance LIMIT 3;

```

```
   id   | incident_id | offence_id | offence_code | offence_code_extension | offence_type_id | offence_category_id | first_occurrence_date | incident_address |   longitude   |  latitude   | district_id | is_crime | is_traffic |
         created_at         |         updated_at         |                      location                      |     distance     |     bearing      
--------+-------------+------------+--------------+------------------------+-----------------+---------------------+-----------------------+------------------+---------------+-------------+-------------+----------+------------+
----------------------------+----------------------------+----------------------------------------------------+------------------+------------------
 365880 |  2019507759 |            |              |                        |                 |                     | 2019-11-08            |                  | -115.46406020 | 34.63823570 |             | t        | f          |
 2020-12-13 04:09:52.706284 | 2020-12-13 04:09:52.706294 | 0101000020E610000004988D29B3DD5CC0E15119B5B1514140 | 8973.38183730183 | 269.758569290676
 328818 |  2018286790 |            |              |                        |                 |                     |                       | 26771 GENESEE LN | -105.32179720 | 39.72117060 |             | t        | f          |
 2020-12-13 04:09:47.505528 | 2020-12-13 04:09:47.505541 | 0101000020E6100000717C485398545AC019EB76514FDC4340 | 9304.77098425005 | 270.936710292694
 191509 |  2015523269 |            |              |                        |                 |                     | 2015-09-09            | 26771 GENESEE LN | -105.30059340 | 39.71561040 |             | t        | f          |
 2020-12-13 04:08:04.893901 | 2020-12-13 04:08:04.893911 | 0101000020E61000002E9919EC3C535AC0B856201F99DB4340 | 9306.52988669639 | 270.935491770985
(3 rows)

Time: 690.986 ms

```

### idでソート

```sql
SELECT crimes.*,
       6371.0 * 2 * ASIN(SQRT(POWER(SIN((35.713768 - crimes.latitude) * PI() / 180 / 2), 2) +
                              COS(35.713768 * PI() / 180) * COS(crimes.latitude * PI() / 180) *
                              POWER(SIN((139.777254 - crimes.longitude) * PI() / 180 / 2), 2))) AS distance,
       MOD(CAST((ATAN2(((crimes.longitude - 139.777254) / 57.2957795), ((crimes.latitude - 35.713768) / 57.2957795)) *
                 57.2957795) + 360 AS decimal), 360)                                            AS bearing
FROM "crimes"
WHERE (crimes.latitude BETWEEN -899285.8921507305 AND 899357.3196867305 AND
       crimes.longitude BETWEEN -1107476.5153560967 AND 1107756.0698640968 AND (6371.0 * 2 * ASIN(SQRT(
                POWER(SIN((35.713768 - crimes.latitude) * PI() / 180 / 2), 2) +
                COS(35.713768 * PI() / 180) * COS(crimes.latitude * PI() / 180) *
                POWER(SIN((139.777254 - crimes.longitude) * PI() / 180 / 2), 2)))) BETWEEN 0.0 AND 100000000)
order by id LIMIT 3;

```

```
  id  | incident_id | offence_id | offence_code | offence_code_extension | offence_type_id | offence_category_id | first_occurrence_date |    incident_address     |   longitude   |  latitude   | district_id | is_crime | is_traf
fic |         created_at         |         updated_at         |                      location                      |     distance     |     bearing      
------+-------------+------------+--------------+------------------------+-----------------+---------------------+-----------------------+-------------------------+---------------+-------------+-------------+----------+--------
----+----------------------------+----------------------------+----------------------------------------------------+------------------+------------------
 1091 |  2018869789 |            |              |                        |                 |                     |                       | 2681 N HANOVER CT       | -104.86615590 | 39.75556140 |             | t        | f      
    | 2020-12-13 04:07:02.732299 | 2020-12-13 04:07:02.732352 | 0101000020E610000032EF27196F375AC05B8F673CB6E04340 | 9331.00439118989 | 270.946506764211
 1092 |  2015664356 |            |              |                        |                 |                     |                       | 4100 BLOCK W COLFAX AVE | -105.04075970 | 39.73999120 |             | f        | t      
    | 2020-12-13 04:07:02.732428 | 2020-12-13 04:07:02.732432 | 0101000020E6100000AA9F92CE9B425AC0F5A91908B8DE4340 | 9321.14822517785 | 270.942188870196
 1093 | 20176005213 |            |              |                        |                 |                     | 2017-08-06            | 1705 17TH ST            | -104.99926360 | 39.75366910 |             | t        | f      
    | 2020-12-13 04:07:02.732515 | 2020-12-13 04:07:02.732526 | 0101000020E6100000548550EFF33F5AC0BD40A43A78E04340 | 9322.74495696943 | 270.945549336999
(3 rows)

Time: 1.154 ms

```

## 実験

### indexをgeography

```sql
create
index geo_index_crimes_on_location on crimes using gist(geography(location));
```

https://gis.stackexchange.com/questions/247113/setting-up-indexes-for-postgis-distance-queries/247131#247131



