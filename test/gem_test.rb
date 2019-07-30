require "test_helper"

class GemTest < Minitest::Test
  def test_version
    refute_nil(::Enu::VERSION)
  end
end
