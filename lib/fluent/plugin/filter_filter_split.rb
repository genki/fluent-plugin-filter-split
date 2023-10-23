#
# Copyright 2023- Kentaro Hayashi
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'fluent/plugin/filter'
require 'fluent/config/error'
require 'fluent/event'
require 'fluent/time'

module Fluent
  module Plugin
    class FilterSplitFilter < Fluent::Plugin::Filter
      Fluent::Plugin.register_filter("filter_split", self)

      helpers :record_accessor

      desc 'Specify a target key to split'
      config_param :split_key, :string
      desc 'Specify a flag whether other key must be kept or not'
      config_param :keep_other_key, :bool, default: false
      desc 'Specify keys to be kept in filtered record'
      config_param :keep_keys, :array, default: []
      desc 'Specify keys to be removed in filtered record'
      config_param :remove_keys, :array, default: []

      def configure(conf)
        super
        if !@keep_keys.empty? && !@remove_keys.empty?
          raise Fluent::ConfigError, 'Cannot set both keep_keys and remove_keys.'
        end
        if @keep_other_key && !@keep_keys.empty?
          raise Fluent::ConfigError, 'Cannot set keep_keys when keep_other_key is true.'
        end
        if !@keep_other_key && !@remove_keys.empty?
          raise Fluent::ConfigError, 'Cannot set remove_keys when keep_other_key is false.'
        end
      end

      def filter_stream(tag, es)
        new_es = Fluent::MultiEventStream.new
        es.each do |time, record|
          begin
            unless record.key?(@split_key)
              new_es.add(time, record)
              next
            end

            keyvalues = if @keep_other_key
                          other_keyvalues(record)
                        else
                          remained_keyvalues(record)
                        end

            unless record[@split_key].is_a?(Array)
              new_es.add(time, record)
              log.warn "failed to split with <#{@split_key}> key because the target field is not Array: <#{record[@split_key]}>."
              next
            end

            record[@split_key].each do |v|
              v.merge!(keyvalues) unless keyvalues.empty?
              new_es.add(time, v)
            end
          rescue => e
            router.emit_error_event(tag, time, record, e)            
            log.warn "failed to split with <#{@split_key} key." , error: e
          end
        end
        new_es
      end

      private

      def remained_keyvalues(record)
        record.select { |key, _value| @keep_keys.include?(key) }
      end

      def other_keyvalues(record)
        record.reject do |key, _value|
          key == @split_key || @remove_keys.include?(key)
        end
      end
    end
  end
end
