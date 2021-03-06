#!/usr/bin/env ruby

ENV['RAILS_ENV'] ||= 'development'
puts "Loading with #{ENV['RAILS_ENV']} environment"

require File.dirname(__FILE__) + '/../config/environment.rb'
require 'IMDB'

#59 23 * * * /srv/movieme/current/script/offline_tasks.rb refresh_times > /srv/movieme/current/log/refresh_showtimes.log 2>&1
class OfflineTasks
  def initialize(task, *params)
    @task = task
    @params = params
  end  
  
  def run
    if self.respond_to?(@task)
      self.send(@task)
    else
      $stderr.puts "No task defined for #{ @task }"
      exit(-1)
    end
  end
  
  def automerge
    unmapped_google_theaters = Theater.all(:conditions => 'gid is null and yid is not null')
    unmapped_google_theaters.each do |google_theater|
      yahoo_theater = Theater.first(:conditions => ['yid is not null and name like ? and zip = ? and id != ?', google_theater.name, google_theater.zip, google_theater.id])
      
      if yahoo_theater
        yahoo_theater.gid ||= google_theater.gid
        yahoo_theater.save
        google_theater.destroy
      end
    end
  end
  
  def geocode
    api_key = 'ABQIAAAAPbIrQY6Tw4qExHaj02Mk2hTJOCfMVGUIg4uV8tajlwAIMJR9eBSNs5gOX9cjCKfJ7QCBHlXuqEaxQQ'
    
    theaters = Theater.all(:conditions => {:latitude => nil}, :order => 'zip asc')
    theaters.each do |theater|
      logger.debug("retreiving geocode for #{theater.name}")
      logger.debug("address #{theater.google_map_location}")

      url ="http://maps.google.com/maps/geo?q=#{CGI.escape(theater.google_map_location)}&output=json&key=#{api_key}&oe=utf-8"

      json = JSON.parse(Curl::Easy.http_get(url).body_str)
      
      return_code = json["Status"]["code"]
      if return_code == 200
        coor = json["Placemark"].first["Point"]["coordinates"]
        theater.zip = (json["AddressDetails"]["AdministrativeArea"]["PostalCode"]["PostalCodeNumber"] rescue nil)
        theater.latitude = coor[1]
        theater.longitude = coor[0]
        theater.save
      end

      sleep(1.8)
    end
  end
  
  def scrape_imdb_theaters
    zip_codes = Theater.all(:group => :zip, :conditions => ['zip > "01000" and zip < "99999"']).map(&:zip)
    while (zip = zip_codes.shift) do
      logger.debug("ZIP: #{zip}")
      html = Curl::Easy.perform("http://www.imdb.com/showtimes/location/#{zip}/50m").body_str
      doc = Hpricot(html)
      (doc/"table.tabular").each do |table|
        theater_name = (table/"a.heading:first").inner_text
        theater_id = table.at('a.heading:first')['href'].split('/').last

        address_cell = (table/"td.address:first")
        theater_group = (address_cell/"a:first").inner_text.gsub('(', '').gsub(')', '')
        theater_zip = (address_cell/"a:last").inner_text
        
        (address_cell/"a").remove
        address = address_cell.inner_text.strip
        street, city, state = address.split(',').map(&:strip)
        
        theater = Theater.first(:conditions => ['(name = ? or street = ?) and zip = ?', theater_name, street, theater_zip])
        unless theater.blank?
          logger.debug("theater found: #{theater_name} with theater_id: #{theater_id}")
          
          theater.imdbid = theater_id
          theater.save
          zip_codes.delete(theater.zip)
        else
          logger.debug("theater create: #{theater_name}")
          Theater.create(
            :name   => theater_name,
            :imdbid => theater_id,
            :group  => theater_group,
            :street => street,
            :city   => city,
            :state  => state,
            :zip    => theater_zip
          )
        end        
      end
      sleep(1)
    end
  end

  def scrape_google_theaters
    (1..3).each do |n|
      zip_codes = Theater.all(:group => :zip, :conditions => ['zip > "01000" and zip < "99999"']).map(&:zip)
      while (zip = zip_codes.shift) do
        logger.debug("retreiving zip code: #{zip}, #{zip_codes.length} remaining")
        html = Curl::Easy.perform("http://google.com/movies?near=#{zip}&num=100&date=#{n}").body_str
        doc = Hpricot(html)
      
        theaters = []
      
        current_theater = {}
      
        (doc/"table[@cellpadding=3] tr").each do |row|
          first_cell = row.at('td:first')
          if first_cell['colspan'] == '4'
            font = first_cell.at('font:first')
            font.search('a').remove
            address, phone = font.inner_html.gsub('&nbsp;', ' ').split(' - ')
            street, city, state = address.split(',').map(&:strip)
          
            current_theater = {
              :name   => (first_cell.at('b').inner_text rescue nil),
              :phone  => phone,
              :street => street,
              :city   => city,
              :state  => state,
              :gid    => (first_cell.at('a:first')['href'].match(/tid=(\w+)$/)[1] rescue nil),
              :movies => []
            }
            theaters << current_theater
          else
            row.search("td[@valign='top']").each do |cell|
              trailer_link = cell.at('a.fl:first')
            
              movie = {
                :gid         => (cell.at('a:first')['href'].match(/mid=(\w+)$/)[1] rescue nil),
                :title       => (cell.at('a:first > b').inner_text rescue nil),
                :trailer_url => (((trailer_link && trailer_link.inner_text == 'Trailer') ? trailer_link['href'].gsub('/url?q=','') : nil) rescue nil),
                :imdbid      => (cell.inner_html.match(/http:\/\/www.imdb.com\/title\/([^\/]+)/)[1] rescue nil),
                :times       => (cell.at('font:first').inner_html.split('<br />').last.gsub(/<\/?[^>]*>/, "").gsub("&nbsp;", "").split(/\s+/) rescue nil)
              }
            
              current_theater[:movies] << movie
            end
          end
        end
        date = (Date.today + n)
        theaters.each do |data|
          movies = data.delete(:movies)
        
          theater = data[:gid].blank? ? nil : Theater.find_by_gid(data[:gid])
        
          theater ||= Theater.new(data)
          theater.attributes = data
          theater.save!
        
          movies.each do |movie_data|
            show_times = movie_data.delete(:times)
          
            movie = Movie.first(:conditions => ['(gid = ? and gid is not null) or imdbid = ? or title like ?', movie_data[:gid], movie_data[:imdbid], movie_data[:title]])
            if movie.blank?
              movie = Movie.create(movie_data)
            else
              movie.update_attributes(movie_data)
            end
          
            show = theater.shows.first(:conditions => {:shown_on => date, :movie_id => movie.id})

            if show.blank?
              show = theater.shows.new(
                :movie     => movie,
                :shown_on  => date,
                :times     => show_times.to_json
              ) 
              show.shown_on = date
            else
              show.times = show_times.to_json
            end
          
            show.save
          end
        
          unless theater.zip.blank?
            zip_codes.delete(theater.zip)
          end
        end
      
        sleep(1)
      end
    end
  end
  
  def refresh_times
    begin
      latest_migration = TimeMigration.last

      # determine the previous state
      status, range = 
        if latest_migration.blank?
          [:new, current_date..Date.today+3]
        elsif latest_migration.completed_at.blank?
          [:error, latest_migration.migrated_at..Date.today+3]
        else
          [:completed, [latest_migration.migrated_at+1, Date.today].max..Date.today+3]
        end
      
      logger.debug("previous status: #{status}")
      logger.debug("range: #{range}")
      
      range.each_with_index do |date, i|
        time_migration = (status == :error) ? latest_migration : TimeMigration.create(:migrated_at => date)
        
        logger.debug("refreshing show times for: #{date.to_s(:date_yahoo)}")
        latest_zip = (status == :error && i == 0) ? latest_migration.last_zip : nil

        zip_codes = Theater.zip_codes(latest_zip)
        zip_codes.compact!
        zip_codes.delete('')
        
        while (zip = zip_codes.shift) do
          logger.debug("#{zip_codes.length} zip codes remaining")
          showtimes = Theater.showtimes(zip, date)

          showtimes.each do |s|
            theater = Theater.find_or_create_by_yid(s[:theater])
        
            s[:showtimes].each do |showtime|          
              movie = Movie.find_or_create_by_yid(
                :yid   => showtime[:mid],
                :title => showtime[:title]
              )
              show = theater.shows.first(:conditions => {:shown_on => date, :movie_id => movie.id})
              
              if show.blank?
                show = theater.shows.new(
                  :movie     => movie,
                  :shown_on  => date,
                  :times     => showtime[:times].to_json
                ) 
                show.shown_on = date
              else
                show.times = showtime[:times].to_json
              end
              
              show.save
              zip_codes.delete(theater.zip)
            end if s[:showtimes] && theater
        
            logger.debug("Theater #{s[:tid]} not found") if theater.blank?
          end
              
          time_migration.update_attribute(:last_zip, zip)
          
          sleep(1)
        end
        status = :completed
        time_migration.update_attribute(:completed_at, Time.now)
      end
    rescue Exception => e
      logger.debug("error: #{e}")
    end
  end
  
  def ingest
    # ActiveRecord::Base.connection.execute "TRUNCATE theaters;"
    
    (1..9829).each do |id|
      next unless File.exists? "#{RAILS_ROOT}/db/data/theaters/yahoo-#{id}.html"
      doc = File.read "#{RAILS_ROOT}/db/data/theaters/yahoo-#{id}.html"
      
      addr = /<td class=ygfa>&nbsp;<small>\s*([^\[]+)/.match(doc)[1].gsub(/&nbsp;/, '').split(/,/)
      
      Theater.find_or_create_by_yid(
        :yid    => id,
        :name   => /<td nowrap class=ygfa>\s*<b>([^<]+)<\/b>/.match(doc)[1].squish,
        :street => addr[0].squish,
        :city   => addr[1].squish,
        :state  => addr[2].squish,
        :zip    => addr[3].squish,
        :phone  => (/<td class=ygfa align=right>\s*<small>([^<]+)/.match(doc)[1].squish rescue nil)
      )
    end
  end
  
  def scrape_boxoffice_info
    html = HTTParty.get("http://www.rottentomatoes.com/movie/box_office.php")
    doc = Hpricot(html)
    date = (doc/"div.header_text:first").inner_text.gsub("Weekend of","").strip

    weekend = Weekend.find_or_create_by_weekend_at(Date.parse(date))
    
    (doc/"table.proViewTbl:first tbody tr").each_with_index do |row, index|
      this_week, last_week, tmeter, title, num_weeks, weekend_gross, total_gross, theater_avg, num_theaters = row.search('td')

      movie = Movie.find_or_create_by_title(title.inner_text)
      movie.gross = total_gross.inner_text.gsub(/[^(\d.)]/, '')
      movie.save
      
      weekend.movie_items.find_or_create_by_movie_id(
        :last_week => last_week.inner_text == 'new' ? nil : this_week.inner_text,
        :this_week => this_week.inner_text,
        :weeks_released => num_weeks.inner_text,
        :weekend_gross => weekend_gross.inner_text.gsub(/[^(\d.)]/, ''),
        :theater_average => theater_avg.inner_text.gsub(/[^(\d.)]/, ''),
        :movie_id => movie.id
      )
    end
  end
  
  def scrape_rottentomatoes
    movies = Movie.all(:conditions => 'imdbid is not null and reviews_count = 0')
    movies.each do |movie|
      logger.debug("#{movie.title}")

      request = Curl::Easy.perform("http://www.rottentomatoes.com/alias?type=imdbid&s=#{movie.imdbid.gsub('tt','')}") do |curl|
        curl.follow_location = true
      end
      url = request.last_effective_url
      
      unless url.match(/rottentomatoes.com\/search/)
        html = request.body_str        
        movie.tmeter = html.match(/<span class="percent">([^<]+)<\/span>/)[1] rescue nil
        movie.save
        
        reviews_url = "#{url}?critic=creamcrop#contentReviews"
        reviews_response = HTTParty.get(reviews_url)
        
        doc = Hpricot(reviews_response)
        (doc/"div.quoteBubble").each do |quote|
          quote_html = quote.inner_html
          comment = (quote_html.match(/<p>\s*([^<]+)/)[1].strip) rescue nil
          
          if !comment.blank? && (comment != 'Click to read the article')
            begin
            review = movie.reviews.create(
              :author      => (quote/"div.author > a:first").inner_text,
              :source      => (quote/"div.source > a:first").inner_text,
              :comment     => comment,
              :reviewed_on => Chronic.parse((quote_html.match(/<div class="date">\s*([^<]+)/)[1].strip rescue nil))
            ) 
            rescue
              logger.debug("error in saving review")
            end
          end
        end
      end

      sleep(1)
    end
  end
  
  # IMDB
  # http://www.trynt.com/movie-imdb-api/v2/?t=#{movie.title}&fo=json
  # http://www.trynt.com/movie-imdb-api/v2/?id=
  #
  # Yahoo
  # http://new.api.movies.yahoo.com/v2/movieDetails?mid=#{movie.yid}&yprop=msapi
  #
  # PostersDB
  # http://api.movieposterdb.com/json.inc.php?imdb=0308353
  #
  # Rottentomatoes
  # http://www.rottentomatoes.com/alias?type=imdbid&s=0438488
  def scrape_movie_info
    movies = Movie.all(:conditions => {:processed => false})
    movies.each do |movie|
      logger.debug("updating movie: #{movie.title}")
      yahoo_response = HTTParty.get("http://new.api.movies.yahoo.com/v2/movieDetails?mid=#{movie.yid}&yprop=msapi")
      if (details = yahoo_response["MovieDetails"])
        movie.title = details["TitleList"]["Title"]
        movie.distributor = details["Distributor"]
        movie.synopsis = details["Synopsis"]
        movie.rating = (details["RatingList"]["Rating"] rescue nil)
              
        genre = (details["GenreList"]["Genre"] rescue nil)
        
        unless genre.blank?
          movie.tag_list = genre.is_a?(Array) ? genre.join(",") : genre
        end
        
        actors = details["CastAndCrew"]["CreditList"].detect{|c| c["job"] == "actor"} rescue nil
        unless actors.blank?
          movie.actors = actors["Credit"].map{|credit| credit["Name"]}.to_json rescue nil
        end
        
        if movie.image_url.blank?
          movie.image_url = (details["Photos"]["Poster"]["Image"].first rescue nil)
        end
      end

      begin
        imdb = IMDB.new(movie.title)
        movie.released_at = imdb.date
        movie.duration = imdb.runtime.gsub(/[^\d]/, '').to_i
        movie.imdbid = imdb.imdb_link.match(/title\/([^\/]+)\//)[1] rescue nil
      rescue
        logger.debug("cannot find imdb info for #{movie.title}")
      end
      
      url = "http://movies.yahoo.com/movie/#{movie.yid}/details"
      response = HTTParty.get(url)
      
      gross = response.match(/U.S. Box Office:<\/b><\/font><\/td>\s*<td valign="top"><font face=arial size=-1>([^<]+)/)[1] rescue nil
      unless gross.blank?
        gross.gsub!(/[^\d]/, '')
        movie.gross = gross
      end
      
      sleep(1)
      movie.processed = true      
      movie.save
    end
    
    scrape_rottentomatoes
  end
  
  # http://movies.yahoo.com/movie/1809953162/video
  def scrape_trailers
  end

  def logger
    @logger = Logger.new(STDOUT)
  end
    
end

OfflineTasks.new(*ARGV).run