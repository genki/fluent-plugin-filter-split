require "helper"
require "fluent/plugin/filter_filter_split.rb"

class FilterSplitFilterTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  sub_test_case 'configure' do
    test '@type only failure' do
      assert_raise Fluent::ConfigError.new("'split_key' parameter is required") do
        create_driver %(
          @type filter_split
        )
      end
    end

    test 'check required split_key' do
      assert_nothing_raised do
        create_driver %(
          @type filter_split
          split_key target_field
        )
      end
    end

    test 'both of keep_keys and remove_keys should not be specified' do
      assert_raise Fluent::ConfigError.new('Cannot set both keep_keys and remove_keys.') do
        create_driver %(
          @type filter_split
          split_key target_field
          keep_keys keep_field
          remove_keys remove_field
        )
      end
    end

    test 'keep_keys and keep_other_key are conflicted' do
      assert_raise Fluent::ConfigError.new('Cannot set keep_keys when keep_other_key is true.') do
        create_driver %(
          @type filter_split
          split_key target_field
          keep_keys keep_field
          keep_other_key true
        )
      end
    end

    test 'remove_keys and keep_other_key are conflicted' do
      assert_raise Fluent::ConfigError.new('Cannot set remove_keys when keep_other_key is false.') do
        create_driver %(
          @type filter_split
          split_key target_field
          remove_keys remove_field
        )
      end
    end
  end

  TARGET_FIELD_VALUES = [{ 'k1' => 'v1' }, { 'k2' => 'v2' }]

  sub_test_case 'split_key' do
    test 'nonexistent split_key does not affect' do
      d = create_driver %(
        @type filter_split
        tag foo
        split_key nonexistent
      )
      d.run(default_tag: 'test') do
        d.feed(event_time,
               'other' => 'foo',
               'target_field' => TARGET_FIELD_VALUES)
      end
      assert_equal [
        [event_time, {'other' => 'foo', 'target_field' => TARGET_FIELD_VALUES}]
      ], d.filtered
    end

    test 'split target_field' do
      d = create_driver %(
        @type filter_split
        split_key target_field
      )
      d.run(default_tag: 'test') do
        d.feed(event_time,
               'other' => 'foo',
               # can't pass TARGET_FIELD_VALUES here. it break test
               'target_field' => [{'k1'=>'v1'},{'k2'=>'v2'}])
      end
      assert_equal [
        [event_time, { 'k1' => 'v1' }],
        [event_time, { 'k2' => 'v2' }]
      ], d.filtered
    end

    test 'split target_field is not array' do
      d = create_driver %(
        @type filter_split
        split_key target_field
      )
      d.run(default_tag: 'test') do
        d.feed(event_time,
               'other' => 'foo',
               'target_field' => nil)
      end
      assert_equal [
        [event_time, { 'other' => 'foo', 'target_field' => nil }],
      ], d.filtered
      matched = d.logs.grep(/\[warn\]: failed to split with <target_field> key because the target field is not Array:/)
      assert_equal(1, matched.size)
    end

    test 'split target_field with array of scalar' do
      d = create_driver %(
        @type filter_split
        split_key target_field
      )
      d.run(default_tag: 'test') do
        d.feed(event_time,
               'other' => 'foo',
               'target_field' => [ 'v1', 'v2', 'v3'])
      end
      assert_equal [
        [event_time, { 'target_field' => 'v1' }],
        [event_time, { 'target_field' => 'v2' }],
        [event_time, { 'target_field' => 'v3' }]
      ], d.filtered
    end
  end

  sub_test_case 'keep_keys' do
    test 'keep other field' do
      d = create_driver %(
        @type filter_split
        split_key target_field
        keep_keys other
      )
      d.run(default_tag: 'test') do
        d.feed(event_time,
               'other' => 'foo',
               'target_field' => TARGET_FIELD_VALUES)
      end
      assert_equal [
        [event_time, { 'other' => 'foo', 'k1' => 'v1' }],
        [event_time, { 'other' => 'foo', 'k2' => 'v2' }]
      ], d.filtered
    end

    test 'keep nonexistent field' do
      d = create_driver %(
        @type filter_split
        split_key target_field
        keep_keys nonexistent
      )
      d.run(default_tag: 'test') do
        d.feed(event_time,
               'other' => 'foo',
               'target_field' => TARGET_FIELD_VALUES)
      end
      assert_equal [
        [event_time, { 'k1' => 'v1' }],
        [event_time, { 'k2' => 'v2' }]
      ], d.filtered
    end
  end

  sub_test_case 'remove_keys' do
    test 'remove other field' do
      d = create_driver %(
        @type filter_split
        split_key target_field
        remove_keys other
        keep_other_key true
      )
      d.run(default_tag: 'test') do
        d.feed(event_time,
               'general' => 'foo',
               'other' => 'bar',
               # can't pass TARGET_FIELD_VALUES here. it break test
               'target_field' => [{'k1'=>'v1'},{'k2'=>'v2'}])
      end
      assert_equal [
        [event_time, { 'general' => 'foo', 'k1' => 'v1' }],
        [event_time, { 'general' => 'foo', 'k2' => 'v2' }]
      ], d.filtered
    end

    test 'remove nonexistent field' do
      d = create_driver %(
        @type filter_split
        split_key target_field
        remove_keys nonexistent
        keep_other_key true
      )
      d.run(default_tag: 'test') do
        d.feed(event_time,
               'other' => 'foo',
               'target_field' => TARGET_FIELD_VALUES)
      end
      assert_equal [
        [event_time, { 'other' => 'foo', 'k1' => 'v1' }],
        [event_time, { 'other' => 'foo', 'k2' => 'v2' }]
      ], d.filtered
    end
  end

  sub_test_case 'keep_other_key' do
    test 'keep other field' do
      d = create_driver %(
        @type filter_split
        split_key target_field
        keep_other_key true
      )
      d.run(default_tag: 'test') do
        d.feed(event_time,
               'other' => 'foo',
               'target_field' => TARGET_FIELD_VALUES)
      end
      assert_equal [
        [event_time, {'other' => 'foo', 'k1' => 'v1' }],
        [event_time, {'other' => 'foo', 'k2' => 'v2' }]
      ], d.filtered
    end
  end

  sub_test_case 'keep_other_key_with_prefix' do
    test 'keep other field' do
      d = create_driver %(
        @type filter_split
        split_key target_field
        prefix prefix_
        keep_other_key true
      )
      d.run(default_tag: 'test') do
        d.feed(event_time,
               'other' => 'foo',
               'target_field' => TARGET_FIELD_VALUES)
      end
      assert_equal [
        [event_time, {'other' => 'foo', 'prefix_k1' => 'v1' }],
        [event_time, {'other' => 'foo', 'prefix_k2' => 'v2' }]
      ], d.filtered
    end
  end

  private

  def create_driver(conf = '')
    Fluent::Test::Driver::Filter.new(Fluent::Plugin::FilterSplitFilter).configure(conf)
  end

  def event_time
    Time.parse('2023-10-23 00:11:22 UTC').to_i
  end
end
