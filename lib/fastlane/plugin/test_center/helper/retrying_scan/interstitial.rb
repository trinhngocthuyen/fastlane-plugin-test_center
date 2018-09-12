module TestCenter
  module Helper
    module RetryingScan
      class Interstitial
        def initialize(options)
          @create_test_result_bundle = options[:result_bundle]
          @output_directory = options[:output_directory]
          @testrun_completed_block = options[:testrun_completed_block]
          before_all
        end

        def before_all
          if @create_test_result_bundle
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

        def send_info(batch, try_count, reportnamer, output_directory)
          report_filepath = File.join(output_directory, reportnamer.junit_last_reportname)

          @testrun_completed_block && @testrun_completed_block.call({
            failed: [], # junit_results[:failed],
            passing: [], # junit_results[:passing],
            batch: batch,
            try_count: try_count,
            report_filepath: report_filepath
          })
        end
      end
    end
  end
end
