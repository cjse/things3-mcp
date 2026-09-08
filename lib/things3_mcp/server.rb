# frozen_string_literal: true

require 'mcp'

module Things3Mcp
  module Server
    INSTRUCTIONS = <<~TEXT
      Tools for the Things 3 task manager on the user's Mac. Every tool returns structured data.
      Tasks, projects, areas, and tags can be addressed by id or by exact name; prefer ids from earlier results.
      Dates accept natural language ("tomorrow", "next friday") or YYYY-MM-DD; "none" clears a date.
      Checklist items and headings are not available through this server.
    TEXT

    module_function

    def build
      MCP::Server.new(
        name: 'things3-mcp',
        title: 'Things 3',
        version: Things3Mcp::VERSION,
        instructions: INSTRUCTIONS,
        tools: Tools::ALL,
        configuration: MCP::Configuration.new(
          exception_reporter: ->(exception, context) { report(exception, context) }
        )
      )
    end

    def report(exception, context)
      $stderr.puts "[things3-mcp] #{exception.class}: #{exception.message} #{context.inspect}"
      $stderr.puts exception.backtrace.first(5).join("\n") if exception.backtrace
    end
  end
end
