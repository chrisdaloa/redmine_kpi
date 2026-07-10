# frozen_string_literal: true

require_relative "../test_helper"

class RedmineSla::LocalesTest < ActiveSupport::TestCase
  LOCALES_DIR = File.join(File.dirname(__FILE__), "..", "..", "config", "locales")

  def flatten_keys(hash, prefix = nil)
    hash.each_with_object([]) do |(key, value), keys|
      full_key = prefix ? "#{prefix}.#{key}" : key.to_s
      if value.is_a?(Hash)
        keys.concat(flatten_keys(value, full_key))
      else
        keys << full_key
      end
    end
  end

  def keys_for(locale_file)
    yaml = YAML.load_file(File.join(LOCALES_DIR, locale_file))
    flatten_keys(yaml.fetch(yaml.keys.first))
  end

  test "every non-English locale has the same keys as en.yml" do
    reference_keys = keys_for("en.yml").sort

    (Dir.children(LOCALES_DIR) - [ "en.yml" ]).each do |locale_file|
      assert_equal reference_keys, keys_for(locale_file).sort, "#{locale_file} keys differ from en.yml"
    end
  end
end
