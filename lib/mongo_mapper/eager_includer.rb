require 'mongo_mapper'

class MongoMapper::EagerIncluder
  class << self
    def enabled?
      (@enabled == true || @enabled == false) ? @enabled : true
    end

    def enabled=(bool)
      @enabled = bool
    end

    def eager_include(record_or_records, *association_names, &block)
      association_names.each do |association_name|
        new(record_or_records, association_name).eager_include(&block)
      end
    end

    def write_to_cache(object_id, association_name, value)
      cache[association_name] ||= {}
      cache[association_name][object_id] = value
    end

    def read_from_cache(object_id, association_name)
      cache[association_name][object_id]
    end

    def clear_cache!
      @cache = {}
    end

  private

    def cache
      @cache ||= {}
    end
  end

  def initialize(record_or_records, association_name)
    association_name = association_name.to_sym

    @records = Array(record_or_records)

    if @records.length == 0
      return
    end

    @association_name = association_name.to_sym
    @association = @records.first.associations[association_name]
    if !@association
      raise "Could not find association `#{association_name}` on instance of #{@records.first.class}"
    end

    @proxy_class = @association.proxy_class
  end

  def enabled?
    self.class.enabled?
  end

  def eager_include(&block)
    return if !enabled?

    if @records.length == 0
      return
    end

    if @proxy_class == MongoMapper::Plugins::Associations::ManyDocumentsProxy
      eager_include_has_many(&block)
    elsif @proxy_class == MongoMapper::Plugins::Associations::BelongsToProxy
      eager_include_belongs_to(&block)
    elsif @proxy_class == MongoMapper::Plugins::Associations::OneProxy
      eager_include_has_one(&block)
    elsif @proxy_class == MongoMapper::Plugins::Associations::InArrayProxy
      eager_include_has_many_in(&block)
    else
      raise NotImplementedError, "#{@proxy_class} not supported yet!"
    end
  end

private

  def setup_association(record, association_name, value)
    association_name = association_name.to_sym

    self.class.write_to_cache(record.object_id, association_name, value)

    code = <<-CODE
      def #{association_name}
        MongoMapper::EagerIncluder.read_from_cache(object_id, :#{association_name})
      end
    CODE

    record.instance_eval(code, __FILE__, __LINE__)
  end

  def foreign_keys
    @association.options[:in]
  end

  def foreign_key
    @association_name.to_s.foreign_key
  end

  def primary_key
    @association.options[:foreign_key] || @records.first.class.name.foreign_key
  end

  def eager_include_has_many(&block)
    ids = @records.map { |el| el.id }.uniq
    proxy_records = @association.klass.where({
      primary_key => {
        '$in' => ids
      }
    }).all

    @records.each do |record|
      matching_proxy_records = proxy_records.select do |proxy_record|
        record_or_records = proxy_record.send(primary_key)
        if record_or_records.is_a?(Array)
          record_or_records.include?(record.id)
        else
          record_or_records == record.id
        end
      end

      setup_association(record, @association_name, matching_proxy_records)
    end
  end

  def eager_include_has_one(&block)
    ids = @records.map { |el| el.id }.uniq
    proxy_records = @association.klass.where({
      primary_key => ids
    })

    if block
      proxy_records = block.call(proxy_records)
    end

    proxy_records = proxy_records.all

    @records.each do |record|
      matching_proxy_record = proxy_records.detect do |proxy_record|
        proxy_record.send(primary_key) == record.id
      end

      setup_association(record, @association_name, matching_proxy_record)
    end
  end

  def eager_include_belongs_to(&block)
    ids = @records.map { |el| el.send(foreign_key) }.uniq

    proxy_records = @association.klass.where({
      :_id => {
        '$in' => ids
      }
    })

    if block
      proxy_records = block.call(proxy_records)
    end

    proxy_records = proxy_records.all

    @records.each do |record|
      matching_proxy_record = proxy_records.detect do |proxy_record|
        proxy_record.id == record.send(foreign_key)
      end

      setup_association(record, @association_name, matching_proxy_record)
    end
  end

  def eager_include_has_many_in(&block)
    ids = @records.map { |el| el.send(foreign_keys) }.flatten.uniq
    proxy_records = @association.klass.where({
      '_id' => {
        '$in' => ids
      }
    }).all

    @records.each do |record|
      proxy_record_ids = record.send(foreign_keys)

      matching_proxy_records = proxy_record_ids.map do |proxy_record_id|
        proxy_records.detect { |proxy_record| proxy_record.id == proxy_record_id }
      end

      setup_association(record, @association_name, matching_proxy_records)
    end
  end
end
