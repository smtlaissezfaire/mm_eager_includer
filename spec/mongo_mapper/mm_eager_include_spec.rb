require 'spec_helper'

describe MongoMapper::EagerIncluder do

  it 'should have awesome custom matchers' do
    expect{ }.to_not perform_any_mongo_queries

    expect{ User.first }.to perform_these_mongo_queries(
      {collection: :users, selector: {}},
    )

    user = User.create!
    UserProfile.create! user: user
    expect{
      User.first.user_profile
    }.to perform_these_mongo_queries(
      {collection: :users, selector: {}},
      {collection: :user_profiles, selector: {user_id: user.id}},
    )
  end

  it 'should raise when given a Plucky::Query' do
    users = User.where()
    expect{
      MongoMapper::EagerIncluder.eager_include(users, :nest)
    }.to raise_error("You must call `to_a` on `Plucky::Query` objects before passing to eager_include")
  end

  context 'eager loading a' do
    before do
      # has_many
      @user_to_posts_map = {}
      # has_many with foreign key
      @user_to_items_map = {}
      # has_many_in
      @user_to_orders_map = {}
      # has_one
      @user_to_user_profile_map = {}
      # belongs_to
      @item_to_user_map = {}

      3.times do
        user = User.create!

        posts = 3.times.map do
          Post.create! user: user
        end
        # has_many
        @user_to_posts_map[user] = posts

        items = 3.times.map do
          item = Item.create! owner: user
          # belongs_to
          @item_to_user_map[item] = user
          item
        end
        # has_many with foreign key
        @user_to_items_map[user] = items

        orders = 3.times.map do
          Order.create!
        end
        user.orders = orders
        user.save!
        # has_many_in
        @user_to_orders_map[user] = orders

        user_profile = UserProfile.create! user: user
        # has_one
        @user_to_user_profile_map[user] = user_profile
      end
    end

    describe 'has_many relationship' do
      it 'should only do one query' do
        users = User.all
        posts = nil

        expect{
          MongoMapper::EagerIncluder.eager_include(users, :posts)
        }.to perform_these_mongo_queries(
          {collection: :posts, selector: {user_id: {"$in"=> users.map(&:id)}}},
        )

        expect{
          posts = users.map(&:posts)
        }.to_not perform_any_mongo_queries

        Hash[users.zip(posts)].should eq @user_to_posts_map

        expect{
          MongoMapper::EagerIncluder.eager_include(users, :posts)
        }.to_not perform_any_mongo_queries
      end
    end

    describe 'has_many with a foreign key relationship' do
      it 'should only do one query' do
        users = User.all
        items = nil

        expect{
          MongoMapper::EagerIncluder.eager_include(users, :items)
        }.to perform_these_mongo_queries(
          {collection: :items, selector: {owner_id: {"$in"=> users.map(&:id)}}},
        )

        expect{
          items = users.map(&:items)
        }.to_not perform_any_mongo_queries

        Hash[users.zip(items)].should eq @user_to_items_map

        expect{
          MongoMapper::EagerIncluder.eager_include(users, :items)
        }.to_not perform_any_mongo_queries
      end

      it 'should accept a block to modify the mongo query' do
        users = User.all
        expect{
          MongoMapper::EagerIncluder.eager_include(users, :items) do |query|
            query.fields(:name)
          end
        }.to perform_these_mongo_queries(
          {collection: :items, selector: {owner_id: {"$in"=> users.map(&:id)}}, :fields=>{ name: 1 }},
        )
      end
    end

    describe 'has_many_in relationship' do
      it 'should only do one query' do
        users = User.all
        orders = nil

        expect{
          MongoMapper::EagerIncluder.eager_include(users, :orders)
        }.to perform_these_mongo_queries(
          {collection: :orders, selector: {_id: {"$in"=> users.map(&:order_ids).flatten}}},
        )

        expect{
          orders = users.map(&:orders)
        }.to_not perform_any_mongo_queries

        Hash[users.zip(orders)].should eq @user_to_orders_map

        expect{
          MongoMapper::EagerIncluder.eager_include(users, :orders)
        }.to_not perform_any_mongo_queries
      end

      it 'should accept a block to modify the mongo query' do
        users = User.all
        expect{
          MongoMapper::EagerIncluder.eager_include(users, :orders) do |query|
            query.fields(:order_number)
          end
        }.to perform_these_mongo_queries(
          {collection: :orders, selector: {_id: {"$in"=> users.map(&:order_ids).flatten}}, :fields=>{ order_number: 1 }},
        )
      end
    end

    describe 'has_one relationship' do
      it 'should only do one query' do
        users = User.all
        user_profiles = nil

        expect{
          MongoMapper::EagerIncluder.eager_include(users, :user_profile)
        }.to perform_these_mongo_queries(
          {collection: :user_profiles, selector: {user_id: {"$in"=> users.map(&:id)}}},
        )

        expect{
          user_profiles = users.map(&:user_profile)
        }.to_not perform_any_mongo_queries

        Hash[users.zip(user_profiles)].should eq @user_to_user_profile_map

        expect{
          MongoMapper::EagerIncluder.eager_include(users, :user_profile)
        }.to_not perform_any_mongo_queries
      end

      it 'should accept a block to modify the mongo query' do
        users = User.all
        expect{
          MongoMapper::EagerIncluder.eager_include(users, :user_profile) do |query|
            query.fields(:phone_number)
          end
        }.to perform_these_mongo_queries(
          {collection: :user_profiles, selector: {user_id: {"$in"=> users.map(&:id)}}, :fields=>{ phone_number: 1 }},
        )
      end
    end

    describe 'belongs_to relationship' do
      it 'should only do one query' do
        items = Item.all
        owners = nil

        expect{
          MongoMapper::EagerIncluder.eager_include(items, :owner)
        }.to perform_these_mongo_queries(
          {collection: :users, selector: {_id: {"$in"=> items.map(&:owner_id).uniq}}},
        )

        expect{
          owners = items.map(&:owner)
        }.to_not perform_any_mongo_queries

        Hash[items.zip(owners)].should eq @item_to_user_map

        expect{
          MongoMapper::EagerIncluder.eager_include(items, :owner)
        }.to_not perform_any_mongo_queries
      end

      it 'should accept a block to modify the mongo query' do
        items = Item.all
        expect{
          MongoMapper::EagerIncluder.eager_include(items, :owner) do |query|
            query.fields(:name)
          end
        }.to perform_these_mongo_queries(
          {collection: :users, selector: {_id: {"$in"=> items.map(&:owner_id).uniq}}, fields:{ name: 1 }},
        )
      end
    end
  end


  context 'eager loadings the same association more than once' do
    it 'should not eager load any association on any record more than once' do
      4.times do
        user = User.create!
        2.times.map do
          Post.create! user: user
        end
      end

      all_users = User.all
      expect(all_users.length).to eq 4
      first_two_users = all_users.first(2)

      expect{
        MongoMapper::EagerIncluder.eager_include(first_two_users, :posts)
      }.to perform_these_mongo_queries(
        {collection: :posts, selector: {user_id: {"$in"=> first_two_users.map(&:id)}}},
      )
      expect(first_two_users.length).to eq 2

      expect{ first_two_users.each(&:posts) }.to_not perform_any_mongo_queries

      expect{
        MongoMapper::EagerIncluder.eager_include(all_users, :posts)
      }.to perform_these_mongo_queries(
        {collection: :posts, selector: {user_id: {"$in"=> (all_users - first_two_users).map(&:id)}}},
      )

      expect(all_users.length).to eq 4

      expect{ all_users.each(&:posts) }.to_not perform_any_mongo_queries

      expect{
        MongoMapper::EagerIncluder.eager_include(all_users, :posts)
      }.to_not perform_any_mongo_queries

      expect(all_users.length).to eq 4
    end
  end

  context "sanity checking eager includer" do
    before do
      @user1 = User.create!
      @user2 = User.create!

      @users = [@user1, @user2]
    end

    it "should be able to load the right number of objects" do
      2.times do
        @user1.posts.create!
      end
      3.times do
        @user2.posts.create!
      end

      @user1.reload
      @user2.reload

      MongoMapper::EagerIncluder.eager_include([@user1, @user2], :posts)
      @user1.posts.length.should == 2
      @user2.posts.length.should == 3
    end
  end
end
