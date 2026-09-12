# frozen_string_literal: true

require_relative 'base_tool'

module Things3Mcp
  module Tools
    class AddProjectTool < BaseTool
      tool_name 'add_project'
      title 'Add project'
      description 'Create a project in Things 3.'
      input_schema(
        properties: {
          name: { type: 'string' },
          notes: { type: 'string' },
          area: { type: 'string', description: 'Area name or id' },
          tags: { type: 'array', items: { type: 'string' } },
          due_date: { type: 'string', description: "Deadline. #{DATE_DESC}" },
          start_date: { type: 'string', description: "When to start. #{DATE_DESC}" }
        },
        required: ['name']
      )
      output_schema(PROJECT_SCHEMA)
      annotations(read_only_hint: false, destructive_hint: false, idempotent_hint: false, open_world_hint: false)

      def self.call(name:, notes: nil, area: nil, tags: nil, due_date: nil, start_date: nil, server_context: nil)
        guarded do
          project = client.add_project(name: name, notes: notes, area: area, tags: tags, due_date: due_date, start_date: start_date)
          record_response(project, "Created: #{summarize_project(project)}")
        end
      end
    end
  end
end
