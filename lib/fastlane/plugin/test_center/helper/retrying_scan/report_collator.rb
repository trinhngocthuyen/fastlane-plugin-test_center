module TestCenter
  module Helper
    module RetryingScan
      class ReportCollator
        def initialize(params)
          @output_directory = params[:output_directory]
          @reportnamer = params[:reportnamer]
        end

        def sort_globbed_files(glob)
          file = Dir.glob(glob).map do |relative_filepath|
            File.absolute_path(relative_filepath)
          end
          file.sort! { |f1, f2| File.mtime(f1) <=> File.mtime(f2) }
        end

        def create_config(klass, options)
          config = FastlaneCore::Configuration.create(klass.available_options, options)
        end

        def collate_junit_reports
          report_files = sort_globbed_files("#{@output_directory}/#{@reportnamer.junit_fileglob}")
          if report_files.size > 1
            config = create_config(
              {
                reports: report_files,
                collated_report: File.absolute_path(File.join(@output_directory, @reportnamer.junit_reportname))
              }
            )
            Fastlane::Actions::CollateJunitReportsAction.run(config)
          end
        end
      end
    end
  end
end
