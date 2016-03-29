require 'spec_helper'

describe CmeFixListener::RequestGenerator do
  let(:klass) { described_class }
  let(:instance) { klass.new(account) }
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

    context 'initial subscription' do
      let(:file_name) { 'trading_firm_initial_subscription.xml' }
      it { expect(instance.build_xml('1')).to eq message_spec_xml }
    end

    context 'continued subscription' do
      let(:file_name) { 'trading_firm_continued_subscription.xml' }
      it { expect(instance.build_xml('3')).to eq message_spec_xml }
    end
  end
end
