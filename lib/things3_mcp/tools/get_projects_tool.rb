# frozen_string_literal: true

require_relative 'base_tool'

module Things3Mcp
  module Tools
    class GetProjectsTool < BaseTool
      tool_name 'get_projects'
      title 'Get projects'
      description 'List projects in Things 3. Filter by area, status, tag, or name search.'
      input_schema(
        properties: {
          area: { type: 'string', description: 'Area name' },
          status: { type: 'string', enum: %w[open completed canceled] },
          tag: { type: 'string' },
          search: { type: 'string', description: 'Only projects whose name contains this text' },
          limit: { type: 'integer', minimum: 1 }
        }
      )
      output_schema(list_schema(:projects, PROJECT_SCHEMA))
      annotations(read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: false)

      def self.call(area: nil, status: nil, tag: nil, search: nil, limit: nil, server_context: nil)
        guarded do
          projects = client.list_projects(area: area, status: status, tag: tag, search: search, limit: limit)
          list_response(:projects, projects, bullet_list(projects.map { |p| summarize_project(p) }, 'No projects found'))
        end
      end
    end
  end
end
