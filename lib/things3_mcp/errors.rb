module Things3Mcp
  class Error < StandardError; end
  class InvalidTaskError < Error; end
  class TaskNotFoundError < Error; end
  class AppleScriptError < Error; end
end