# frozen_string_literal: true

require_relative 'base_tool'

module Things3Mcp
  module Tools
    class GetAreasTool < BaseTool
      tool_name 'get_areas'
      title 'Get areas'
      description 'List all areas in Things 3.'
      input_schema(properties: {})
      output_schema(list_schema(:areas, AREA_SCHEMA))
      annotations(read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: false)

      def self.call(server_context: nil)
        guarded do
          areas = client.list_areas
          list_response(:areas, areas, bullet_list(areas.map { |a| "#{a[:name]} (id: #{a[:id]})" }, 'No areas found'))
        end
      end
    end
  end
end
