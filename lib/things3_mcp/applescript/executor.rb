# frozen_string_literal: true

require 'tempfile'
require 'timeout'

module Things3Mcp
  module AppleScript
    # Runs AppleScript through osascript. Calls are serialized with a process-wide
    # lock because Things handles one Apple event at a time, and a timeout guards
    # against a stuck dialog in Things.
    class Executor
      class AppleScriptError < StandardError; end

      LOCK = Mutex.new
      DEFAULT_TIMEOUT = 60

      def initialize(debug: false, timeout: DEFAULT_TIMEOUT)
        @debug = debug
        @timeout = timeout
      end

      def execute(script)
        log_debug("Executing AppleScript:\n#{script}")

        result = LOCK.synchronize { run_osascript(script) }

        log_debug("AppleScript result: #{result}")
        result
      end

      def things3_installed?
        script = <<~APPLESCRIPT
          try
            tell application "Things3" to return "installed"
          on error
            return "not_installed"
          end try
        APPLESCRIPT
        execute(script).strip == 'installed'
      rescue AppleScriptError
        false
      end

      def things3_running?
        script = <<~APPLESCRIPT
          tell application "System Events"
            return (name of processes) contains "Things3"
          end tell
        APPLESCRIPT
        execute(script).strip == 'true'
      rescue AppleScriptError
        false
      end

      private

      def run_osascript(script)
        Tempfile.create(['things3_script', '.applescript']) do |file|
          file.write(script)
          file.flush

          reader, writer = IO.pipe
          pid = Process.spawn('osascript', file.path, out: writer, err: writer)
          writer.close

          output = +''
          status = nil
          begin
            Timeout.timeout(@timeout) do
              output = reader.read
              _, status = Process.wait2(pid)
            end
          rescue Timeout::Error
            Process.kill('KILL', pid) rescue nil
            Process.wait(pid) rescue nil
            raise AppleScriptError, "AppleScript timed out after #{@timeout}s"
          ensure
            reader.close unless reader.closed?
          end

          output = output.force_encoding('UTF-8')
          raise AppleScriptError, clean_error(output) unless status.success?

          output
        end
      end

      # osascript prefixes errors with "<file>:<line>:<col>: execution error: "
      def clean_error(output)
        message = output.strip.sub(/\A.*?(execution|script) error: /m, '')
        message = message.sub(/ \(-?\d+\)\z/, '')
        message.empty? ? 'AppleScript execution failed' : message
      end

      def log_debug(message)
        $stderr.puts "[AppleScriptExecutor DEBUG] #{message}" if @debug
      end
    end
  end
end
