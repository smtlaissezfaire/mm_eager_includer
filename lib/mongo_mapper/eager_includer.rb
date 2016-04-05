require 'mongo_mapper'

class MongoMapper::EagerIncluder
  def self.eager_include(record_or_records, *association_names, &query_alteration_block)
    association_names.each do |association_name|
      new(record_or_records, association_name, &query_alteration_block).eager_include
    end
  end

  def initialize(record_or_records, association_name, &query_alteration_block)
    if record_or_records.is_a? Plucky::Query
      raise "You must call `to_a` on `Plucky::Query` objects before passing to eager_include"
    end
    @records = Array(record_or_records)

    return if @records.length == 0
    @association_name = association_name.to_sym
    @query_alteration_block = query_alteration_block
    @association = @records.first.associations[@association_name]
    if !@association
      raise "Could not find association `#{association_name}` on instance of #{@records.first.class}"
    end
  end

  def eager_include
    @records.reject! do |record|
      record.instance_variable_defined?(instance_variable_name)
    end

    return if @records.length == 0

    @association_type = case @association.proxy_class.to_s
    when 'MongoMapper::Plugins::Associations::ManyDocumentsProxy'
      :has_many
    when 'MongoMapper::Plugins::Associations::BelongsToProxy'
      :belongs_to
    when 'MongoMapper::Plugins::Associations::OneProxy'
      :has_one
    when 'MongoMapper::Plugins::Associations::InArrayProxy'
      :has_many_in
    else
      raise NotImplementedError, "#{@association.proxy_class} not supported yet!"
    end

    send("eager_include_#{@association_type}")
  end

private

  attr_reader :association_name

  def instance_variable_name
    "@eager_loaded_#{association_name}"
  end

  def setup_association(record, value)
    code = <<-RUBY
      def #{association_name}
        #{instance_variable_name}
      end
    RUBY
    record.instance_eval(code, __FILE__, __LINE__)
    record.instance_variable_set(instance_variable_name, value)
  end

  def association_class
    @association_class ||= @association.klass
  end

  def foreign_keys
    @foreign_keys ||= @association.options[:in]
  end

  def foreign_key
    @foreign_key ||= @association_name.to_s.foreign_key
  end

  def primary_key
    @primary_key ||= @association.options[:foreign_key] || @records.first.class.name.foreign_key
  end

  def record_ids
    case @association_type
    when :has_many, :has_one
      @records.map(&:id)
    when :belongs_to
      @records.map do |record|
        record.send(foreign_key)
      end
    when :has_many_in
      @records.map do |record|
        record.send(foreign_keys)
      end.flatten
    end.uniq
  end

  def load_association_records!
    @association_records_query = case @association_type
    when :has_many, :has_one
      association_class.where({ primary_key => { '$in' => record_ids } })
    when :belongs_to, :has_many_in
      association_class.where({ _id: { '$in' => record_ids } })
    end

    if @query_alteration_block
      @association_records_query = @query_alteration_block.call(@association_records_query)
    end
    @association_records = @association_records_query.all
  end

  def eager_include_has_many(&block)
    load_association_records!

    @records.each do |record|
      matching_association_records = @association_records.select do |association_record|
        record_or_records = association_record.send(primary_key)
        if record_or_records.is_a?(Array)
          record_or_records.include?(record.id)
        else
          record_or_records == record.id
        end
      end

      setup_association(record, matching_association_records)
    end
  end

  def eager_include_has_one(&block)
    load_association_records!

    @records.each do |record|
      matching_association_record = @association_records.detect do |association_record|
        association_record.send(primary_key) == record.id
      end

      setup_association(record, matching_association_record)
    end
  end

  def eager_include_belongs_to(&block)
    load_association_records!

    @records.each do |record|
      matching_association_record = @association_records.detect do |association_record|
        association_record.id == record.send(foreign_key)
      end

      setup_association(record, matching_association_record)
    end
  end

  def eager_include_has_many_in(&block)
    load_association_records!

    @records.each do |record|
      association_record_ids = record.send(foreign_keys)

      matching_association_records = association_record_ids.map do |association_record_id|
        @association_records.detect { |association_record| association_record.id == association_record_id }
      end

      setup_association(record, matching_association_records)
    end
  end
end
