describe TestCenter::Helper::RetryingScan do
  describe 'interstitial', interstitial: true do
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
      allow(FastlaneCore::DeviceManager).to receive(:simulators).and_return(mock_devices)
      expect(mock_devices[0]).to receive(:`).with('xcrun simctl erase E697990C-3A83-4C01-83D1-C367011B31EE')
      expect(mock_devices[1]).not_to receive(:reset)
      stitcher.reset_simulators(
        ['platform=iOS Simulator,id=E697990C-3A83-4C01-83D1-C367011B31EE']
      )
    end

    it 'sends all info after a run of scan' do
      testrun_completed_block = lambda { |info| true }
      expect(testrun_completed_block).to receive(:call).with({
        failed: [], # junit_results[:failed],
        passing: [], # junit_results[:passing],
        batch: 1,
        try_count: 2,
        report_filepath: './relative_path/to/last_produced_junit.xml'
      })
      stitcher = Interstitial.new(
        output_directory: '.',
        testrun_completed_block: testrun_completed_block
      )
      mock_reportnamer = OpenStruct.new
      allow(mock_reportnamer).to receive(:junit_last_reportname).and_return('relative_path/to/last_produced_junit.xml')
      stitcher.send_info(1, 2, mock_reportnamer, '.')
    end
  end
end