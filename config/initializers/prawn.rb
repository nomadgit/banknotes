module Prawn
  module Core
    module Text
      module Formatted #:nodoc:
        class LineWrap #:nodoc:
          def wrap_line(options)
            initialize_line(options)

            while fragment = @arranger.next_string
              @fragment_output = ""

              fragment.to_str.lstrip! if first_fragment_on_this_line?(fragment)
              next if empty_line?(fragment)

              unless apply_font_settings_and_add_fragment_to_line(fragment)
                break
              end
            end
            @arranger.finalize_line
            @accumulated_width = @arranger.line_width
            @space_count = @arranger.space_count
            @arranger.line
          end
        end
      end
    end
  end
end
