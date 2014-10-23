require File.dirname(__FILE__) + "/../lib/mongo_mapper/eager_includer"

class User
  include MongoMapper::Document

  has_many :posts
  has_many :items, :foreign_key => :owner_id
  has_many :orders, :foreign_key => :customer_id
  has_one :user_profile
end

class Tree
  include MongoMapper::Document

  key :bird_ids, Array

  has_many :birds, :in => :bird_ids
end

class Bird
  include MongoMapper::Document
  belongs_to :tree
end

class UserProfile
  include MongoMapper::Document
  belongs_to :user
end

class OwnerProfile
  include MongoMapper::Document
  belongs_to :owner
end

class Post
  include MongoMapper::Document
  belongs_to :user
end

class Item
  include MongoMapper::Document
  belongs_to :owner, :class_name => "User"
end

class Order
  include MongoMapper::Document
  belongs_to :customer, :class_name => "User"
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
