# frozen_string_literal: true

Dir[File.join(__dir__, 'tools', '*_tool.rb')].sort.each { |f| require f }

module Things3Mcp
  module Tools
    ALL = [
      GetTasksTool, GetTaskTool, AddTaskTool, UpdateTaskTool, CompleteTaskTool, DeleteTaskTool, MoveTaskTool,
      GetProjectsTool, GetProjectTool, AddProjectTool, UpdateProjectTool, DeleteProjectTool,
      GetAreasTool, AddAreaTool, UpdateAreaTool, DeleteAreaTool,
      GetTagsTool, AddTagTool, UpdateTagTool, DeleteTagTool
    ].freeze
  end
end
