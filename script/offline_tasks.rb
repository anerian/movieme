ENV['RAILS_ENV'] ||= 'production'
puts "Loading with #{ENV['RAILS_ENV']} environment"

require File.dirname(__FILE__) + '/../config/environment.rb'
require 'httparty'
require 'curb'
require 'json'
require 'amazon/ecs'

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

  def refresh_times
    zip_codes = Theater.zip_codes
    zip_codes.compact!
    zip_codes.delete('')
    counter = 0
    while (zip = zip_codes.shift) do
      
      showtimes = Theater.showtimes(zip)
      showtimes.each do |s|
        theater = Theater.find_or_create_by_yid(s[:theater])
        
        s[:showtimes].each do |showtime|          
          movie = Movie.find_or_create_by_mid(
            :mid   => showtime[:mid],
            :title => showtime[:title]
          )
          show = theater.shows.first(:conditions => {:date => s[:date], :movie_id => movie.id})
          theater.shows.create(
            :movie => movie,
            :date  => s[:date],
            :times => showtime[:times].to_json
          ) if show.blank?
          
          zip_codes.delete(theater.zip)
        end if s[:showtimes] && theater
        
        logger.debug("Theater #{s[:tid]} not foud") if theater.blank?
      end
      counter += 1
      logger.debug("requesting: #{zip}")
      logger.debug("counter: #{counter}")
      sleep(1)
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

  def logger
    @logger = Logger.new(STDOUT)
  end
    
end

OfflineTasks.new(*ARGV).run