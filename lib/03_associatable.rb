require_relative '02_searchable'
require 'active_support/inflector'

require 'byebug'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    self.class_name.constantize
  end

  def table_name
    self.model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    default_options = {
      foreign_key: "#{name.to_s.singularize.downcase}_id".to_sym,
      primary_key: :id,
      class_name: "#{name.to_s.singularize.camelcase}"
    }

    options = default_options.merge(options)

    self.foreign_key = options[:foreign_key]
    self.primary_key = options[:primary_key]
    self.class_name = options[:class_name]
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    default_options = {
      foreign_key: "#{self_class_name.singularize.downcase}_id".to_sym,
      primary_key: :id,
      class_name: "#{name.singularize.camelcase}",
      self_class_name: self_class_name
    }

    options = default_options.merge(options)

    self.foreign_key = options[:foreign_key]
    self.primary_key = options[:primary_key]
    self.class_name = options[:class_name]
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)

		assoc_options[name] = options

		define_method(name) do
			foreign_key = send(options.foreign_key)
			options.model_class.where(options.primary_key => foreign_key).first
		end
  end

  def has_many(name, options = {})
		options = HasManyOptions.new(name.to_s, self.to_s, options)

		define_method(name) do
			primary_key = send(options.primary_key)
			options.model_class.where(options.foreign_key => primary_key)
		end
  end

  def assoc_options
  	@assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
