# frozen_string_literal: true

require_relative 'base_tool'

module Things3Mcp
  module Tools
    class AddTagTool < BaseTool
      tool_name 'add_tag'
      title 'Add tag'
      description 'Create a tag in Things 3, optionally nested under a parent tag.'
      input_schema(
        properties: {
          name: { type: 'string' },
          parent: { type: 'string', description: 'Parent tag name or id' }
        },
        required: ['name']
      )
      output_schema(TAG_SCHEMA)
      annotations(read_only_hint: false, destructive_hint: false, idempotent_hint: false, open_world_hint: false)

      def self.call(name:, parent: nil, server_context: nil)
        guarded do
          tag = client.add_tag(name: name, parent: parent)
          record_response(tag, "Created tag: #{tag[:name]}")
        end
      end
    end
  end
end
