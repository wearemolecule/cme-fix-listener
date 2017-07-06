# frozen_string_literal: true

require "spec_helper"

describe CmeFixListener::TradeCaptureReportRequester do
  let(:klass) { described_class }
  let(:instance) { klass.new(account) }
  let(:account) do
    {
      "id" => 123,
      "name" => "Account1",
      "cmeUsername" => "USERNAME_SPEC",
      "cmePassword" => "PASSWORD_SPEC",
      "cmeEnvironment" => "production"
    }
  end

  describe "#new_client_request" do
    let(:header) { { "Content-Type" => "text/plain" } }
    let(:body) { "body" }
    let(:base_auth) do
      {
        basic_auth: {
          username: "USERNAME_SPEC",
          password: "PASSWORD_SPEC"
        }
      }
    end
    let(:response_body) { base_auth.merge(body: body, headers: header) }

    subject(:response) { instance.new_client_request(nil) }
    before { allow(instance).to receive(:request_body).with("1").and_return(body) }

    context "when making a request" do
      it "should send the correct type and header" do
        expect_any_instance_of(klass).to receive(:post_client_request).with("1", header)
        subject
      end
    end

    context "when http request succeeds" do
      it "should return the response" do
        successful_httparty_response
        subject
      end
    end

    context "when http request fails" do
      it "should retry once" do
        failed_httparty_response
        subject
      end
    end
  end

  describe "#existing_client_request" do
    let(:token) { "123" }
    let(:body) { "body" }
    let(:header) { { "Content-Type" => "text/plain", "x-cme-token" => token } }
    let(:base_auth) do
      {
        basic_auth: {
          username: "USERNAME_SPEC",
          password: "PASSWORD_SPEC"
        }
      }
    end
    let(:response_body) { base_auth.merge(body: body, headers: header) }

    subject(:response) { instance.existing_client_request(token) }
    before { allow(instance).to receive(:request_body).with("3").and_return(body) }

    context "when making a request" do
      it "should send the correct type and header" do
        expect_any_instance_of(klass).to receive(:post_client_request).with("3", header)
        subject
      end
    end

    context "when http request succeeds" do
      it "should return the response" do
        successful_httparty_response
        subject
      end
    end

    context "when http request fails" do
      it "should retry once" do
        failed_httparty_response
        subject
      end
    end
  end

  def failed_httparty_response
    configurable_sleep_stub
    allow(HTTParty).to receive(:post).with("https://services.cmegroup.com/cmestp/query", response_body).
      and_raise(Net::ReadTimeout)
    expect(response).to eq nil
    expect(HTTParty).to have_received(:post).twice
  end

  def successful_httparty_response
    allow(HTTParty).to receive(:post).with("https://services.cmegroup.com/cmestp/query", response_body).
      and_return(:success)
    expect(response).to eq :success
    expect(HTTParty).to have_received(:post).once
  end

  def configurable_sleep_stub
    allow(instance).to receive(:configurable_sleep).and_return(nil)
  end
end
