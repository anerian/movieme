class Theater < ActiveRecord::Base
  
  def self.showtimes(postal_code)
    theaters = HTTParty.get("http://new.api.movies.yahoo.com/v2/listTheatersByPostalCode?pcode=#{postal_code}&count=100&yprop=msapi")
  end
  
end
