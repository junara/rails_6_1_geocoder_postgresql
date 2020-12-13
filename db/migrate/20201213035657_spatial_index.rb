class SpatialIndex < ActiveRecord::Migration[6.0]
  def up
    add_column :crimes, :location, :st_point, srid: 4326, geographic: true
    add_index :crimes, :location, using: :gist
  end

  def down
    remove_column :crimes, :location
  end

  # def update_crime_locations
  #   Crime.find_each do |crime|
  #     next unless crime.latitude.present? && crime.longitude.present?
  #     wkt_parser = RGeo::WKRep::WKTParser.new(nil, support_ewkt: true)
  #     point = wkt_parser.parse("SRID=4326;Point(#{crime.longitude.to_s} #{crime.latitude.to_s})")
  #     crime.update!(location: point)
  #   end
  # end
  #
  # def up
  #   wkt_parser = RGeo::WKRep::WKTParser.new(nil, support_ewkt: true)
  #   point = wkt_parser.parse('SRID=4326;Point(123.456 78.9)')
  #   add_column :crimes, :location, :geometry, srid: 4326
  #   Crime.update_all(location: point)
  #   change_column :crimes, :location, :geometry, null: false
  #   add_index :crimes, :location, type: :spatial
  #   update_crime_locations
  # end
  #
  # def down
  #   remove_column :crimes, :location
  # end
end
