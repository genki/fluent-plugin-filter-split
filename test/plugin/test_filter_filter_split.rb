require "helper"
require "fluent/plugin/filter_filter_split.rb"

class FilterSplitFilterTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  test "failure" do
    flunk
  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Filter.new(Fluent::Plugin::FilterSplitFilter).configure(conf)
  end
end
