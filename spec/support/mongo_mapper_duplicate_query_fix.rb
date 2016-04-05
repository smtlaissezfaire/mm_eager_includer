# This exists to fix a bug in mongo_mapper 0.12.0, in which
# models that aren't using the identity map are yielding duplicate
# queries.
#
# TODO: This code should probably be removed when
# mongo_mapper 0.12.0 is upgraded
raise "this hack only works on MongoMapper 0.12.0" if MongoMapper::Version != '0.12.0'
MongoMapper::Plugins::IdentityMap::ClassMethods.class_eval do
  alias_method :query_definied_by_identity_mapper, :query

  def query(opts={})
    if plugins.include?(MongoMapper::Plugins::IdentityMap)
      query_definied_by_identity_mapper(opts)
    else
      super
    end
  end
end
