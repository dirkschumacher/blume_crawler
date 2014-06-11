require 'mongoid'
class Page 
    include Mongoid::Document
    field :content, type: String
    field :url, type: String
    field :date_download, type: DateTime
    validates_uniqueness_of :url
end