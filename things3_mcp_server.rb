#!/usr/bin/env ruby
# frozen_string_literal: true
# encoding: utf-8

require 'bundler/setup'
require 'dotenv/load'
require 'fast_mcp'

# Add lib to the load path
$LOAD_PATH.unshift(File.expand_path('lib', __dir__))

# Require the main module
require 'things3_mcp'

# Main server setup
if __FILE__ == $0
  # Create and configure the server
  server = FastMcp::Server.new(
    name: 'things3-mcp',
    version: Things3Mcp::VERSION
  )

  # Register all tools
  server.register_tool(Things3Mcp::Tools::AddTaskTool)
  server.register_tool(Things3Mcp::Tools::GetTasksTool)
  server.register_tool(Things3Mcp::Tools::UpdateTaskTool)
  server.register_tool(Things3Mcp::Tools::CompleteTaskTool)
  server.register_tool(Things3Mcp::Tools::DeleteTaskTool)
  server.register_tool(Things3Mcp::Tools::MoveTaskTool)

  # Start the server
  server.start
end
