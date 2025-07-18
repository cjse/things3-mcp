# frozen_string_literal: true

module Things3Mcp
  module AppleScript
    class Builder
      def initialize(app_name)
        @app_name = app_name
        @do = []
        @try = []
        @on_error = []
        @indent_level = 1
      end

      def do(statement)
        @do << statement if statement
      end

      def try(statement)
        @try << statement if statement
      end

      def on_error(statement)
        @on_error << statement if statement
      end

      def to_script
        @results = ["tell application \"#{@app_name}\""]

        add_do_statements! unless @do.empty?
        add_try_block! unless @try.empty?

        @results << "end tell"

        @results.join("\n")
      end

      private

      def add_do_statements!
        @do.each do |statement|
          @results << indent(statement)
        end
      end

      def add_try_block!
        @results << indent("try")
        @try.each do |statement|
          @results << indent(statement, 1)
        end

        add_on_error_block! unless @on_error.empty?

        @results << indent("end try")
      end

      def add_on_error_block!
        @results << indent("on error errorMsg")
        @on_error.each do |statement|
          @results << indent(statement, 1)
        end
      end

      def indent(statement = "", offset = 0)
        ("  " * (@indent_level + offset)) + statement
      end
    end
  end
end
