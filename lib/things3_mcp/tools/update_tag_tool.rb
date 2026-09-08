# frozen_string_literal: true

require_relative 'base_tool'

module Things3Mcp
  module Tools
    class UpdateTagTool < BaseTool
      tool_name 'update_tag'
      title 'Update tag'
      description 'Rename a tag in Things 3 or change its parent. Use parent "none" to make it a top-level tag.'
      input_schema(
        properties: {
          tag_id: { type: 'string', description: 'Tag id or exact name' },
          name: { type: 'string', description: 'New name' },
          parent: { type: 'string', description: 'Parent tag name or id, or "none"' }
        },
        required: ['tag_id']
      )
      output_schema(TAG_SCHEMA)
      annotations(read_only_hint: false, destructive_hint: false, idempotent_hint: true, open_world_hint: false)

      def self.call(tag_id:, name: nil, parent: nil, server_context: nil)
        guarded do
          tag = client.update_tag(tag_id, name: name, parent: parent)
          record_response(tag, "Updated tag: #{tag[:name]}")
        end
      end
    end
  end
end
