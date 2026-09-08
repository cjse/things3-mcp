# frozen_string_literal: true

# Records scripts and returns canned output instead of running osascript.
class FakeExecutor
  attr_reader :scripts

  def initialize(*outputs)
    @outputs = outputs
    @scripts = []
  end

  def execute(script)
    @scripts << script
    output = @outputs.shift
    raise Things3Mcp::AppleScript::Executor::AppleScriptError, output.message if output.is_a?(Exception)

    output.to_s
  end
end

def rec(*fields)
  fields.join(Things3Mcp::RecordParser::FIELD_SEP)
end

def recs(*records)
  records.join(Things3Mcp::RecordParser::RECORD_SEP)
end
