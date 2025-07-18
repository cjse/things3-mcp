# frozen_string_literal: true

require 'tempfile'

module Things3Mcp
  module AppleScript
    class Executor
      class AppleScriptError < StandardError; end
      
      def initialize(debug: false)
        @debug = debug
      end
      
      def execute(script)
        log_debug("Executing AppleScript:\n#{script}") if @debug
        
        result = nil
        
        Tempfile.create(['things3_script', '.scpt']) do |file|
          file.write(script)
          file.flush
          
          result = `osascript #{file.path} 2>&1`.force_encoding('UTF-8')
          
          if $?.exitstatus != 0
            raise AppleScriptError, "AppleScript execution failed: #{result}"
          end
        end
        
        log_debug("AppleScript result: #{result}") if @debug
        result
      end
      
      def execute_with_response(script)
        begin
          result = execute(script)
          {
            success: true,
            result: result.strip,
            error: nil
          }
        rescue AppleScriptError => e
          {
            success: false,
            result: nil,
            error: e.message
          }
        end
      end
      
      def validate_things3_availability
        test_script = <<~APPLESCRIPT
          tell application "System Events"
            return (name of processes) contains "Things3"
          end tell
        APPLESCRIPT
        
        response = execute_with_response(test_script)
        
        if response[:success] && response[:result] == "true"
          true
        else
          false
        end
      end
      
      def things3_installed?
        test_script = <<~APPLESCRIPT
          try
            tell application "Things3"
              return "installed"
            end tell
          on error
            return "not_installed"
          end try
        APPLESCRIPT
        
        response = execute_with_response(test_script)
        response[:success] && response[:result] == "installed"
      end
      
      private
      
      def log_debug(message)
        puts "[AppleScriptExecutor DEBUG] #{message}" if @debug
      end
    end
  end
end