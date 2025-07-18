# frozen_string_literal: true

# Main module file that requires all components
require_relative 'things3_mcp/errors'
require_relative 'things3_mcp/applescript/executor'
require_relative 'things3_mcp/applescript/generator'
require_relative 'things3_mcp/date_parser'
require_relative 'things3_mcp/client'
require_relative 'things3_mcp/task_filter'
require_relative 'things3_mcp/bulk_operations'
require_relative 'things3_mcp/report_generator'
require_relative 'things3_mcp/tools/add_task_tool'
require_relative 'things3_mcp/tools/get_tasks_tool'
require_relative 'things3_mcp/tools/update_task_tool'
require_relative 'things3_mcp/tools/complete_task_tool'
require_relative 'things3_mcp/tools/delete_task_tool'
require_relative 'things3_mcp/tools/move_task_tool'
require_relative 'things3_mcp/tools/filter_tasks_tool'
require_relative 'things3_mcp/tools/bulk_create_tool'
require_relative 'things3_mcp/tools/weekly_review_tool'
require_relative 'things3_mcp/tools/productivity_stats_tool'

module Things3Mcp
  VERSION = '1.0.0'
end