describe TestCenter::Helper::RetryingScan do
  describe 'report_collator', report_collator: true do
    require 'pry-byebug'

    ReportCollator = TestCenter::Helper::RetryingScan::ReportCollator

    before(:each) do
      @mock_reportnamer = OpenStruct.new
      allow(@mock_reportnamer).to receive(:junit_fileglob).and_return('report*.xml')
      allow(@mock_reportnamer).to receive(:junit_reportname).and_return('report.xml')
    end

    it 'collates junit reports correctly' do
      collator = ReportCollator.new(
        output_directory: '.',
        reportnamer: @mock_reportnamer
      )
      expect(collator).to receive(:sort_globbed_files).with('./report*.xml').and_return(['report.xml', 'report-1.xml', 'report-2.xml'])
      config = OpenStruct.new
      allow(config).to receive(:_values).and_return(
        {
            reports: ['report.xml', 'report-1.xml', 'report-2.xml'],
            collated_report: 'report.xml'
          }
      )
      expect(collator).to receive(:create_config).and_return(config)
      expect(Fastlane::Actions::CollateJunitReportsAction).to receive(:run) do |c|
        expect(c._values).to eq(
          {
            reports: ['report.xml', 'report-1.xml', 'report-2.xml'],
            collated_report: 'report.xml'
          }
        )
      end
      collator.collate_junit_reports
    end
  end
end