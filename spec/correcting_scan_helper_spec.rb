require 'json'
CorrectingScanHelper = TestCenter::Helper::CorrectingScanHelper
describe TestCenter do
  describe TestCenter::Helper do
    describe CorrectingScanHelper do
      describe 'scan' do
        before(:each) do
          @mock_reportnamer = OpenStruct.new
          allow(TestCenter::Helper::ReportNameHelper).to receive(:new).and_return(@mock_reportnamer)

          @mock_interstitcher = OpenStruct.new
          allow(TestCenter::Helper::RetryingScan::Interstitial).to receive(:new).and_return(@mock_interstitcher)

          @mock_testcollector = OpenStruct.new
          allow(TestCenter::Helper::TestCollector).to receive(:new).and_return(@mock_testcollector)

          @mock_collator = OpenStruct.new
          allow(TestCenter::Helper::RetryingScan::ReportCollator).to receive(:new).and_return(@mock_collator)
          
          allow(File).to receive(:exist?).and_call_original
        end

        it 'calls scan_testable for each testable' do
          allow(@mock_testcollector).to receive(:testables).and_return(['AtomicBoyTests'])
          scanner = CorrectingScanHelper.new(
            xctestrun: 'path/to/fake.xctestrun'
          )
          expect(scanner).to receive(:scan_testable).with('AtomicBoyTests').and_return(true).once
          results = scanner.scan
          expect(results).to eq(true)

          allow(@mock_testcollector).to receive(:testables).and_return(['AtomicBoyTests', 'AtomicBoyUITests'])
          scanner = CorrectingScanHelper.new(
            xctestrun: 'path/to/fake.xctestrun'
          )
          expect(scanner).to receive(:scan_testable).with('AtomicBoyTests').and_return(false).ordered.once
          expect(scanner).to receive(:scan_testable).with('AtomicBoyUITests').and_return(true).ordered.once
          results = scanner.scan
          expect(results).to eq(false)
        end

        it 'clears out test_rest bundles before calling correcting_scan' do
          allow(@mock_testcollector).to receive(:testables).and_return(['AtomicBoyTests', 'AtomicBoyUITests'])
          scanner = CorrectingScanHelper.new(
            xctestrun: 'path/to/fake.xctestrun',
            result_bundle: true,
            output_directory: '.',
            scheme: 'AtomicBoy'
          )
          allow(@mock_testcollector).to receive(:testables_tests).and_return(
            {
              'AtomicBoyTests' => [
                'AtomicBoyTests/AtomicBoyTests/testExample1',
                'AtomicBoyTests/AtomicBoyTests/testExample2',
                'AtomicBoyTests/AtomicBoyTests/testExample3',
                'AtomicBoyTests/AtomicBoyTests/testExample4'
              ],
              'AtomicBoyUITests' => [
                'AtomicBoyUITests/AtomicBoyUITests/testExample1',
                'AtomicBoyUITests/AtomicBoyUITests/testExample2',
                'AtomicBoyUITests/AtomicBoyUITests/testExample3',
                'AtomicBoyUITests/AtomicBoyUITests/testExample4'
              ]
            }
          )

          expected_calls = []
          expect(TestCenter::Helper::RetryingScan::Interstitial).to receive(:new).and_return(@mock_interstitcher)
          expect(scanner).to receive(:correcting_scan).twice do
            expected_calls << :correcting_scan
          end
          scanner.scan
          expect(expected_calls).to eq([:correcting_scan, :correcting_scan])
        end

        it 'scan calls correcting_scan once for one testable' do
          scanner = CorrectingScanHelper.new(
            xctestrun: 'path/to/fake.xctestrun',
            output_directory: '.'
          )
          allow(@mock_testcollector).to receive(:testables).and_return(['AtomicBoyTests'])
          expect(@mock_testcollector).to receive(:testables_tests).and_return(
            {
              'AtomicBoyTests' => [
                'AtomicBoyTests/AtomicBoyTests/testExample1',
                'AtomicBoyTests/AtomicBoyTests/testExample2',
                'AtomicBoyTests/AtomicBoyTests/testExample3',
                'AtomicBoyTests/AtomicBoyTests/testExample4'
              ]
            }
          )
          expect(scanner).to receive(:correcting_scan)
            .with(
              {
                only_testing: [
                  'AtomicBoyTests/AtomicBoyTests/testExample1',
                  'AtomicBoyTests/AtomicBoyTests/testExample2',
                  'AtomicBoyTests/AtomicBoyTests/testExample3',
                  'AtomicBoyTests/AtomicBoyTests/testExample4'
                ],
                output_directory: '.'
              },
              1,
              @mock_reportnamer
            )
          expect(@mock_collator).to receive(:collate)
          scanner.scan
        end

        it 'scan calls correcting_scan once for each of two testables' do
          scanner = CorrectingScanHelper.new(
            xctestrun: 'path/to/fake.xctestrun',
            output_directory: '.'
          )
          allow(@mock_testcollector).to receive(:testables).and_return(['AtomicBoyTests', 'AtomicBoyUITests'])
          expect(@mock_testcollector).to receive(:testables_tests).and_return(
            {
              'AtomicBoyTests' => [
                'AtomicBoyTests/AtomicBoyTests/testExample1',
                'AtomicBoyTests/AtomicBoyTests/testExample2',
                'AtomicBoyTests/AtomicBoyTests/testExample3',
                'AtomicBoyTests/AtomicBoyTests/testExample4'
              ],
              'AtomicBoyUITests' => [
                'AtomicBoyUITests/AtomicBoyUITests/testExample1',
                'AtomicBoyUITests/AtomicBoyUITests/testExample2',
                'AtomicBoyUITests/AtomicBoyUITests/testExample3',
                'AtomicBoyUITests/AtomicBoyUITests/testExample4'
              ]
            }
          ).twice
          expect(scanner).to receive(:correcting_scan)
            .with(
              {
                only_testing: [
                  'AtomicBoyTests/AtomicBoyTests/testExample1',
                  'AtomicBoyTests/AtomicBoyTests/testExample2',
                  'AtomicBoyTests/AtomicBoyTests/testExample3',
                  'AtomicBoyTests/AtomicBoyTests/testExample4'
                ],
                output_directory: './results-AtomicBoyTests'
              },
              1,
              @mock_reportnamer
            )
            .and_return(true)
            .ordered
            .once
          expect(scanner).to receive(:correcting_scan)
            .with(
              {
                only_testing: [
                  'AtomicBoyUITests/AtomicBoyUITests/testExample1',
                  'AtomicBoyUITests/AtomicBoyUITests/testExample2',
                  'AtomicBoyUITests/AtomicBoyUITests/testExample3',
                  'AtomicBoyUITests/AtomicBoyUITests/testExample4'
                ],
                output_directory: './results-AtomicBoyUITests'
              },
              1,
              @mock_reportnamer
            )
            .and_return(false)
            .ordered
            .once
          expect(@mock_collator).to receive(:collate).twice
          results = scanner.scan
          expect(results).to eq(false)
        end

        it 'scan calls correcting_scan twice for each batch in one testable' do
          scanner = CorrectingScanHelper.new(
            xctestrun: 'path/to/fake.xctestrun',
            batch_count: 2,
            output_directory: '.'
          )
          allow(@mock_testcollector).to receive(:testables).and_return(['AtomicBoyTests'])
          expect(@mock_testcollector).to receive(:testables_tests).and_return(
            {
              'AtomicBoyTests' => [
                'AtomicBoyTests/AtomicBoyTests/testExample1',
                'AtomicBoyTests/AtomicBoyTests/testExample2',
                'AtomicBoyTests/AtomicBoyTests/testExample3',
                'AtomicBoyTests/AtomicBoyTests/testExample4'
              ]
            }
          )
          expect(scanner).to receive(:correcting_scan)
            .with(
              {
                only_testing: [
                  'AtomicBoyTests/AtomicBoyTests/testExample1',
                  'AtomicBoyTests/AtomicBoyTests/testExample2'
                ],
                output_directory: '.'
              },
              1,
              @mock_reportnamer
            )
            .and_return(true)
            .ordered
            .once
          expect(scanner).to receive(:correcting_scan)
            .with(
              {
                only_testing: [
                  'AtomicBoyTests/AtomicBoyTests/testExample3',
                  'AtomicBoyTests/AtomicBoyTests/testExample4'
                ],
                output_directory: '.'
              },
              2,
              @mock_reportnamer
            )
            .and_return(true)
            .ordered
            .once
          expect(@mock_collator).to receive(:collate)
          results = scanner.scan
          expect(results).to eq(true)
        end

        it 'scan calls correcting_scan twice for each batch in two testables' do
          scanner = CorrectingScanHelper.new(
            xctestrun: 'path/to/fake.xctestrun',
            batch_count: 2,
            output_directory: '.'
          )
          allow(@mock_testcollector).to receive(:testables).and_return(['AtomicBoyTests', 'AtomicBoyUITests'])
          expect(@mock_testcollector).to receive(:testables_tests).and_return(
            {
              'AtomicBoyTests' => [
                'AtomicBoyTests/AtomicBoyTests/testExample1',
                'AtomicBoyTests/AtomicBoyTests/testExample2',
                'AtomicBoyTests/AtomicBoyTests/testExample3',
                'AtomicBoyTests/AtomicBoyTests/testExample4'
              ],
              'AtomicBoyUITests' => [
                'AtomicBoyUITests/AtomicBoyUITests/testExample1',
                'AtomicBoyUITests/AtomicBoyUITests/testExample2',
                'AtomicBoyUITests/AtomicBoyUITests/testExample3',
                'AtomicBoyUITests/AtomicBoyUITests/testExample4'
              ]
            }
          ).twice
          expect(scanner).to receive(:correcting_scan)
            .with(
              {
                only_testing: [
                  'AtomicBoyTests/AtomicBoyTests/testExample1',
                  'AtomicBoyTests/AtomicBoyTests/testExample2'
                ],
                output_directory: './results-AtomicBoyTests'
              },
              1,
              @mock_reportnamer
            )
            .and_return(true)
            .ordered
            .once
          expect(scanner).to receive(:correcting_scan)
            .with(
              {
                only_testing: [
                  'AtomicBoyTests/AtomicBoyTests/testExample3',
                  'AtomicBoyTests/AtomicBoyTests/testExample4'
                ],
                output_directory: './results-AtomicBoyTests'
              },
              2,
              @mock_reportnamer
            )
            .and_return(false)
            .ordered
            .once
          expect(scanner).to receive(:correcting_scan)
            .with(
              {
                only_testing: [
                  'AtomicBoyUITests/AtomicBoyUITests/testExample1',
                  'AtomicBoyUITests/AtomicBoyUITests/testExample2'
                ],
                output_directory: './results-AtomicBoyUITests'
              },
              1,
              @mock_reportnamer
            )
            .and_return(true)
            .ordered
            .once
          expect(scanner).to receive(:correcting_scan)
            .with(
              {
                only_testing: [
                  'AtomicBoyUITests/AtomicBoyUITests/testExample3',
                  'AtomicBoyUITests/AtomicBoyUITests/testExample4'
                ],
                output_directory: './results-AtomicBoyUITests'
              },
              2,
              @mock_reportnamer
            )
            .and_return(true)
            .ordered
            .once
          expect(@mock_collator).to receive(:collate).twice
          results = scanner.scan
          expect(results).to eq(false)
        end

        it 'scan calls correcting_scan with :skip_testing with two testables' do
          scanner = CorrectingScanHelper.new(
            xctestrun: 'path/to/fake.xctestrun',
            output_directory: '.',
            skip_testing: [
              'AtomicBoyTests/AtomicBoyTests/testExample2',
              'AtomicBoyTests/AtomicBoyTests/testExample3',
              'AtomicBoyUITests/AtomicBoyUITests/testExample4'
            ]
          )
          allow(@mock_testcollector).to receive(:testables).and_return(['AtomicBoyTests', 'AtomicBoyUITests'])
          allow(File).to receive(:exist?).with('path/to/fake.xctestrun').and_return(true)
          allow(@mock_testcollector).to receive(:testables_tests)
            .and_return(
              'AtomicBoyTests' => [
                'AtomicBoyTests/AtomicBoyTests/testExample1',
                'AtomicBoyTests/AtomicBoyTests/testExample4'
              ],
              'AtomicBoyUITests' => [
                'AtomicBoyUITests/AtomicBoyUITests/testExample1',
                'AtomicBoyUITests/AtomicBoyUITests/testExample2',
                'AtomicBoyUITests/AtomicBoyUITests/testExample3'
              ]
            )

          expect(scanner).to receive(:correcting_scan)
            .with(
              {
                only_testing: [
                  'AtomicBoyTests/AtomicBoyTests/testExample1',
                  'AtomicBoyTests/AtomicBoyTests/testExample4'
                ],
                output_directory: './results-AtomicBoyTests'
              },
              1,
              @mock_reportnamer
            )
            .and_return(false)
            .ordered
            .once
          expect(scanner).to receive(:correcting_scan)
            .with(
              {
                only_testing: [
                  'AtomicBoyUITests/AtomicBoyUITests/testExample1',
                  'AtomicBoyUITests/AtomicBoyUITests/testExample2',
                  'AtomicBoyUITests/AtomicBoyUITests/testExample3'
                ],
                output_directory: './results-AtomicBoyUITests'
              },
              1,
              @mock_reportnamer
            )
            .and_return(true)
            .ordered
            .once
          expect(@mock_collator).to receive(:collate).twice
          results = scanner.scan
          expect(results).to eq(false)
        end

        it 'scan calls correcting_scan twice each with one batch of tests minus :skipped_testing items for one testable' do
          scanner = CorrectingScanHelper.new(
            xctestrun: 'path/to/fake.xctestrun',
            output_directory: '.',
            batch_count: 2,
            skip_testing: [
              'AtomicBoyTests/AtomicBoyTests/testExample2',
              'AtomicBoyTests/AtomicBoyTests/testExample3',
              'AtomicBoyUITests/AtomicBoyUITests/testExample4'
            ]
          )
          allow(@mock_testcollector).to receive(:testables).and_return(['AtomicBoyTests'])
          allow(File).to receive(:exist?).with('path/to/fake.xctestrun').and_return(true)
          # pretend that @mock_testcollector is doing its job and parsed out the tests in skip_testing
          allow(@mock_testcollector).to receive(:testables_tests)
            .and_return(
              'AtomicBoyTests' => [
                'AtomicBoyTests/AtomicBoyTests/testExample1',
                'AtomicBoyTests/AtomicBoyTests/testExample4'
              ]
            )
          expect(scanner).to receive(:correcting_scan)
            .with(
              {
                only_testing: [
                  'AtomicBoyTests/AtomicBoyTests/testExample1'
                ],
                output_directory: '.'
              },
              1,
              @mock_reportnamer
            )
            .and_return(true)
            .ordered
            .once
          expect(scanner).to receive(:correcting_scan)
            .with(
              {
                only_testing: [
                  'AtomicBoyTests/AtomicBoyTests/testExample4'
                ],
                output_directory: '.'
              },
              2,
              @mock_reportnamer
            )
            .and_return(true)
            .ordered
            .once
          expect(@mock_collator).to receive(:collate)
          results = scanner.scan
          expect(results).to eq(true)
        end

        it 'scan calls correcting_scan twice each with one batch of tests minus :skipped_testing items for two testables' do
          scanner = CorrectingScanHelper.new(
            xctestrun: 'path/to/fake.xctestrun',
            output_directory: '.',
            batch_count: 2,
            skip_testing: [
              'AtomicBoyTests/AtomicBoyTests/testExample2',
              'AtomicBoyTests/AtomicBoyTests/testExample3',
              'AtomicBoyUITests/AtomicBoyUITests/testExample4'
            ]
          )
          allow(@mock_testcollector).to receive(:testables).and_return(['AtomicBoyTests', 'AtomicBoyUITests'])
          allow(File).to receive(:exist?).with('path/to/fake.xctestrun').and_return(true)
          allow(@mock_testcollector).to receive(:testables_tests)
            .and_return(
              'AtomicBoyTests' => [
                'AtomicBoyTests/AtomicBoyTests/testExample1',
                'AtomicBoyTests/AtomicBoyTests/testExample4'
              ],
              'AtomicBoyUITests' => [
                'AtomicBoyUITests/AtomicBoyUITests/testExample1',
                'AtomicBoyUITests/AtomicBoyUITests/testExample2',
                'AtomicBoyUITests/AtomicBoyUITests/testExample3'
              ]
            )
          expect(scanner).to receive(:correcting_scan)
            .with(
              {
                only_testing: [
                  'AtomicBoyTests/AtomicBoyTests/testExample1'
                ],
                output_directory: './results-AtomicBoyTests'
              },
              1,
              @mock_reportnamer
            ).and_return(true)
            .ordered
            .once
          expect(scanner).to receive(:correcting_scan)
            .with(
              {
                only_testing: [
                  'AtomicBoyTests/AtomicBoyTests/testExample4'
                ],
                output_directory: './results-AtomicBoyTests'
              },
              2,
              @mock_reportnamer
            )
            .and_return(true)
            .ordered
            .once
          expect(scanner).to receive(:correcting_scan)
            .with(
              {
                only_testing: [
                  'AtomicBoyUITests/AtomicBoyUITests/testExample1',
                  'AtomicBoyUITests/AtomicBoyUITests/testExample2'
                ],
                output_directory: './results-AtomicBoyUITests'
              },
              1,
              @mock_reportnamer
            )
            .and_return(true)
            .ordered
            .once
          expect(scanner).to receive(:correcting_scan)
            .with(
              {
                only_testing: [
                  'AtomicBoyUITests/AtomicBoyUITests/testExample3'
                ],
                output_directory: './results-AtomicBoyUITests'
              },
              2,
              @mock_reportnamer
            )
            .and_return(false)
            .ordered
            .once
          expect(@mock_collator).to receive(:collate).twice
          expect(@mock_interstitcher).to receive(:before_all).exactly(4).times
          results = scanner.scan
          expect(results).to eq(false)
        end
      end

      describe 'correcting_scan' do
        before(:each) do
          allow(Fastlane::Actions).to receive(:sh)
          allow_any_instance_of(CorrectingScanHelper).to receive(:sleep)

          @mock_interstitcher = OpenStruct.new
          allow(@mock_interstitcher).to receive(:finish_try)
          allow(TestCenter::Helper::RetryingScan::Interstitial).to receive(:new).and_return(@mock_interstitcher)

          @mock_testcollector = OpenStruct.new
          allow(TestCenter::Helper::TestCollector).to receive(:new).and_return(@mock_testcollector)
        end
        describe 'one testable' do
          describe 'code coverage' do
            before(:each) do
              allow(File).to receive(:exist?).and_call_original
              allow(File).to receive(:exist?).and_return(true)
              allow(@mock_testcollector).to receive(:testables).and_return(['AtomicBoyTests'])
            end

            it 'stops sending :code_coverage down after the first run' do
              scanner = CorrectingScanHelper.new(
                xctestrun: 'path/to/fake.xctestrun',
                output_directory: '.',
                try_count: 2,
                batch_count: 2,
                clean: true,
                code_coverage: true
              )
              allow(scanner).to receive(:failed_tests).and_return(['AtomicBoyUITests/AtomicBoyUITests/testExample3'])
              allow(scanner).to receive(:testrun_info).and_return({ failed: [] })
              expect(Fastlane::Actions::ScanAction).to receive(:run).ordered.once do |config|
                expect(config._values).to have_key(:code_coverage)
                expect(config._values[:code_coverage]).to eq(true)
                raise FastlaneCore::Interface::FastlaneTestFailure, 'failed tests'
              end
              expect(Fastlane::Actions::ScanAction).to receive(:run).ordered.once do |config|
                expect(config._values).not_to have_key(:code_coverage)
              end
              scanner.correcting_scan(
                {
                  output_directory: '.'
                },
                1,
                ReportNameHelper.new('html,junit')
              )
            end
          end

          describe 'no batches' do
            before(:all) do
              @xcpretty_json_file_output = ENV['XCPRETTY_JSON_FILE_OUTPUT']
            end
            after(:all) do
              ENV['XCPRETTY_JSON_FILE_OUTPUT'] = @xcpretty_json_file_output
            end

            before(:each) do
              allow(File).to receive(:exist?).and_call_original
              allow(File).to receive(:exist?).and_return(true)
              allow(@mock_testcollector).to receive(:testables).and_return(['AtomicBoyTests'])
            end

            it 'calls scan once with no failures' do
              scanner = CorrectingScanHelper.new(
                xctestrun: 'path/to/fake.xctestrun',
                output_directory: '.',
                try_count: 2,
                batch_count: 2,
                clean: true
              )
              expect(Fastlane::Actions::ScanAction).to receive(:run).once do |config|
                expect(config._values).to have_key(:output_files)
                expect(config._values).not_to have_key(:try_count)
                expect(config._values).not_to have_key(:batch_count)
                expect(config._values[:clean]).to be(false)
                expect(config._values).not_to have_key(:custom_report_file_name)
                expect(config._values[:output_files]).to eq('report.html,report.junit')
              end
              result = scanner.correcting_scan(
                {
                  output_directory: '.'
                },
                1,
                ReportNameHelper.new('html,junit')
              )
              expect(scanner.retry_total_count).to eq(0)
              expect(result).to eq(true)
            end

            it 'calls scan three times when two runs have failures' do
              scanner = CorrectingScanHelper.new(
                xctestrun: 'path/to/fake.xctestrun',
                output_directory: '.',
                try_count: 3
              )
              allow(File).to receive(:exist?).and_call_original
              allow(File).to receive(:exist?).with(%r{.*/report(-[23])?.junit}).and_return(true)
              allow(scanner).to receive(:failed_tests).and_return(['BagOfTests/CoinTossingUITests/testResultIsTails'])
              expect(Fastlane::Actions::ScanAction).to receive(:run).ordered.once do |config|
                raise FastlaneCore::Interface::FastlaneTestFailure, 'failed tests'
              end
              expect(Fastlane::Actions::ScanAction).to receive(:run).ordered.once do |config|
                raise FastlaneCore::Interface::FastlaneTestFailure, 'failed tests'
              end
              expect(Fastlane::Actions::ScanAction).to receive(:run).ordered.once do |config|
                raise FastlaneCore::Interface::FastlaneTestFailure, 'failed tests'
              end
              result = scanner.correcting_scan(
                {
                  output_directory: '.'
                },
                1,
                ReportNameHelper.new('html,junit')
              )
              expect(scanner.retry_total_count).to eq(2)
              expect(result).to eq(false)
            end
          end
        end
      end
    end
  end
end
