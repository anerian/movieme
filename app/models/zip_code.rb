class ZipCode < ActiveRecord::Base
  
  def coordinate
    [latitude.to_f, longitude.to_f]
  end
end
