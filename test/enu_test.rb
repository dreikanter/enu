require "test_helper"

class EnuTest < Minitest::Test
  IMPLICIT_DEFINITION = %i[
    mango
    banana
  ].freeze

  EXPLICIT_DEFINITION = {
    mango: 100,
    banana: 500
  }.freeze

  def create_enum
    Class.new(Enu)
  end

  def create_explicit_enum
    Class.new(Enu) do
      EXPLICIT_DEFINITION.each { |key, value| option(key, value) }
    end
  end

  def create_implicit_enum
    Class.new(Enu) do
      IMPLICIT_DEFINITION.each { |key| option(key) }
    end
  end

  def test_explicit_definition
    enum = create_explicit_enum
    EXPLICIT_DEFINITION.keys.each do |key|
      assert_respond_to(enum, key)
    end
  end

  def test_explicit_keys_set
    expected = create_explicit_enum.keys.to_set
    assert_equal(expected, EXPLICIT_DEFINITION.keys.to_set)
  end

  def test_explicit_keys
    enum = create_explicit_enum
    EXPLICIT_DEFINITION.keys.each do |key|
      assert_equal(enum.send(key), key)
    end
  end

  def test_explicit_values
    enum = create_explicit_enum
    EXPLICIT_DEFINITION.each_pair do |key, value|
      assert_equal(enum.send("#{key}_value"), value)
    end
  end

  def test_explicit_default
    expected = EXPLICIT_DEFINITION.keys.first
    assert_equal(expected, create_explicit_enum.default)
  end

  TUPLEIZE = ->(key, value) { [key, value] }

  def test_explicit_each
    expected = EXPLICIT_DEFINITION.map(&TUPLEIZE).to_h
    result = {}
    create_explicit_enum.each do |key, value|
      result[key] = value
    end
    assert_equal(expected, result)
  end

  class Implicit < Enu
    IMPLICIT_DEFINITION.each do |key|
      option key
    end
  end

  def test_implicit_definition
    IMPLICIT_DEFINITION.each do |key|
      assert_respond_to(Implicit, key)
    end
  end

  def test_implicit_keys_set
    expected = create_implicit_enum.keys.to_set
    assert_equal(expected, IMPLICIT_DEFINITION.to_set)
  end

  def test_implicit_keys
    enum = create_implicit_enum
    IMPLICIT_DEFINITION.each do |key|
      assert_equal(enum.send(key), key)
    end
  end

  def test_implicit_values
    enum = create_implicit_enum
    IMPLICIT_DEFINITION.each_with_index do |key, index|
      assert_equal(enum.send("#{key}_value"), index)
    end
  end

  def test_implicit_default
    expected = IMPLICIT_DEFINITION.first
    assert_equal(expected, create_implicit_enum.default)
  end

  def test_implicit_each
    expected = IMPLICIT_DEFINITION.map.with_index(&TUPLEIZE).to_h
    result = {}
    create_implicit_enum.each do |key, value|
      result[key] = value
    end
    assert_equal(expected, result)
  end

  def test_option_already_defined_error
    assert_raises(KeyError) do
      Class.new(Enu) do |alterego|
        alterego.class_eval { 2.times { option :banana } }
      end
    end
  end

  def test_value_type_error
    assert_raises(TypeError) do
      Class.new(Enu) do |alterego|
        alterego.class_eval { option(:banana, :not_an_integer) }
      end
    end
  end

  def test_reserved_key_error
    Enu.public_methods.each do |reserved_key|
      assert_raises(ArgumentError) do
        Class.new(Enu) do |alterego|
          alterego.class_eval { option(reserved_key) }
        end
      end
    end
  end

  def test_default_nothing
    assert_raises(StandardError) { Enu.default }
  end

  def test_each_pair
    result = create_explicit_enum.each_pair.to_a
    expected = EXPLICIT_DEFINITION.each_pair.to_a
    assert_equal(expected, result)
  end

  def test_explicit_each_with_index
    expected = EXPLICIT_DEFINITION.each_with_index.to_a
    result = create_explicit_enum.each_with_index.to_a
    assert_equal(expected, result)
  end

  def test_impicit_each_with_index
    with_index = IMPLICIT_DEFINITION.each_with_index
    expected = with_index.map { |key, index| [[key, index], index] }
    result = create_implicit_enum.each_with_index.to_a
    assert_equal(expected, result)
  end

  def test_hash_options
    assert(create_explicit_enum.options.is_a?(Hash))
    assert(create_implicit_enum.options.is_a?(Hash))
  end

  def test_options_are_frozen
    assert(create_explicit_enum.options.frozen?)
  end
end
