require "enu/version"

class Enu
  def self.option(key, value = nil)
    value ||= next_value

    raise KeyError, "'#{key}' option already exists" if include?(key)
    raise TypeError, "enum values must be integer" unless value.is_a?(Integer)
    raise KeyError, "'#{key}' is a reserved key" if respond_to?(key)

    str_key = key.to_s
    @options[str_key] = value

    singleton_class.class_eval do
      define_method(key) { str_key }
      define_method("#{str_key}_value") { value }
    end
  end

  def self.include?(key)
    options.key?(key.to_s)
  end

  def self.options
    @options ||= {}
  end

  def self.keys
    options.keys
  end

  def self.values
    options.values
  end

  def self.default
    raise if options.empty?
    options.keys.first.to_s
  end

  def self.each
    options.each { |key, value| yield key, value }
  end

  def self.each_pair(&block)
    each(&block)
  end

  def self.each_with_index(&block)
    each(&block)
  end

  def self.next_value
    return 0 if values.empty?
    values.max + 1
  end

  private_class_method :next_value
end
