# frozen_string_literal: true

# Main module file that requires all components
require_relative 'things3_mcp/applescript/builder'
require_relative 'things3_mcp/applescript/executor'
require_relative 'things3_mcp/applescript/generator'
require_relative 'things3_mcp/date_parser'
require_relative 'things3_mcp/client'
require_relative 'things3_mcp/tools/add_task_tool'
require_relative 'things3_mcp/tools/get_tasks_tool'
require_relative 'things3_mcp/tools/update_task_tool'
require_relative 'things3_mcp/tools/complete_task_tool'
require_relative 'things3_mcp/tools/delete_task_tool'
require_relative 'things3_mcp/tools/move_task_tool'

module Things3Mcp
  VERSION = '1.0.0'
end
