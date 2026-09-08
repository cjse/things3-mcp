# frozen_string_literal: true

require_relative 'base_tool'

module Things3Mcp
  module Tools
    class GetProjectTool < BaseTool
      tool_name 'get_project'
      title 'Get project'
      description 'Show one project in Things 3 with its open tasks. Looks up by id first, then by exact name.'
      input_schema(
        properties: {
          project_id: { type: 'string', description: 'Project id or exact name' },
          include_tasks: { type: 'boolean', description: 'Include the open tasks (default true)' }
        },
        required: ['project_id']
      )
      output_schema(
        properties: PROJECT_SCHEMA[:properties].merge(tasks: { type: 'array', items: TASK_SCHEMA })
      )
      annotations(read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: false)

      def self.call(project_id:, include_tasks: true, server_context: nil)
        guarded do
          project = client.get_project(project_id, include_tasks: include_tasks)
          text = summarize_project(project)
          if project[:tasks]
            text += "\n" + bullet_list(project[:tasks].map { |t| summarize_task(t) }, 'No open tasks')
          end
          record_response(project, text)
        end
      end
    end
  end
end
