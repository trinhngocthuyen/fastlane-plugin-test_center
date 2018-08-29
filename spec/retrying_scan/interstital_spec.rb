describe TestCenter::Helper::RetryingScan do
  describe 'interstitial', interstitial: true do
    it 'clears out `test_result` bundles when created' do
      expected_calls = []
      allow(Dir).to receive(:glob).and_call_original
      expect(Dir).to receive(:glob).with(/.*\.test_result/) do
        expected_calls << :glob
        ['./AtomicDragon.test_result']
      end
      allow(FileUtils).to receive(:rm_rf).and_call_original
      expect(FileUtils).to receive(:rm_rf).with(['./AtomicDragon.test_result']) do
        expected_calls << :rm_rf
      end
      expect(expected_calls).to eq([:glob, :rm_rf, :correcting_scan, :correcting_scan])
      Interstitial.new(
        result_bundle: true,
        output_directory: '.',
      )
    end
  end
end