# frozen_string_literal: true

require_relative 'things3_mcp/applescript/executor'
require_relative 'things3_mcp/applescript/generator'
require_relative 'things3_mcp/record_parser'
require_relative 'things3_mcp/date_parser'
require_relative 'things3_mcp/client'
require_relative 'things3_mcp/tools'
require_relative 'things3_mcp/server'

module Things3Mcp
  VERSION = '2.0.0'

  class << self
    # The process-wide client. Tools share it so AppleScript runs through one
    # serialized executor.
    def client
      @client ||= Client.new(
        AppleScript::Executor.new(debug: ENV['THINGS3_MCP_DEBUG'] == '1'),
        DateParser.new
      )
    end

    attr_writer :client
  end
end
