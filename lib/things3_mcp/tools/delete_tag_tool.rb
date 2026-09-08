# frozen_string_literal: true

require_relative 'base_tool'

module Things3Mcp
  module Tools
    class DeleteTagTool < BaseTool
      tool_name 'delete_tag'
      title 'Delete tag'
      description 'Delete a tag in Things 3 and remove it from every task and project.'
      input_schema(
        properties: { tag_id: { type: 'string', description: 'Tag id or exact name' } },
        required: ['tag_id']
      )
      output_schema(TAG_SCHEMA)
      annotations(read_only_hint: false, destructive_hint: true, idempotent_hint: false, open_world_hint: false)

      def self.call(tag_id:, server_context: nil)
        guarded do
          tag = client.delete_tag(tag_id)
          record_response(tag, "Deleted tag: #{tag[:name]}")
        end
      end
    end
  end
end
