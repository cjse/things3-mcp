# frozen_string_literal: true

require_relative 'base_tool'

module Things3Mcp
  module Tools
    class DeleteAreaTool < BaseTool
      tool_name 'delete_area'
      title 'Delete area'
      description 'Delete an area in Things 3. Its projects and tasks stay, without an area.'
      input_schema(
        properties: { area_id: { type: 'string', description: 'Area id or exact name' } },
        required: ['area_id']
      )
      output_schema(AREA_SCHEMA)
      annotations(read_only_hint: false, destructive_hint: true, idempotent_hint: false, open_world_hint: false)

      def self.call(area_id:, server_context: nil)
        guarded do
          area = client.delete_area(area_id)
          record_response(area, "Deleted area: #{area[:name]}")
        end
      end
    end
  end
end
