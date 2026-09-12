# frozen_string_literal: true

require_relative 'base_tool'

module Things3Mcp
  module Tools
    class UpdateAreaTool < BaseTool
      tool_name 'update_area'
      title 'Update area'
      description 'Rename an area in Things 3 or replace its tags.'
      input_schema(
        properties: {
          area_id: { type: 'string', description: 'Area id or exact name' },
          name: { type: 'string', description: 'New name' },
          tags: { type: 'array', items: { type: 'string' }, description: 'Replaces all tags' }
        },
        required: ['area_id']
      )
      output_schema(AREA_SCHEMA)
      annotations(read_only_hint: false, destructive_hint: false, idempotent_hint: true, open_world_hint: false)

      def self.call(area_id:, name: nil, tags: nil, server_context: nil)
        guarded do
          area = client.update_area(area_id, name: name, tags: tags)
          record_response(area, "Updated area: #{area[:name]} (id: #{area[:id]})")
        end
      end
    end
  end
end
