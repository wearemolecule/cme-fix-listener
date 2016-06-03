require 'spec_helper'

describe CmeFixListener::HistoryRequestGenerator do
  let(:klass) { described_class }
  let(:instance) { klass.new(account, '2016-01-01', '2016-01-02') }
  let(:content_type) { 'text/xml' }

  let(:account) do
    {
      'cmeRequestId' => 'COMPANY_NAME',
      'cmeUsername' => 'USERNAME_SPEC',
      'cmeFirmSid' => 'COMPANY_SPEC',
      'cmePartyRole' => '7'
    }
  end

  let(:file) { File.open(file_path) }
  let(:file_path) { File.join("spec/datafiles/#{file_name}") }

  describe '#build_xml' do
    let(:message_spec) { file.read }
    let(:message_spec_xml) { (Nokogiri::XML message_spec).to_xml }
    let(:file_name) { 'history_request.xml' }

    it { expect(instance.build_xml('1')).to eq message_spec_xml }

    context "when start time is blank" do
      let(:instance) { klass.new(account, '', 'test') }
      it { expect(instance.build_xml('1')).to eq nil }
    end

    context "when end time is blank" do
      let(:instance) { klass.new(account, 'test', nil) }
      it { expect(instance.build_xml('1')).to eq nil }
    end
  end
end
