require 'spec_helper'

describe MongoMapper::EagerIncluder do
  before do
    MongoMapper::EagerIncluder.clear_cache!

    @user = User.new
    @post = Post.new(:user => @user)
    @post_2 = Post.new(:user => @user)
    @item = Item.new(:owner => @user)
    @user_profile = UserProfile.new(:user => @user)

    @user.save!
    @post.save!
    @post_2.save!
    @item.save!
    @user_profile.save!
  end

  it "should be able to eager include a has_many association" do
    MongoMapper::EagerIncluder.eager_include(@user, :posts)
    @user.posts.should == [@post, @post_2]
  end

  it "should be able to eager include a belongs_to association" do
    MongoMapper::EagerIncluder.eager_include([@post, @post_2], :user)
    @post.user.should == @user
    @post_2.user.should == @user
  end

  it "should be able to eager include a has_many with a different foreign key" do
    MongoMapper::EagerIncluder.eager_include(@user, :items)
    @user.items.should == [@item]
  end

  it "should be able to eager include a has_one" do
    MongoMapper::EagerIncluder.eager_include(@user, :user_profile)
    @user.user_profile.should == [@user_profile]
  end
end