class AttrAccessorObject
  def self.my_attr_accessor(*names)
    self.my_attr_reader(*names)
    self.my_attr_writer(*names)
  end

  def self.my_attr_reader(*names)
    names.each do |name|
      define_method(name) { instance_variable_get("@#{name}") }
    end
  end

  def self.my_attr_writer(*names)
    names.each do |name|
      define_method("#{name}=") do |value|
        instance_variable_set("@#{name}", value)
      end
    end
  end

end
