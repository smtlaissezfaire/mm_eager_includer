require 'rspec/expectations'
require 'pp'

RSpec::Matchers.define :perform_these_mongo_queries do
  match do |block|
    @block = @actual
    @actual = MongoQueryLog.capture(&block)
    @actual == @expected
  end

  failure_message_for_should do |*args|
    "expected #{@block} to perform the following mongo queries:\n#{@expected.pretty_inspect}\nbut queried:\n#{@actual.pretty_inspect}"
  end

  failure_message_for_should_not do |*args|
    "expected #{@block} to not perform the following mongo queries:\n#{@expected.pretty_inspect}\nbut queried:\n#{@actual.pretty_inspect}"
  end
end

RSpec::Matchers.define :perform_any_mongo_queries do
  match do |block|
    @block = @actual
    @actual = MongoQueryLog.capture(&block)
    @actual.present?
  end

  failure_message_for_should do |*args|
    "expected #{@block} to perform any mongo queries but it performed none"
  end

  failure_message_for_should_not do |*args|
    "expected #{@block} to not perform any mongo queries but it performed these: \n#{@actual.pretty_inspect}"
  end
end
