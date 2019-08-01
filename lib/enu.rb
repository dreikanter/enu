require "forwardable"
require "enu/version"

class Enu
  class << self
    extend Forwardable

    attr_writer :options

    def_delegators(
      :options,
      :each,
      :each_pair,
      :each_with_index,
      :key?,
      :keys,
      :values
    )

    def options
      @options ||= {}.freeze
    end

    def option(enum_key, value = nil)
      key = enum_key.to_sym
      raise KeyError, "'#{key}' option already exists" if key?(key)
      raise ArgumentError, "'#{key}' key is reserved" if respond_to?(key)
      raise TypeError, "non-integer value" if value && !value.is_a?(Integer)
      raise ArgumentError, "repeating value" if values.include?(value)

      explicit_value = value || (options.none? ? 0 : values.max + 1)
      self.options = options.merge(key => explicit_value).freeze

      singleton_class.class_eval do
        define_method(key) { key }
        define_method("#{key}_value") { explicit_value }
      end

      nil
    end

    def inherited(descendant)
      inherited_frozen_options = options&.clone || {}.freeze
      descendant.class_eval { self.options = inherited_frozen_options }
    end

    def default
      raise "empty enum, sad enum" unless options&.any?
      keys.first
    end
  end

  private_class_method :new, :option, :options=
end
