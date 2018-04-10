module TestCenter
  module Helper
    require 'fastlane_core/ui/ui.rb'

    class ReportNameHelper
      attr_reader :report_count

      def initialize(output_types = nil, output_files = nil, custom_report_file_name = nil)
        @output_types = output_types || 'junit'
        @output_files = output_files || custom_report_file_name
        @report_count = 0

        if @output_types && @output_files.nil?
          @output_files = @output_types.split(',').map { |type| "report.#{type}" }.join(',')
        end
        unless @output_types.include?('junit')
          FastlaneCore::UI.important('Scan output types missing \'junit\', adding it')
          @output_types = @output_types.split(',').push('junit').join(',')
          if @output_types.split(',').size == @output_files.split(',').size + 1
            @output_files = @output_files.split(',').push('report.xml').join(',')
            FastlaneCore::UI.message('As output files has one less than the new number of output types, assumming the filename for the junit was missing and added it')
          end
        end

        types = @output_types.split(',').each(&:chomp)
        files = @output_files.split(',').each(&:chomp)
        unless files.size == types.size
          raise ArgumentError, "Error: count of :output_types, #{types}, does not match the output filename(s) #{files}"
        end
      end

      def numbered_filename(filename)
        if @report_count > 0
          basename = File.basename(filename, '.*')
          extension = File.extname(filename)
          filename = "#{basename}-#{@report_count + 1}#{extension}"
        end
        filename
      end

      def scan_options
        files = @output_files.split(',').each(&:chomp)
        files.map! do |filename|
          filename.chomp
          numbered_filename(filename)
        end
        {
          output_types: @output_types,
          output_files: files.join(',')
        }
      end

      def junit_last_reportname
        junit_index = @output_types.split(',').find_index('junit')
        numbered_filename(@output_files.to_s.split(',')[junit_index])
      end

      def junit_reportname
        junit_index = @output_types.split(',').find_index('junit')
        @output_files.to_s.split(',')[junit_index]
      end

      def junit_filextension
        File.extname(junit_reportname)
      end

      # --- HTML ---
      # TODO: what to do when there are no html output types?
      def includes_html?
        @output_types.split(',').find_index('html') != nil
      end

      def html_last_reportname
        html_index = @output_types.split(',').find_index('html')
        numbered_filename(@output_files.to_s.split(',')[html_index])
      end

      def html_reportname
        html_index = @output_types.split(',').find_index('html')
        @output_files.to_s.split(',')[html_index]
      end

      def html_filextension
        File.extname(html_reportname)
      end

      def increment
        @report_count += 1
      end
    end
  end
end
