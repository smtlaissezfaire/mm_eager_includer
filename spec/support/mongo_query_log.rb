module MongoQueryLog
  def self.log
    @log ||= []
  end

  def self.log_query(query)
    log << query
  end

  def self.clear!
    log.clear
  end

  def self.capture(&block)
    log_length = log.length
    yield
    log[log_length..-1]
  end
end

Mongo::Cursor.class_eval do
  alias_method "send_initial_query_without_logging", "send_initial_query"
  def send_initial_query(*args)
    send_initial_query_without_logging(*args).tap do |*res|
      query = {
        collection: @collection.name.to_sym,
        selector: @selector,
      }
      query[:fields] = @fields unless @fields.nil?
      MongoQueryLog.log_query(query)
    end
  end
end
