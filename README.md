# fluent-plugin-filter-split

[Fluentd](https://fluentd.org/) filter plugin to split specified field.

Compared to existing plugins:

* https://github.com/wshihadeh/fluent-plugin-record-splitter
  * This is filter plugin. It splits the specified field into multiple records. The target field must be lines.
* https://github.com/unquietwiki/fluent-plugin-split_record
  * This is filter plugin. It splits the specified field into key/value pairs. The target field must contain "key=value" pairs.
* https://github.com/SNakano/fluent-plugin-split-array
  * This is filter plugin. It splits the specified field into multiple records. The target field must be always array.
* https://github.com/toyama0919/fluent-plugin-split
  * This is output plugin. It splits the specified field into multiple records. The target field must contains specific separator.
* https://github.com/activeshadow/fluent-plugin-split-event
  * This is filter plugin. It splits the specified field into multiple records. The target field must contains specific separator.
* https://github.com/bitpatty/fluent-plugin-filter-split-message
  * 404. The only gem exists. https://rubygems.org/gems/fluent-plugin-filter-split-message
  * This is filter plugin. It splits the specified field into multiple records. The target field must contains specific separator.

Thus, about above plugins, there are limitation of type of field or missing feature to control keep/remove other fields.

## Installation

### RubyGems

```
$ gem install fluent-plugin-filter-split
```

### Bundler

Add following line to your Gemfile:

```ruby
gem "fluent-plugin-filter-split"
```

And then execute:

```
$ bundle
```

## Configuration

|parameter|type|description|default|
|---|---|---|---|
|split_key|string (required)|Specify a target key to split||
|keep_other_key|bool (optional)|Specify a flag whether other key must be kept or not|`false`|
|keep_keys|array (optional)|Specify keys to be kept in filtered record|`[]`|
|remove_keys|array (optional)|Specify keys to be removed in filtered record|`[]`|

## Copyright

* Copyright(c) 2023- Kentaro Hayashi
* License
  * Apache License, Version 2.0
