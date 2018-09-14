describe TestCenter::Helper::RetryingScan do
  describe 'interstitial', interstitial: true do
    before(:each) do
      allow(File).to receive(:exist?).and_call_original
    end

    Interstitial = TestCenter::Helper::RetryingScan::Interstitial
    
    it 'clears out `test_result` bundles when created' do
      allow(Dir).to receive(:glob).and_call_original
      allow(FileUtils).to receive(:rm_rf).and_call_original

      expect(Dir).to receive(:glob).with(/.*\.test_result/).and_return(['./AtomicDragon.test_result'])
      expect(FileUtils).to receive(:rm_rf).with(['./AtomicDragon.test_result'])
      Interstitial.new(
        result_bundle: true,
        output_directory: '.',
      )
    end

    it 'resets a simulator between each run' do
      stitcher = Interstitial.new(
        output_directory: '.',
      )
      mock_devices = [
        FastlaneCore::DeviceManager::Device.new(
          name: 'iPhone Amazing',
          udid: 'E697990C-3A83-4C01-83D1-C367011B31EE',
          os_type: 'iOS',
          os_version: '99.0',
          state: 'Shutdown',
          is_simulator: true
        ),
        FastlaneCore::DeviceManager::Device.new(
          name: 'iPhone Bland',
          udid: 'THIS-IS-A-UNIQUE-DEVICE-ID',
          os_type: 'iOS',
          os_version: '3.0',
          state: 'Booted',
          is_simulator: true
        )
      ]
      allow(Scan).to receive(:config).and_return(
        {
          destination: ['platform=iOS Simulator,id=E697990C-3A83-4C01-83D1-C367011B31EE']
        }
      )
      allow(FastlaneCore::DeviceManager).to receive(:simulators).and_return(mock_devices)
      expect(mock_devices[0]).to receive(:`).with('xcrun simctl erase E697990C-3A83-4C01-83D1-C367011B31EE')
      expect(mock_devices[1]).not_to receive(:reset)
      expect(stitcher).to receive(:send_info_for_try)
      stitcher.finish_try(1)
    end

    it 'sends all info after a run of scan' do
      testrun_completed_block = lambda { |info| true }
      expect(testrun_completed_block).to receive(:call).with({
        failed: ['BagOfTests/CoinTossingUITests/testResultIsTails'],
        passing: ['BagOfTests/CoinTossingUITests/testResultIsHeads'],
        batch: 1,
        try_count: 2,
        report_filepath: './relative_path/to/last_produced_junit.xml'
      })
      mock_reportnamer = OpenStruct.new
      allow(mock_reportnamer).to receive(:junit_last_reportname).and_return('relative_path/to/last_produced_junit.xml')

      stitcher = Interstitial.new(
        output_directory: '.',
        batch: 1,
        reportnamer: mock_reportnamer,
        testrun_completed_block: testrun_completed_block
      )
      allow(File).to receive(:exist?).with(%r{.*relative_path/to/last_produced_junit.xml}).and_return(true)
      allow(Fastlane::Actions::TestsFromJunitAction).to receive(:run).and_return(
        {
          failed: ['BagOfTests/CoinTossingUITests/testResultIsTails'],
          passing: ['BagOfTests/CoinTossingUITests/testResultIsHeads']
        }
      )
      stitcher.send_info_for_try(2)
    end

    it 'sends all info and the html report file path after a run of scan' do
      testrun_completed_block = lambda { |info| true }
      expect(testrun_completed_block).to receive(:call).with({
        failed: ['BagOfTests/CoinTossingUITests/testResultIsTails'],
        passing: ['BagOfTests/CoinTossingUITests/testResultIsHeads'],
        batch: 1,
        try_count: 2,
        report_filepath: './relative_path/to/last_produced_junit.xml',
        html_report_filepath: './relative_path/to/last_produced_html.html'
      })
      mock_reportnamer = OpenStruct.new
      allow(mock_reportnamer).to receive(:junit_last_reportname).and_return('relative_path/to/last_produced_junit.xml')
      allow(mock_reportnamer).to receive(:includes_html?).and_return(true)
      allow(mock_reportnamer).to receive(:html_last_reportname).and_return('relative_path/to/last_produced_html.html')

      stitcher = Interstitial.new(
        output_directory: '.',
        batch: 1,
        reportnamer: mock_reportnamer,
        testrun_completed_block: testrun_completed_block
      )
      allow(File).to receive(:exist?).with(%r{.*relative_path/to/last_produced_junit.xml}).and_return(true)
      allow(Fastlane::Actions::TestsFromJunitAction).to receive(:run).and_return(
        {
          failed: ['BagOfTests/CoinTossingUITests/testResultIsTails'],
          passing: ['BagOfTests/CoinTossingUITests/testResultIsHeads']
        }
      )
      stitcher.send_info_for_try(2)
    end

    it 'sends all info and the json report file path after a run of scan' do
      testrun_completed_block = lambda { |info| true }
      expect(testrun_completed_block).to receive(:call).with({
        failed: ['BagOfTests/CoinTossingUITests/testResultIsTails'],
        passing: ['BagOfTests/CoinTossingUITests/testResultIsHeads'],
        batch: 1,
        try_count: 2,
        report_filepath: './relative_path/to/last_produced_junit.xml',
        json_report_filepath: './relative_path/to/last_produced.json'
      })
      mock_reportnamer = OpenStruct.new
      allow(mock_reportnamer).to receive(:junit_last_reportname).and_return('relative_path/to/last_produced_junit.xml')
      allow(mock_reportnamer).to receive(:includes_json?).and_return(true)
      allow(mock_reportnamer).to receive(:json_last_reportname).and_return('relative_path/to/last_produced.json')
      stitcher = Interstitial.new(
        output_directory: '.',
        reportnamer: mock_reportnamer,
        batch: 1,
        testrun_completed_block: testrun_completed_block
      )
      allow(File).to receive(:exist?).with(%r{.*relative_path/to/last_produced_junit.xml}).and_return(true)
      allow(Fastlane::Actions::TestsFromJunitAction).to receive(:run).and_return(
        {
          failed: ['BagOfTests/CoinTossingUITests/testResultIsTails'],
          passing: ['BagOfTests/CoinTossingUITests/testResultIsHeads']
        }
      )
      stitcher.send_info_for_try(2)
    end

    it 'sends all info and the test result bundlepath after a run of scan' do
      testrun_completed_block = lambda { |info| true }
      expect(testrun_completed_block).to receive(:call).with({
        failed: ['BagOfTests/CoinTossingUITests/testResultIsTails'],
        passing: ['BagOfTests/CoinTossingUITests/testResultIsHeads'],
        batch: 1,
        try_count: 2,
        report_filepath: './relative_path/to/last_produced_junit.xml',
        test_result_bundlepath: './AtomicHeart.test_result'
      })
      mock_reportnamer = OpenStruct.new
      allow(mock_reportnamer).to receive(:report_count).and_return(0)
      allow(mock_reportnamer).to receive(:junit_last_reportname).and_return('relative_path/to/last_produced_junit.xml')
      stitcher = Interstitial.new(
        output_directory: '.',
        result_bundle: true,
        scheme: 'AtomicHeart',
        reportnamer: mock_reportnamer,
        batch: 1,
        testrun_completed_block: testrun_completed_block
      )
      allow(File).to receive(:exist?).with(%r{.*relative_path/to/last_produced_junit.xml}).and_return(true)
      allow(Fastlane::Actions::TestsFromJunitAction).to receive(:run).and_return(
        {
          failed: ['BagOfTests/CoinTossingUITests/testResultIsTails'],
          passing: ['BagOfTests/CoinTossingUITests/testResultIsHeads']
        }
      )
      stitcher.send_info_for_try(2)

      expect(testrun_completed_block).to receive(:call).with({
        failed: ['BagOfTests/CoinTossingUITests/testResultIsTails'],
        passing: ['BagOfTests/CoinTossingUITests/testResultIsHeads'],
        batch: 1,
        try_count: 2,
        report_filepath: './relative_path/to/last_produced_junit.xml',
        test_result_bundlepath: './AtomicHeart_1.test_result'
      })
      allow(mock_reportnamer).to receive(:report_count).and_return(1)
      stitcher.send_info_for_try(2)
    end
  end
end