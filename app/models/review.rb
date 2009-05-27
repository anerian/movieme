class Review < ActiveRecord::Base
  belongs_to :movie, :counter_cache => true
end
