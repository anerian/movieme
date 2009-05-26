require 'open-uri'

class Movie < ActiveRecord::Base
  attr_accessor :image_url
  
  has_attached_file :image, 
                    :styles         => { :medium => "300x300>", :thumb => "100x100>" },
                    :storage        => :s3,
                    :s3_credentials => "#{RAILS_ROOT}/config/s3.yml",
                    :path           => ":attachment/:id/:style.:extension"
  
  before_validation :download_remote_image, :if => :image_url_provided?
  validates_presence_of :image_remote_url, :if => :image_url_provided?, :message => 'is invalid or inaccessible'
  
  private
    def image_url_provided?
      !self.image_url.blank?
    end

    def download_remote_image
      self.image = do_download_remote_image
      self.image_remote_url = image_url
    end

    def do_download_remote_image
      io = open(URI.parse(image_url))
      
      def io.original_filename; base_uri.path.split('/').last; end
      io.original_filename.blank? ? nil : io
    rescue Exception => e
      puts e
    end
end
