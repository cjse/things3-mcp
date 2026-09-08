# frozen_string_literal: true

require_relative 'base_tool'

module Things3Mcp
  module Tools
    class AddAreaTool < BaseTool
      tool_name 'add_area'
      title 'Add area'
      description 'Create an area in Things 3.'
      input_schema(
        properties: {
          name: { type: 'string' },
          tags: { type: 'array', items: { type: 'string' } }
        },
        required: ['name']
      )
      output_schema(AREA_SCHEMA)
      annotations(read_only_hint: false, destructive_hint: false, idempotent_hint: false, open_world_hint: false)

      def self.call(name:, tags: nil, server_context: nil)
        guarded do
          area = client.add_area(name: name, tags: tags)
          record_response(area, "Created area: #{area[:name]} (id: #{area[:id]})")
        end
      end
    end
  end
end
