# frozen_string_literal: true

class AddAttesaStatusIdsToSlaProjectSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :sla_project_settings, :attesa_cliente_status_ids, :json
    add_column :sla_project_settings, :attesa_interna_status_ids, :json
  end
end
