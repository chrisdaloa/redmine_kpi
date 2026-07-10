# Load the Redmine helper

require "simplecov"
require "simplecov-cobertura"

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::CoberturaFormatter,
  SimpleCov::Formatter::HTMLFormatter
])

SimpleCov.start do
  root File.expand_path(File.dirname(__FILE__) + "/..")
  add_filter "/test/"
  add_filter "lib/tasks"

  add_group "Controllers", "app/controllers"
  add_group "Models", "app/models"
  add_group "Helpers", "app/helpers"

  add_group "Plugin Features", "lib/redmine_sla"
end

require File.expand_path(File.dirname(__FILE__) + "/../../../test/test_helper")

ActiveSupport::TestCase.parallelize(workers: 1)

if defined?(Rails::TestUnitReporter) && Rails::TestUnitReporter.respond_to?(:executable) && !Rails::TestUnitReporter.method_defined?(:executable)
  Rails::TestUnitReporter.class_eval do
    def format_rerun_snippet(result)
      location, line =
        if result.respond_to?(:source_location)
          result.source_location
        else
          result.method(result.name).source_location
        end

      "#{self.class.executable} #{relative_path_for(location)}:#{line}"
    end
  end
end

# Load model_factory.rb from the same folder as this file
require_relative "./model_factory"
