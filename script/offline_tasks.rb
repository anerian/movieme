#!/usr/bin/env ruby

ENV['RAILS_ENV'] ||= 'development'
puts "Loading with #{ENV['RAILS_ENV']} environment"

require File.dirname(__FILE__) + '/../config/environment.rb'
require 'IMDB'

#59 23 * * * /var/www/apps/movieme/current/script/offline_tasks.rb refresh_times > /var/www/apps/movieme/current/log/refresh_showtimes.log 2>&1
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

        theater.latitude = coor[1]
        theater.longitude = coor[0]
        theater.save
      end

      sleep(1.8)
    end
  end
  
  def scrape_google_theaters
    zip_codes = Theater.all(:group => :zip, :conditions => ['zip > "01000" and zip < "99999"']).map(&:zip)

    while (zip = zip_codes.shift) do
      puts "updating theaters near #{zip}, #{zip_codes.length} zip codes remaining"
      # sleep(1)
      
      html = Curl::Easy.perform("http://google.com/movies?near=#{zip}").body_str
      matches = html.scan(/tid=([^"]+)"><b dir=ltr>([^<]+)<\/\s*b>\s*<\/a>\s*<br><font size=-1>([^<]+)/)
      matches.each do |tid, title, info|

        info.gsub!('&nbsp;', ' ')
        info.gsub!('&amp;', '&')
        info.gsub!('&#39;', "'")
        title.gsub!('&nbsp;', ' ')
        title.gsub!('&amp;', '&')
        title.gsub!('&#39;', "'")
        
        theater = Theater.first(:conditions => {:name => title, :zip => zip})
        unless theater.blank?
          theater.update_attribute(:gid, tid)

          zip_codes.delete(theater.zip)
        end
        
        
        # puts "creating #{title}"
        # addr = info.split(/ - /)[0].split(/,/)
        # phone = (info.split(/ - /)[1].squish rescue nil)
        # 
        # begin
        # theater = Theater.create(
        #   :name   => title,
        #   :tid    => tid,
        #   :street =>    addr[0].squish,
        #   :city   => addr[1].squish,
        #   :state  => addr[2].squish,
        #   :phone  => (info.split(/ - /)[1].squish rescue nil)
        # )
        # rescue Exception => e
        # end

      end
      sleep(0.25)
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
              movie = Movie.find_or_create_by_mid(
                :mid   => showtime[:mid],
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
                show.save
              end
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
      yahoo_response = HTTParty.get("http://new.api.movies.yahoo.com/v2/movieDetails?mid=#{movie.mid}&yprop=msapi")
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
      
      url = "http://movies.yahoo.com/movie/#{movie.mid}/details"
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