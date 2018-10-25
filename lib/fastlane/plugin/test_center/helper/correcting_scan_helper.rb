module TestCenter
  module Helper
    require 'fastlane_core/ui/ui.rb'
    require 'plist'
    require 'json'
    class CorrectingScanHelper
      include TestCenter::Helper::RetryingScan::SimulatorManager

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
        ObjectSpace.define_finalizer( self, self.class.finalize )
        super()
      end

      def self.finalize
        proc { cleanup_simulators }
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
          @scan_options[:devices] = devices(current_batch_index)
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

      def setup_pipes_for_fork
        @pipe_endpoints = []
        (0..@batch_count).each do |current_batch_index|
          @pipe_endpoints << IO.pipe
        end
      end

      def connect_subprocess_endpoint(batch_index)
        mainprocess_reader, = @pipe_endpoints[batch_index]
        mainprocess_reader.close # we are now in the subprocess

        subprocess_output_dir = Dir.mktmpdir
        puts "log files written to #{subprocess_output_dir}"
        subprocess_logfilepath = File.join(subprocess_output_dir, "batchscan_#{current_batch_index}.log")
        subprocess_logfile = File.open(subprocess_logfilepath, 'w')
        $stdout.reopen(subprocess_logfile)
        $stderr.reopen(subprocess_logfile)
      end

      def disconnect_subprocess_endpoints
        # This is done from the parent process to close the pipe from its end so
        # that its reading of the pipe doesn't block waiting for more IO on the
        # writer.
        # This has to be done after the fork, because we don't want the subprocess
        # to receive its endpoint already closed.
        @pipe_endpoints.each { |_, subprocess_writer| subprocess_writer.close }
      end

      def ensure_conflict_free_scanlogging(batch_index)
        @scan_options[:buildlog_path] = @scan_options[:buildlog_path] + "-#{current_batch_index}"
      end

      def send_subprocess_result(batch_index, result)
        _, subprocess_writer = @pipe_endpoints[batch_index]
        subprocess_logfile = $stdout # Remember? We changed $stdout in :connect_subprocess_endpoint to be a File.

        subprocess_output = {
          'subprocess_logfilepath' => subprocess_logfile.path,
          'tests_passed' => result
        }
        subprocess_writer.puts subprocess_output.to_json
        subprocess_writer.flush
        subprocess_logfile.close
      end

      def parse_subprocess_results(subprocess_index, subprocess_output)
        subprocess_result = {
          'tests_passed' => false
        }
        if subprocess_output.empty?
          FastlaneCore::UI.error("Something went terribly wrong: no output from parallelized batch #{subprocess_index}!")
        else
          subprocess_result = JSON.parse(subprocess_output)
        end
        subprocess_result
      end

      def stream_subprocess_result_to_console(subprocess_logfilepath)
        puts '-' * 80
        if File.exist?(subprocess_logfilepath)
          File.foreach(subprocess_logfilepath, 'r') do |line|
            puts line
          end
        end
      end

      def wait_for_subprocesses
        disconnect_subprocess_endpoints # to ensure no blocking on the pipe
        FastlaneCore::Helper.show_loading_indicator("Scanning in #{@batch_count} batches")
        Process.waitall
        FastlaneCore::Helper.hide_loading_indicator
      end

      def handle_subprocesses_results
        tests_passed = false
        FastlaneCore::UI.header("Output from parallelized batch run")
        @pipe_endpoints.each_with_index do |endpoints, index|
          mainprocess_reader, = endpoints
          subprocess_result = parse_subprocess_results(index, mainprocess_reader.read)
          mainprocess_reader.close
          stream_subprocess_result_to_console(subprocess_result['subprocess_logfilepath'])
          tests_passed = subprocess_result['tests_passed']
        end
        puts '=' * 80
        tests_passed
      end

      def each_batch
        tests_passed = true
        if @parallelize
          setup_simulators
          setup_pipes_for_fork

          @test_collector.test_batches.each_with_index do |test_batch, current_batch_index|
            fork do
              connect_subprocess_endpoint(current_batch_index)
              ensure_conflict_free_scanlogging(current_batch_index)
              begin
                tests_passed = yield(test_batch, current_batch_index)
              ensure
                send_subprocess_result(current_batch_index, tests_passed)
              end
              exit(true) # last command to ensure subprocess ends quickly.
            end
          end
          wait_for_subprocesses
          tests_passed = handle_subprocesses_results && tests_passed
          cleanup_simulators
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
