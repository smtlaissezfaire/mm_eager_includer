require 'pry-byebug'

require Bundler.root + 'lib/mongo_mapper/eager_includer'
require Bundler.root + 'spec/support/mongo_mapper_duplicate_query_fix'
require Bundler.root + 'spec/support/mongo_query_log'
require Bundler.root + 'spec/support/mongo_query_log_matchers'


class User
  include MongoMapper::Document
  key :name, String
  has_many :posts
  has_many :items, :foreign_key => :owner_id
  key :order_ids, Array
  has_many :orders, :in => :order_ids
  has_one :user_profile
end

class Post
  include MongoMapper::Document
  key :title, String
  belongs_to :user
end

class UserProfile
  include MongoMapper::Document
  key :phone_number, String
  belongs_to :user
end

class Item
  include MongoMapper::Document
  key :name, String
  belongs_to :owner, :class_name => "User"
end

class Order
  include MongoMapper::Document
  key :order_number, String
  belongs_to :user
end

MongoMapper.connection = Mongo::Connection.new('localhost')
MongoMapper.database = "mm_eager_include"

def wipe_db
  MongoMapper.database.collections.each do |c|
    c.remove({}) unless (c.name =~ /system/)
  end
end

RSpec.configure do |config|
  config.before(:each) do
    wipe_db
    MongoQueryLog.clear!
  end
end
