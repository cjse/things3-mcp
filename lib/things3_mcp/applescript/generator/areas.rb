# frozen_string_literal: true

require_relative 'common'
require_relative 'tasks'

module Things3Mcp
  module AppleScript
    module Generator
      module Areas
        extend Common
        module_function

        def list_script
          Common.tell(Common.collect_records('area', 'areas'))
        end

        def add_script(name:, tags: nil)
          Common.tell(
            "set a to make new area with properties {name:#{Common.q(name)}}",
            Tasks.tags_statements('a', tags),
            Common.return_record('area', 'a')
          )
        end

        def update_script(ref, name: nil, tags: nil)
          Common.tell(
            "set a to my findArea(#{Common.q(ref)})",
            (name ? "set name of a to #{Common.q(name)}" : nil),
            Tasks.tags_statements('a', tags),
            Common.return_record('area', 'a')
          )
        end

        def delete_script(ref)
          Common.tell(
            "set a to my findArea(#{Common.q(ref)})",
            'set rec to my areaRecord(a)',
            'delete a',
            'return rec'
          )
        end
      end
    end
  end
end
