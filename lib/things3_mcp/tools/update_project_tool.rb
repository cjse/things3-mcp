# frozen_string_literal: true

require_relative 'base_tool'

module Things3Mcp
  module Tools
    class UpdateProjectTool < BaseTool
      tool_name 'update_project'
      title 'Update project'
      description 'Change fields of a project in Things 3. Only the given fields change. Use area "none" to remove it from its area.'
      input_schema(
        properties: {
          project_id: { type: 'string', description: 'Project id or exact name' },
          name: { type: 'string' },
          notes: { type: 'string', description: 'Replaces existing notes' },
          area: { type: 'string', description: 'Area name or id, or "none"' },
          tags: { type: 'array', items: { type: 'string' }, description: 'Replaces all tags' },
          due_date: { type: 'string', description: "Deadline. #{DATE_DESC}" },
          start_date: { type: 'string', description: "When to start. #{DATE_DESC}" },
          status: { type: 'string', enum: %w[open completed canceled] }
        },
        required: ['project_id']
      )
      output_schema(PROJECT_SCHEMA)
      annotations(read_only_hint: false, destructive_hint: false, idempotent_hint: true, open_world_hint: false)

      def self.call(project_id:, name: nil, notes: nil, area: nil, tags: nil, due_date: nil, start_date: nil, status: nil, server_context: nil)
        guarded do
          project = client.update_project(project_id, name: name, notes: notes, area: area, tags: tags,
                                          due_date: due_date, start_date: start_date, status: status)
          record_response(project, "Updated: #{summarize_project(project)}")
        end
      end
    end
  end
end
