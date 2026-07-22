# frozen_string_literal: true

require_relative "../test_helper"

class RedmineSla::ProjectCustomFieldColumnTest < ActiveSupport::TestCase
  def setup
    Setting.plugin_redmine_sla = (Setting.plugin_redmine_sla || {}).merge("categoria_custom_field_id" => nil)
  end

  def enable_sla_and_grant_view!(project)
    project.enabled_module_names += [ "sla" ]
    Role.anonymous.add_permission!(:view_sla)
  end

  context "#value_object" do
    should "return the project's custom field value when the setting id is configured" do
      field = ProjectCustomField.create!(name: "Categoria", field_format: "string", is_for_all: true)
      issue = create(:issue)
      enable_sla_and_grant_view!(issue.project)
      issue.project.custom_field_values = { field.id.to_s => "VIP" }
      issue.project.save!
      Setting.plugin_redmine_sla = Setting.plugin_redmine_sla.merge("categoria_custom_field_id" => field.id.to_s)

      column = RedmineSla::ProjectCustomFieldColumn.new(:sla_categoria, :categoria_custom_field_id)
      assert_equal "VIP", column.value_object(issue.reload)
    end

    should "return nil when no custom field id is configured" do
      issue = create(:issue)
      enable_sla_and_grant_view!(issue.project)

      column = RedmineSla::ProjectCustomFieldColumn.new(:sla_categoria, :categoria_custom_field_id)
      assert_nil column.value_object(issue)
    end

    should "return nil when the configured field is not applicable to the project" do
      field = ProjectCustomField.create!(name: "Categoria", field_format: "string", is_for_all: false)
      issue = create(:issue)
      enable_sla_and_grant_view!(issue.project)
      Setting.plugin_redmine_sla = Setting.plugin_redmine_sla.merge("categoria_custom_field_id" => field.id.to_s)

      column = RedmineSla::ProjectCustomFieldColumn.new(:sla_categoria, :categoria_custom_field_id)
      assert_nil column.value_object(issue)
    end

    should "return nil when the sla module is disabled" do
      field = ProjectCustomField.create!(name: "Categoria", field_format: "string", is_for_all: true)
      issue = create(:issue)
      Role.anonymous.add_permission!(:view_sla)
      issue.project.custom_field_values = { field.id.to_s => "VIP" }
      issue.project.save!
      Setting.plugin_redmine_sla = Setting.plugin_redmine_sla.merge("categoria_custom_field_id" => field.id.to_s)

      column = RedmineSla::ProjectCustomFieldColumn.new(:sla_categoria, :categoria_custom_field_id)
      assert_nil column.value_object(issue.reload)
    end

    should "return nil when the current user lacks the view_sla permission" do
      field = ProjectCustomField.create!(name: "Categoria", field_format: "string", is_for_all: true)
      issue = create(:issue)
      issue.project.enabled_module_names += [ "sla" ]
      issue.project.custom_field_values = { field.id.to_s => "VIP" }
      issue.project.save!
      Setting.plugin_redmine_sla = Setting.plugin_redmine_sla.merge("categoria_custom_field_id" => field.id.to_s)

      column = RedmineSla::ProjectCustomFieldColumn.new(:sla_categoria, :categoria_custom_field_id)
      assert_nil column.value_object(issue.reload)
    end
  end
end
