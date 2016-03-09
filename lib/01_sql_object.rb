require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    if @columns
      @columns
    else
      column_names = DBConnection.execute2(<<-SQL)
        SELECT
          *
        FROM
          "#{self.table_name}"
      SQL

      @columns = column_names.first.map { |name| name.to_sym }
    end
  end

  def self.finalize!
    columns.each do |column_name|
      define_method(column_name) { attributes[column_name] }

      define_method("#{column_name}=") do |value|
        attributes[column_name] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    everything = DBConnection.execute(<<-SQL)
      SELECT
        "#{self.table_name}".*
      FROM
        "#{self.table_name}"
    SQL

    parse_all(everything)
  end

  def self.parse_all(results)
    results.map { |el| self.new(el) }
  end

  def self.find(id)
    results = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{self.table_name}.id = ?
    SQL

    return nil if results.empty?

    self.new(results.first)
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      symbolized = attr_name.to_sym

      unless self.class.columns.include?(symbolized)
        raise "unknown attribute '#{attr_name}'"
      end

      self.send("#{symbolized}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map { |el| send(el.to_sym) }
  end

  def insert
    col_names = self.class.columns.join(", ")
    question_marks = ["?"] * self.class.columns.length
    question_marks = question_marks.join(", ")

    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    col_names = self.class.columns
    set = col_names.map { |col_name| "#{col_name} = ?" }.join(",")

    DBConnection.execute(<<-SQL, *attribute_values, id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set}
      WHERE
        #{self.class.table_name}.id = ?
    SQL
  end

  def save
    if id.nil?
      insert
    else
      update
    end
  end
end
