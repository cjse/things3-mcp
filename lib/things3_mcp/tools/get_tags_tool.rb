# frozen_string_literal: true

require_relative 'base_tool'

module Things3Mcp
  module Tools
    class GetTagsTool < BaseTool
      tool_name 'get_tags'
      title 'Get tags'
      description 'List all tags in Things 3 with their parent tag.'
      input_schema(properties: {})
      output_schema(list_schema(:tags, TAG_SCHEMA))
      annotations(read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: false)

      def self.call(server_context: nil)
        guarded do
          tags = client.list_tags
          lines = tags.map { |t| t[:parent] ? "#{t[:name]} (parent: #{t[:parent]})" : t[:name] }
          list_response(:tags, tags, bullet_list(lines, 'No tags found'))
        end
      end
    end
  end
end
