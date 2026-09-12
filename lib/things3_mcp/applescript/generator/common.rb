# frozen_string_literal: true

module Things3Mcp
  module AppleScript
    module Generator
      # Shared AppleScript handlers and Ruby helpers used by every generator.
      #
      # Records are returned as text: fields are separated by ASCII 31 (unit
      # separator) and records by ASCII 30 (record separator). RecordParser turns
      # that text back into hashes.
      module Common
        APP_NAME = 'Things3'

        TASK_FIELDS = %i[id name status notes project area tags due_date start_date creation_date completion_date].freeze
        PROJECT_FIELDS = %i[id name status notes area tags due_date start_date creation_date task_count].freeze
        AREA_FIELDS = %i[id name tags].freeze
        TAG_FIELDS = %i[id name parent].freeze

        HANDLERS = <<~APPLESCRIPT
          on fmtDate(d)
            if d is missing value then return ""
            set y to year of d as integer
            set m to month of d as integer
            set dd to day of d as integer
            return (y as text) & "-" & text -2 thru -1 of ("0" & m) & "-" & text -2 thru -1 of ("0" & dd)
          end fmtDate

          on mkDate(y, m, d)
            set dt to current date
            set day of dt to 1
            set year of dt to y
            set month of dt to m
            set day of dt to d
            set time of dt to 0
            return dt
          end mkDate

          on replaceText(t, s, r)
            set {tid, AppleScript's text item delimiters} to {AppleScript's text item delimiters, s}
            set parts to text items of t
            set AppleScript's text item delimiters to r
            set t to parts as text
            set AppleScript's text item delimiters to tid
            return t
          end replaceText

          on esc(t)
            if t is missing value then return ""
            set t to my replaceText(t, return, "\\\\n")
            set t to my replaceText(t, linefeed, "\\\\n")
            return t
          end esc

          on joinRecords(recs)
            set {tid, AppleScript's text item delimiters} to {AppleScript's text item delimiters, character id 30}
            set out to recs as text
            set AppleScript's text item delimiters to tid
            return out
          end joinRecords

          on findTask(theRef)
            tell application "Things3"
              try
                set t to to do id theRef
                get name of t
                return t
              end try
              try
                return first to do whose name is theRef and status is open
              end try
              try
                return first to do whose name is theRef
              end try
            end tell
            error "Task not found: " & theRef
          end findTask

          on findProject(theRef)
            tell application "Things3"
              try
                set p to project id theRef
                get name of p
                return p
              end try
              try
                return first project whose name is theRef
              end try
            end tell
            error "Project not found: " & theRef
          end findProject

          on findArea(theRef)
            tell application "Things3"
              try
                set a to area id theRef
                get name of a
                return a
              end try
              try
                return first area whose name is theRef
              end try
            end tell
            error "Area not found: " & theRef
          end findArea

          on findTag(theRef)
            tell application "Things3"
              try
                set g to tag id theRef
                get name of g
                return g
              end try
              try
                return first tag whose name is theRef
              end try
            end tell
            error "Tag not found: " & theRef
          end findTag

          on projectName(t)
            tell application "Things3"
              try
                return name of project of t
              end try
            end tell
            return ""
          end projectName

          on areaName(t)
            tell application "Things3"
              try
                return name of area of t
              end try
            end tell
            return ""
          end areaName

          on taskRecord(t)
            set f to character id 31
            tell application "Things3"
              set pr to properties of t
              set pj to ""
              if project of pr is not missing value then set pj to name of (project of pr)
              set ar to ""
              if area of pr is not missing value then set ar to name of (area of pr)
              return (id of pr) & f & (name of pr) & f & ((status of pr) as text) & f & my esc(notes of pr) & f & pj & f & ar & f & (tag names of pr) & f & my fmtDate(due date of pr) & f & my fmtDate(activation date of pr) & f & my fmtDate(creation date of pr) & f & my fmtDate(completion date of pr)
            end tell
          end taskRecord

          on projectRecord(p)
            set f to character id 31
            tell application "Things3"
              set pr to properties of p
              set ar to ""
              if area of pr is not missing value then set ar to name of (area of pr)
              return (id of pr) & f & (name of pr) & f & ((status of pr) as text) & f & my esc(notes of pr) & f & ar & f & (tag names of pr) & f & my fmtDate(due date of pr) & f & my fmtDate(activation date of pr) & f & my fmtDate(creation date of pr) & f & (count of to dos of p)
            end tell
          end projectRecord

          on areaRecord(a)
            set f to character id 31
            tell application "Things3"
              return (id of a) & f & (name of a) & f & (tag names of a)
            end tell
          end areaRecord

          on tagRecord(g)
            set f to character id 31
            tell application "Things3"
              set pt to ""
              try
                set pt to name of parent tag of g
              end try
              return (id of g) & f & (name of g) & f & pt
            end tell
          end tagRecord
        APPLESCRIPT

        module_function

        # Prepends the shared handlers to a script body.
        def script(body)
          "#{HANDLERS}\n#{body}"
        end

        # Wraps statements in a tell block and prepends the handlers.
        def tell(*statements)
          body = statements.flatten.compact.map { |s| indent(s) }.join("\n")
          script("tell application \"#{APP_NAME}\"\n#{body}\nend tell")
        end

        def indent(text, level = 1)
          text.lines.map { |line| line.strip.empty? ? '' : ('  ' * level) + line.rstrip }.join("\n")
        end

        # Quotes a Ruby string as an AppleScript string literal.
        def q(str)
          text = str.to_s.dup.force_encoding('UTF-8')
          text = text.gsub('\\', '\\\\\\\\').gsub('"', '\\"')
          text = text.gsub("\r\n", '\\n').gsub("\r", '\\n').gsub("\n", '\\n').gsub("\t", '\\t')
          '"' + text + '"'
        end

        # A date hash from DateParser ({year:, month:, day:}) to a mkDate call.
        def date_expr(date)
          "my mkDate(#{date[:year]}, #{date[:month]}, #{date[:day]})"
        end

        def tag_names_expr(tags)
          Array(tags).map { |t| t.to_s.strip }.reject(&:empty?).join(', ')
        end

        # Statements that return one record for the object held in `var`.
        def return_record(kind, var)
          "return my #{kind}Record(#{var})"
        end

        # Emits a `repeat` over `source`, applies optional filter conditions and a limit,
        # and returns the records joined with the record separator.
        def collect_records(kind, source, conditions: [], limit: nil, var: 'x')
          checks = conditions.compact
          body = []
          body << 'set out to {}'
          body << 'set n to 0'
          body << "repeat with #{var} in (#{source})"
          if checks.any?
            body << "  if #{checks.map { |c| "(#{c})" }.join(' and ')} then"
            body << "    set end of out to my #{kind}Record(#{var})"
            body << '    set n to n + 1'
            body << '  end if'
          else
            body << "  set end of out to my #{kind}Record(#{var})"
            body << '  set n to n + 1'
          end
          body << "  if n ≥ #{limit.to_i} then exit repeat" if limit && limit.to_i.positive?
          body << 'end repeat'
          body << 'return my joinRecords(out)'
          body.join("\n")
        end
      end
    end
  end
end
