class User
  include Mongoid::Document
  field :uid, type: String
  field :name, type: String
  field :access_token, type: String
end
