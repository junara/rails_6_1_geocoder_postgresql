class Crime < ApplicationRecord
  geocoded_by :incident_address, latitude: :latitude, longitude: :longitude
end
