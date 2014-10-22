require File.dirname(__FILE__) + "/../lib/mongo_mapper/eager_include"

class User
  include MongoMapper::Document
  has_many :posts
  has_one :user_profile

  has_many :items, :foreign_key => :owner_id
end

class UserProfile
  include MongoMapper::Document
  belongs_to :user
end

class Post
  include MongoMapper::Document
  belongs_to :user
end

class Item
  include MongoMapper::Document
  belongs_to :owner
end

RSpec.configure do |config|
  def wipe_db
    MongoMapper.database.collections.each do |c|
      unless (c.name =~ /system/)
        c.remove({})
      end
    end
  end

  config.before(:all) do
    MongoMapper.connection = Mongo::Connection.new('localhost')
    MongoMapper.database = "mm_eager_include"
  end

  config.before(:each) do
    wipe_db
  end
end
