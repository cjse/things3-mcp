# frozen_string_literal: true

require_relative 'base_tool'

module Things3Mcp
  module Tools
    class DeleteProjectTool < BaseTool
      tool_name 'delete_project'
      title 'Delete project'
      description 'Move a project and its tasks in Things 3 to the Trash.'
      input_schema(
        properties: { project_id: { type: 'string', description: 'Project id or exact name' } },
        required: ['project_id']
      )
      output_schema(PROJECT_SCHEMA)
      annotations(read_only_hint: false, destructive_hint: true, idempotent_hint: false, open_world_hint: false)

      def self.call(project_id:, server_context: nil)
        guarded do
          project = client.delete_project(project_id)
          record_response(project, "Moved to Trash: #{summarize_project(project)}")
        end
      end
    end
  end
end
