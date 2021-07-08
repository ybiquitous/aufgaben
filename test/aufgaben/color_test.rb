require "test_helper"
require_relative "../../lib/aufgaben/color"

class ColorTest < Minitest::Test
  include TestHelper

  def test_green_with_enabled
    Aufgaben::Color.stub :enabled?, true do
      assert_equal "\e[32mhello\e[0m", Aufgaben::Color.new("hello").green
    end
  end

  def test_green_with_disabled
    Aufgaben::Color.stub :enabled?, false do
      assert_equal "hello", Aufgaben::Color.new("hello").green
    end
  end
end
