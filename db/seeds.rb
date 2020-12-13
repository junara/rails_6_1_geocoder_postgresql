require 'csv'
# "12/27/2018 4:51:00 PM"
def custom_to_date(denver_crime_datetime)
  ActiveSupport::TimeZone['Central Time (US & Canada)']
    .strptime(denver_crime_datetime, '%m/%d/%Y').to_date
end

def crime_params(row)
  wkt_parser = RGeo::WKRep::WKTParser.new(nil, support_ewkt: true)
  point = wkt_parser.parse("SRID=4326;Point(#{row['GEO_LON']} #{row['GEO_LAT']})")

  {
    incident_id: row['INCIDENT_ID'],
    offence_id: row['OFFENCE_ID'],
    offence_code: row['OFFENCE_CODE'],
    offence_code_extension: row['OFFENCE_CODE_EXTENSION'],
    offence_type_id: row['OFFENCE_TYPE_ID'],
    offence_category_id: row['OFFENCE_CATEGORY_ID'],
    first_occurrence_date: row['FIRST_OCCURRENCE_DATE'],
    incident_address: row['INCIDENT_ADDRESS'],
    district_id: row['DISTINCT_ID'],
    longitude: row['GEO_LON'],
    latitude: row['GEO_LAT'],
    location: point,
    is_crime: row['IS_CRIME'],
    is_traffic: row['IS_TRAFFIC'],
    created_at: Time.current,
    updated_at: Time.current
  }
end

filepath = 'crime.csv'
Crime.delete_all

list = []
CSV.foreach(filepath, headers: true).each do |row|
  next unless row['GEO_LON'].present? && row['GEO_LAT']

  list << crime_params(row)
  if list.size >= 100000
    Crime.insert_all!(list)
    list = []
  end
end
Crime.insert_all!(list) if list.present?

# 位置情報がないデータを削除
Crime.where(longitude: nil).delete_all
