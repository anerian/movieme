class Show < ActiveRecord::Base
  belongs_to :theater
  belongs_to :movie
  
  def data
    @data ||= JSON.parse(self.times)
  end
end
