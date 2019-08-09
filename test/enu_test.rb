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

  def new_enum(&block)
    Class.new(Enu, &block)
  end

  def explicit_enum
    new_enum do
      EXPLICIT_DEFINITION.each { |key, value| option(key, value) }
    end
  end

  def implicit_enum
    new_enum do
      IMPLICIT_DEFINITION.each { |key| option(key) }
    end
  end

  def test_explicit_definition
    enum = explicit_enum
    EXPLICIT_DEFINITION.keys.each do |key|
      assert_respond_to(enum, key)
    end
  end

  def test_explicit_keys_set
    expected = explicit_enum.keys.to_set
    assert_equal(expected, EXPLICIT_DEFINITION.keys.to_set)
  end

  def test_explicit_keys
    enum = explicit_enum
    EXPLICIT_DEFINITION.keys.each do |key|
      assert_equal(enum.send(key), key)
    end
  end

  def test_explicit_values
    enum = explicit_enum
    EXPLICIT_DEFINITION.each_pair do |key, value|
      assert_equal(enum.send("#{key}_value"), value)
    end
  end

  def test_explicit_default
    expected = EXPLICIT_DEFINITION.keys.first
    assert_equal(expected, explicit_enum.default)
  end

  def test_explicit_each
    expected = EXPLICIT_DEFINITION.to_a
    result = explicit_enum.each.to_a
    assert_equal(expected, result)
  end

  def test_implicit_definition
    enum_class = implicit_enum
    IMPLICIT_DEFINITION.each do |key|
      assert_respond_to(enum_class, key)
    end
  end

  def test_implicit_keys_set
    expected = implicit_enum.keys.to_set
    assert_equal(expected, IMPLICIT_DEFINITION.to_set)
  end

  def test_implicit_keys
    enum = implicit_enum
    IMPLICIT_DEFINITION.each do |key|
      assert_equal(enum.send(key), key)
    end
  end

  def test_implicit_values
    enum = implicit_enum
    IMPLICIT_DEFINITION.each_with_index do |key, index|
      assert_equal(enum.send("#{key}_value"), index)
    end
  end

  def test_implicit_default
    expected = IMPLICIT_DEFINITION.first
    assert_equal(expected, implicit_enum.default)
  end

  def test_implicit_each
    expected = IMPLICIT_DEFINITION.map.with_index.to_a
    result = implicit_enum.each.to_a
    assert_equal(expected, result)
  end

  def test_option_already_defined_error
    assert_raises(KeyError) do
      new_enum do |alterego|
        alterego.class_eval { 2.times { option :coconut } }
      end
    end
  end

  def test_repeating_value_error
    assert_raises(ArgumentError) do
      new_enum do |alterego|
        alterego.class_eval do
          option :mango, 1
          option :banana, 1
        end
      end
    end
  end

  def test_value_type_error
    assert_raises(TypeError) do
      new_enum do |alterego|
        alterego.class_eval { option(:coconut, :not_an_integer) }
      end
    end
  end

  def test_reserved_key_error
    Enu.public_methods.each do |reserved_key|
      assert_raises(ArgumentError) do
        new_enum do |alterego|
          alterego.class_eval { option(reserved_key) }
        end
      end
    end
  end

  def test_no_default_error
    assert_raises(StandardError) { Enu.default }
  end

  def test_each_pair
    expected = EXPLICIT_DEFINITION.each_pair.to_a
    result = explicit_enum.each_pair.to_a
    assert_equal(expected, result)
  end

  def test_explicit_each_with_index
    expected = EXPLICIT_DEFINITION.each_with_index.to_a
    result = explicit_enum.each_with_index.to_a
    assert_equal(expected, result)
  end

  def test_impicit_each_with_index
    with_index = IMPLICIT_DEFINITION.each_with_index
    expected = with_index.map { |key, index| [[key, index], index] }
    result = implicit_enum.each_with_index.to_a
    assert_equal(expected, result)
  end

  def test_hash_options
    assert(explicit_enum.options.is_a?(Hash))
    assert(implicit_enum.options.is_a?(Hash))
  end

  def test_options_are_frozen
    assert(new_enum.options.frozen?)
    assert(explicit_enum.options.frozen?)
  end

  EXPECTED_JSON = '{"mango":"mango","banana":"banana"}'.freeze

  def test_explicit_enum_to_json
    result = explicit_enum.to_json
    assert_equal(EXPECTED_JSON, result)
  end

  def test_implicit_enum_to_json
    result = implicit_enum.to_json
    assert_equal(EXPECTED_JSON, result)
  end
end
