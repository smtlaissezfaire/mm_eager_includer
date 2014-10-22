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

    @tree = Tree.new
    @bird = Bird.new
    @bird.save!
    @tree.save!
    @tree.bird_ids = [@bird.id]
    @tree.save!
    @tree.reload

    @order = Order.new
    @order.customer = @user
    @order.save!

    MongoMapper::EagerIncluder.enabled = true
    # make sure nothing is loaded
    @user.reload
    @post.reload
    @post_2.reload
    @item.reload
    @user_profile.reload
    @tree.reload
    @bird.reload
    @order.reload
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

  it "should only perform one query" do
    proxy = mock('query proxy', :all => [@user])
    User.should_receive(:where).once.and_return(proxy)
    User.should_not_receive(:find_by_id)

    MongoMapper::EagerIncluder.eager_include([@post, @post_2], :user)

    @post.user
    @post_2.user
  end

  it "should have enabled = true by default" do
    MongoMapper::EagerIncluder.send :remove_instance_variable, "@enabled"
    MongoMapper::EagerIncluder.enabled?.should be_true
  end

  it "should be able to be turned off and on" do
    MongoMapper::EagerIncluder.enabled = false
    MongoMapper::EagerIncluder.enabled?.should be_false

    MongoMapper::EagerIncluder.enabled = true
    MongoMapper::EagerIncluder.enabled?.should be_true
  end

  it "should perform two queries if off" do
    MongoMapper::EagerIncluder.enabled = false
    User.should_not_receive(:where)
    User.should_receive(:find_by_id).twice.and_return(@user)

    MongoMapper::EagerIncluder.eager_include([@post, @post_2], :user)

    @post.user
    @post_2.user
  end

  it "should be able to eager include a has_many with a different foreign key" do
    MongoMapper::EagerIncluder.eager_include(@user, :items)
    @user.items.should == [@item]
  end

  it "should be able to eager include a has_one" do
    MongoMapper::EagerIncluder.eager_include(@user, :user_profile)
    @user.user_profile.should == @user_profile
  end

  it "should be able to eager include a has_many with in" do
    MongoMapper::EagerIncluder.eager_include(@tree, :birds)
    @tree.birds.should == [@bird]
  end

  it "should be able to eager include a belongs_to with a different foreign_key" do
    MongoMapper::EagerIncluder.eager_include([@order], :customer)
    @order.customer.should == @user
  end
end