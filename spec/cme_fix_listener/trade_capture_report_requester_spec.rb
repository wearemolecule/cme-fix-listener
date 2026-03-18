# frozen_string_literal: true

require "spec_helper"

describe CmeFixListener::TradeCaptureReportRequester do
  let(:instance) { described_class.new(account) }
  let(:account) do
    {
      "id" => 123,
      "name" => "Account1",
      "cmeUsername" => "USERNAME_SPEC",
      "cmePassword" => "PASSWORD_SPEC",
      "cmeEnvironment" => "production"
    }
  end
  let(:body) { "body" }
  let(:plain_text_header) { described_class::PLAIN_TEXT_HEADER }
  let(:base_auth) do
    {
      basic_auth: {
        username: "USERNAME_SPEC",
        password: "PASSWORD_SPEC"
      }
    }
  end

  shared_examples "successful http request" do
    context "when http request succeeds" do
      before do
        allow(described_class).to receive(:post)
          .with("https://posttrade.api.cmegroup.com/cmestp/query", response_body)
          .and_return(:success)
      end

      it "returns the response" do
        expect(subject).to eq :success
        expect(described_class).to have_received(:post).once
      end
    end
  end

  shared_examples "failed http request" do
    context "when http request fails" do
      before do
        allow(instance).to receive(:configurable_sleep).and_return(nil)
        allow(described_class).to receive(:post)
          .with("https://posttrade.api.cmegroup.com/cmestp/query", response_body)
          .and_raise(Net::ReadTimeout)
      end

      it "retries once" do
        expect(subject).to eq nil
        expect(described_class).to have_received(:post).twice
      end
    end
  end

  describe "DEFAULT_CME_HOST" do
    it "is the posttrade API host" do
      expect(described_class::DEFAULT_CME_HOST).to eq "https://posttrade.api.cmegroup.com"
    end
  end

  describe "#new_client_request" do
    subject { instance.new_client_request(nil) }

    let(:response_body) { base_auth.merge(body: body, headers: plain_text_header) }

    before { allow(instance).to receive(:request_body).with("1").and_return(body) }

    context "when making a request" do
      before { allow(instance).to receive(:post_client_request).with("1", plain_text_header) }

      it "sends the correct type and header" do
        subject
        expect(instance).to have_received(:post_client_request).with("1", plain_text_header)
      end
    end

    include_examples "successful http request"
    include_examples "failed http request"
  end

  describe "#existing_client_request" do
    subject { instance.existing_client_request(token) }

    let(:token) { "123" }
    let(:token_header) { plain_text_header.merge("x-cme-token" => token) }
    let(:response_body) { base_auth.merge(body: body, headers: token_header) }

    before { allow(instance).to receive(:request_body).with("3").and_return(body) }

    context "when making a request" do
      before { allow(instance).to receive(:post_client_request).with("3", token_header) }

      it "sends the correct type and header" do
        subject
        expect(instance).to have_received(:post_client_request).with("3", token_header)
      end
    end

    include_examples "successful http request"
    include_examples "failed http request"
  end
end
