module TestCenter
  module Helper
    module RetryingScan
      class Interstitial
        def initialize(options)
          @output_directory = options[:output_directory]
          @testrun_completed_block = options[:testrun_completed_block]
          @result_bundle = options[:result_bundle]
          @scheme = options[:scheme]
          @batch = options[:batch]
          @reportnamer = options[:reportnamer]
          before_all
        end

        def before_all
          if @result_bundle
            remove_preexisting_test_result_bundles
          end
        end

        def remove_preexisting_test_result_bundles
          glob_pattern = "#{@output_directory}/.*\.test_result"
          preexisting_test_result_bundles = Dir.glob(glob_pattern)
          FileUtils.rm_rf(preexisting_test_result_bundles)
        end

        def reset_simulators(destinations)
          simulators = FastlaneCore::DeviceManager.simulators('iOS')
          simulator_ids_to_reset = []
          destinations.each do |destination|
            destination.split(',').each do |destination_pair|
              key, value = destination_pair.split('=')
              if key == 'id'
                simulator_ids_to_reset << value
              end
            end
          end
          simulators.each do |simulator|
            simulator.reset if simulator_ids_to_reset.include?(simulator.udid)
          end
        end

        def send_info_for_try(try_count)
          report_filepath = File.join(@output_directory, @reportnamer.junit_last_reportname)

          config = FastlaneCore::Configuration.create(
            Fastlane::Actions::TestsFromJunitAction.available_options,
            {
              junit: File.absolute_path(report_filepath)
            }
          )
          junit_results = Fastlane::Actions::TestsFromJunitAction.run(config)
          info = {
            failed: junit_results[:failed],
            passing: junit_results[:passing],
            batch: @batch,
            try_count: try_count,
            report_filepath: report_filepath
          }

          if @reportnamer.includes_html?
            html_report_filepath = File.join(@output_directory, @reportnamer.html_last_reportname)
            info[:html_report_filepath] = html_report_filepath
          end
          if @reportnamer.includes_json?
            json_report_filepath = File.join(@output_directory, @reportnamer.json_last_reportname)
            info[:json_report_filepath] = json_report_filepath
          end
          if @result_bundle
            test_result_suffix = '.test_result'
            test_result_suffix.prepend("_#{@reportnamer.report_count}") unless @reportnamer.report_count.zero?
            test_result_bundlepath = File.join(@output_directory, @scheme) + test_result_suffix
            info[:test_result_bundlepath] = test_result_bundlepath
          end
          @testrun_completed_block && @testrun_completed_block.call(info)
        end
      end
    end
  end
end
