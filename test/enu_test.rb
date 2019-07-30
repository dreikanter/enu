require "test_helper"

class EnuTest < Minitest::Test
  EXPLICIT_DEFINITION = {
    one: 1,
    two: 2
  }.freeze

  IMPLICIT_DEFINITION = %i[
    one
    two
  ].freeze

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
    assert_equal(expected, EXPLICIT_DEFINITION.keys.map(&:to_s).to_set)
  end

  def test_explicit_keys
    enum = create_explicit_enum
    EXPLICIT_DEFINITION.keys.each do |key|
      assert_equal(enum.send(key), key.to_s)
    end
  end

  def test_explicit_values
    enum = create_explicit_enum
    EXPLICIT_DEFINITION.each do |key, value|
      assert_equal(enum.send("#{key}_value"), value)
    end
  end

  def test_explicit_default
    expected = EXPLICIT_DEFINITION.keys.first.to_s
    assert_equal(expected, create_explicit_enum.default)
  end

  TUPLEIZE = ->(key, value) { [key.to_s, value] }

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
    assert_equal(expected, IMPLICIT_DEFINITION.map(&:to_s).to_set)
  end

  def test_implicit_keys
    enum = create_implicit_enum
    IMPLICIT_DEFINITION.each do |key|
      assert_equal(enum.send(key), key.to_s)
    end
  end

  def test_implicit_values
    enum = create_implicit_enum
    IMPLICIT_DEFINITION.each_with_index do |key, index|
      assert_equal(enum.send("#{key}_value"), index)
    end
  end

  def test_implicit_default
    expected = IMPLICIT_DEFINITION.first.to_s
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
    new_enum = create_enum
    option_name = :banana
    new_enum.option(option_name)
    assert_raises(KeyError) { new_enum.option(option_name) }
  end

  def test_value_type_error
    new_enum = create_enum
    assert_raises(TypeError) { new_enum.option(:banana, :banana) }
  end

  def test_reserved_key_error
    new_enum = create_enum
    Enu.public_methods.each do |reserved_key|
      assert_raises(KeyError) { new_enum.option(reserved_key) }
    end
  end

  def test_default
    assert_raises(StandardError) { Enu.default }
  end

  def test_each_pair
    result = {}
    create_explicit_enum.each_pair do |key, value|
      result[key.to_sym] = value
    end
    assert_equal(EXPLICIT_DEFINITION, result)
  end

  def test_each_with_index
    result = {}
    create_explicit_enum.each_with_index do |key, value|
      result[key.to_sym] = value
    end
    assert_equal(EXPLICIT_DEFINITION, result)
  end
end
