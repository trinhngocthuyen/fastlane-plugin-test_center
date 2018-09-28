module TestCenter
  module Helper
    module RetryingScan
      class ReportCollator

        CollateJunitReportsAction = Fastlane::Actions::CollateJunitReportsAction
        CollateHtmlReportsAction = Fastlane::Actions::CollateHtmlReportsAction
        
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

        def delete_globbed_intermediatefiles(glob)
          retried_reportfiles = Dir.glob(glob)
          FileUtils.rm_f(retried_reportfiles)
        end

        def create_config(klass, options)
          FastlaneCore::Configuration.create(klass.available_options, options)
        end

        def collate_junit_reports
          report_files = sort_globbed_files("#{@output_directory}/#{@reportnamer.junit_fileglob}")
          if report_files.size > 1
            config = create_config(
              CollateJunitReportsAction,
              {
                reports: report_files,
                collated_report: File.absolute_path(File.join(@output_directory, @reportnamer.junit_reportname))
              }
            )
            CollateJunitReportsAction.run(config)
            delete_globbed_intermediatefiles("#{@output_directory}/#{@reportnamer.junit_numbered_fileglob}")
          end
        end

        def collate_html_reports
          report_files = sort_globbed_files("#{@output_directory}/#{@reportnamer.html_fileglob}")
          if report_files.size > 1
            config = create_config(
              CollateJunitReportsAction,
              {
                reports: report_files,
                collated_report: File.absolute_path(File.join(@output_directory, @reportnamer.html_reportname))
              }
            )
            CollateHtmlReportsAction.run(config)
            delete_globbed_intermediatefiles("#{@output_directory}/#{@reportnamer.html_numbered_fileglob}")
          end
        end
      end
    end
  end
end
