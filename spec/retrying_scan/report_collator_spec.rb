describe TestCenter::Helper::RetryingScan do
  describe 'report_collator', report_collator: true do
    require 'pry-byebug'

    ReportCollator = TestCenter::Helper::RetryingScan::ReportCollator

    before(:each) do
      @mock_reportnamer = OpenStruct.new
      allow(@mock_reportnamer).to receive(:junit_fileglob).and_return('report*.xml')
      allow(@mock_reportnamer).to receive(:html_fileglob).and_return('report*.html')
      allow(@mock_reportnamer).to receive(:junit_numbered_fileglob).and_return("report-[1-9]*.xml")
      allow(@mock_reportnamer).to receive(:html_numbered_fileglob).and_return("report-[1-9]*.html")
      allow(@mock_reportnamer).to receive(:junit_reportname).and_return('report.xml')
      allow(@mock_reportnamer).to receive(:html_reportname).and_return('report.html')
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
      expect(collator).to receive(:delete_globbed_intermediatefiles).with('./report-[1-9]*.xml')
      collator.collate_junit_reports
    end

    it 'collates html reports correctly' do
      collator = ReportCollator.new(
        output_directory: '.',
        reportnamer: @mock_reportnamer
      )
      expect(collator).to receive(:sort_globbed_files).with('./report*.html').and_return(['report.html', 'report-1.html', 'report-2.html'])
      config = OpenStruct.new
      allow(config).to receive(:_values).and_return(
        {
            reports: ['report.html', 'report-1.html', 'report-2.html'],
            collated_report: 'report.html'
          }
      )
      expect(collator).to receive(:create_config).and_return(config)
      expect(Fastlane::Actions::CollateHtmlReportsAction).to receive(:run) do |c|
        expect(c._values).to eq(
          {
            reports: ['report.html', 'report-1.html', 'report-2.html'],
            collated_report: 'report.html'
          }
        )
      end
      expect(collator).to receive(:delete_globbed_intermediatefiles).with('./report-[1-9]*.html')

      collator.collate_html_reports
    end
  end
end
