module TestCenter
  module Helper
    require 'fastlane_core/ui/ui.rb'
    require 'plist'
    require 'json'
    class CorrectingScanHelper
      Parallelization = TestCenter::Helper::RetryingScan::Parallelization

      attr_reader :retry_total_count

      def initialize(multi_scan_options)
        @output_directory = multi_scan_options[:output_directory] || 'test_results'
        @try_count = multi_scan_options[:try_count]
        @retry_total_count = 0
        @testrun_completed_block = multi_scan_options[:testrun_completed_block]
        @given_custom_report_file_name = multi_scan_options[:custom_report_file_name]
        @given_output_types = multi_scan_options[:output_types]
        @given_output_files = multi_scan_options[:output_files]
        @parallelize = multi_scan_options[:parallelize]
        @fork_pipes = []
        @scan_options = multi_scan_options.reject do |option, _|
          %i[
            output_directory
            only_testing
            skip_testing
            clean
            try_count
            batch_count
            custom_report_file_name
            fail_build
            testrun_completed_block
            output_types
            output_files
            parallelize
          ].include?(option)
        end
        @scan_options[:clean] = false
        @scan_options[:disable_concurrent_testing] = true
        @test_collector = TestCollector.new(multi_scan_options)
        @batch_count = @test_collector.test_batches.size
        @parallelizer = Parallelization.new(@batch_count) if @parallelize
      end

      def scan
        all_tests_passed = true
        @testables_count = @test_collector.testables.size
        all_tests_passed = each_batch do |test_batch, current_batch_index|
          output_directory = @output_directory
          unless @testables_count == 1
            output_directory_suffix = test_batch.first.split('/').first
            output_directory = File.join(@output_directory, "results-#{output_directory_suffix}")
          end
          reset_for_new_testable(output_directory)
          FastlaneCore::UI.header("Starting test run on batch '#{current_batch_index}'")
          @interstitial.batch = current_batch_index
          @interstitial.output_directory = output_directory
          @interstitial.before_all
          testrun_passed = correcting_scan(
            {
              only_testing: test_batch,
              output_directory: output_directory
            },
            current_batch_index,
            @reportnamer
          )
          all_tests_passed = testrun_passed && all_tests_passed
          TestCenter::Helper::RetryingScan::ReportCollator.new(
            output_directory: output_directory,
            reportnamer: @reportnamer,
            scheme: @scan_options[:scheme],
            result_bundle: @scan_options[:result_bundle]
          ).collate
          testrun_passed && all_tests_passed
        end
        all_tests_passed
      end

      def each_batch
        tests_passed = true
        if @parallelize
          @parallelizer.setup_simulators(@scan_options[:devices] || Array(@scan_options[:device]))
          @parallelizer.setup_pipes_for_fork

          @test_collector.test_batches.each_with_index do |test_batch, current_batch_index|
            fork do
              @parallelizer.connect_subprocess_endpoint(current_batch_index)
              @parallelizer.ensure_conflict_free_scanlogging(current_batch_index)
              begin
                @scan_options[:devices] = @parallelizer.devices(current_batch_index)
                tests_passed = yield(test_batch, current_batch_index)
              ensure
                @parallelizer.send_subprocess_result(current_batch_index, tests_passed)
              end
              exit(true) # last command to ensure subprocess ends quickly.
            end
          end
          @parallelizer.wait_for_subprocesses
          tests_passed = @parallelizer.handle_subprocesses_results && tests_passed
          @parallelizer.cleanup_simulators
        else
          @test_collector.test_batches.each_with_index do |test_batch, current_batch_index|
            tests_passed = yield(test_batch, current_batch_index)
          end
        end
        tests_passed
      end

      def testrun_output_directory
        if @test_collector.testables.size.one?
          @output_directory
        else
          File.join(@output_directory, "results-#{testable}")
        end
      end

      def reset_reportnamer
        @reportnamer = ReportNameHelper.new(
          @given_output_types,
          @given_output_files,
          @given_custom_report_file_name
        )
      end

      def reset_interstitial(output_directory)
        @interstitial = TestCenter::Helper::RetryingScan::Interstitial.new(
          @scan_options.merge(
            {
              output_directory: output_directory,
              reportnamer: @reportnamer
            }
          )
        )
      end

      def reset_for_new_testable(output_directory)
        reset_reportnamer
        reset_interstitial(output_directory)
      end

      def correcting_scan(scan_run_options, batch, reportnamer)
        scan_options = @scan_options.merge(scan_run_options)
        try_count = 0
        tests_passed = true
        begin
          try_count += 1
          config = FastlaneCore::Configuration.create(
            Fastlane::Actions::ScanAction.available_options,
            scan_options.merge(reportnamer.scan_options)
          )
          quit_simulators
          Fastlane::Actions::ScanAction.run(config)
          @interstitial.finish_try(try_count)
          tests_passed = true
        rescue FastlaneCore::Interface::FastlaneTestFailure => e
          FastlaneCore::UI.verbose("Scan failed with #{e}")
          if try_count < @try_count
            @retry_total_count += 1
            scan_options.delete(:code_coverage)
            tests_to_retry = failed_tests(reportnamer, scan_options[:output_directory]).map(&:shellescape)

            scan_options[:only_testing] = tests_to_retry
            FastlaneCore::UI.message('Re-running scan on only failed tests')
            @interstitial.finish_try(try_count)
            retry
          end
          tests_passed = false
        end
        tests_passed
      end

      def failed_tests(reportnamer, output_directory)
        report_filepath = File.join(output_directory, reportnamer.junit_last_reportname)
        config = FastlaneCore::Configuration.create(
          Fastlane::Actions::TestsFromJunitAction.available_options,
          {
            junit: File.absolute_path(report_filepath)
          }
        )
        Fastlane::Actions::TestsFromJunitAction.run(config)[:failed]
      end

      def quit_simulators
        Fastlane::Actions.sh("killall -9 'iPhone Simulator' 'Simulator' 'SimulatorBridge' &> /dev/null || true", log: false)
        launchctl_list_count = 0
        while Fastlane::Actions.sh('launchctl list | grep com.apple.CoreSimulator.CoreSimulatorService || true', log: false) != ''
          break if (launchctl_list_count += 1) > 10
          Fastlane::Actions.sh('launchctl remove com.apple.CoreSimulator.CoreSimulatorService &> /dev/null || true', log: false)
          sleep(1)
        end
      end
    end
  end
end
