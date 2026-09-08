# frozen_string_literal: true

require_relative 'common'

module Things3Mcp
  module AppleScript
    module Generator
      module Tags
        extend Common
        module_function

        def list_script
          Common.tell(Common.collect_records('tag', 'tags'))
        end

        def add_script(name:, parent: nil)
          Common.tell(
            "set g to make new tag with properties {name:#{Common.q(name)}}",
            parent_statement('g', parent),
            Common.return_record('tag', 'g')
          )
        end

        def update_script(ref, name: nil, parent: nil)
          Common.tell(
            "set g to my findTag(#{Common.q(ref)})",
            (name ? "set name of g to #{Common.q(name)}" : nil),
            parent_statement('g', parent),
            Common.return_record('tag', 'g')
          )
        end

        def delete_script(ref)
          Common.tell(
            "set g to my findTag(#{Common.q(ref)})",
            'set rec to my tagRecord(g)',
            'delete g',
            'return rec'
          )
        end

        def parent_statement(var, parent)
          return nil if parent.nil?
          return "set parent tag of #{var} to missing value" if parent == 'none'

          "set parent tag of #{var} to my findTag(#{Common.q(parent)})"
        end
      end
    end
  end
end
