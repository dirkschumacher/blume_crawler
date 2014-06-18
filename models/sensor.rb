require 'mongoid'
class Sensor 
    include Mongoid::Document
    #has_many :sensor_data
    field :sensor_id, type: String
    validates_uniqueness_of :sensor_id
end