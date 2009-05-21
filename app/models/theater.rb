class Theater < ActiveRecord::Base
  
  attr_accessor :showtimes
  
  def self.showtimes(postal_code)
    response = HTTParty.get("http://new.api.movies.yahoo.com/v2/listTheatersByPostalCode?pcode=#{postal_code}&count=100&yprop=msapi")
    puts response.inspect;
    yids = response['TheaterList']['Theater'].map{|t| t['theater:id'].to_i}
    theaters = Theater.all(:conditions => {:yid => yids})
    
    theaters.each do |theater|
      data = response['TheaterList']['Theater'].detect{|t| t['theater:id'].to_i == theater.yid }
      
      theater.showtimes = 
        data['MovieList']['Movie'].map do |m| 
          { m['movie:Title'] => m['Shows']['Time'].map{|t| Time.parse(t).strftime('%I:%M') }}
        end rescue []
    end
    theaters
  end  
end