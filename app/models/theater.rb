class Theater < ActiveRecord::Base
  attr_accessor :distance
  
  has_many :shows
  
  define_index do
    indexes name
    indexes shows(:shown_on), :as => :shown_on
    
    has 'RADIANS(latitude)',  :as => :lat, :type => :float
    has 'RADIANS(longitude)', :as => :lng, :type => :float
    
    set_property :latitude_attr   => "lat"
    set_property :longitude_attr  => "lng"
  end
  
  
  def google_map_location
    [street, city, zip, state].reject{|r| r.blank?}.join(", ").strip.squeeze(" ")
  end
  
  # http://new.api.movies.yahoo.com/v2/listTheatersByPostalCode?mid=1809752801&pcode=20850&count=20&yprop=msapi
  def self.showtimes(postal_code, date = Date.today)
    begin
      response = HTTParty.get("http://new.api.movies.yahoo.com/v2/listTheatersByPostalCode?pcode=#{postal_code}&count=100&yprop=msapi&date=#{date.to_s(:date_yahoo)}")

      return response['TheaterList']['Theater'].map do |t|
        {
          :theater   => {
            :yid    => t['theater:id'].to_i,
            :name   => t['Name'],
            :phone  => t['Phone'],
            :street => (t['PostalAddress']['DeliveryAddress']['AddressLine'] rescue nil),
            :state  => t['Region'],
            :zip    => t['PostalCode']
          },
          :date      => date,
          :showtimes => (t['MovieList']['Movie'].map{|m|{ :mid => m['movie:id'].to_i, :title => m['movie:Title'], :times => m['Shows']['Time'].map{|t| Time.parse(t).strftime('%I:%M') }} } rescue [])
        }
      end.compact
    rescue Exception => e
    end
    []
  end  
  
  def self.zip_codes(zip = '01000')
    zip ||= '01000'
    select_column(:zip, connection.select_all("select distinct(zip) as zip from theaters where zip >= '#{zip}' AND zip <= '99999' order by zip asc")) || []
  end
  
  def self.nearby(lat, lng, date = Date.today)
    theaters = Theater.search('', :geo => [lat.to_radian, lng.to_radian], :order => "@geodist asc", :include => [:shows], :conditions => [%Q{shown_on = "#{Date.today.to_s(:date_yahoo)}"}])
    theaters.each_with_geodist do |theater, distance|
      theater.distance = (distance * 0.000621371192)
    end
    theaters
  end
  
  def self.select_column(column, rows)
    rows.collect{|h| h[column.to_s]}
  end
end