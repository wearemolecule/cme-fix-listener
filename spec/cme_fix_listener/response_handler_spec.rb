# frozen_string_literal: true

require "spec_helper"

describe CmeFixListener::ResponseHandler do
  let(:instance) { described_class.new(account) }
  let(:account) { { "id" => 123 } }
  let(:time_zone) { "Central Time (US & Canada)" }
  let(:token_manager_klass) { CmeFixListener::TokenManager }
  let(:parser_klass) { CmeFixListener::FixmlParser }
  let(:resque_klass) { CmeFixListener::ResqueManager }

  describe "#handle_cme_response" do
    let(:cme_response) { double(body: body, headers: headers) }
    let(:body) { "body" }
    let(:headers) { "headers" }

    subject { instance.handle_cme_response(cme_response) }

    it "should make the appropriate method calls" do
      expect(instance).to receive(:parse_headers).with(headers).and_return("123")
      expect(instance).to receive(:handle_headers).with("123", headers).and_return(nil)
      expect(instance).to receive(:parse_body).with(body).and_return("abc")
      expect(instance).to receive(:handle_body).with("abc").and_return(nil)
      subject
    end
  end

  describe "#parse_headers" do
    let(:headers) do
      {
        "x-cme-token" => "123abc",
        "date" => Time.new(2016, 2, 2).in_time_zone(time_zone)
      }
    end

    subject { instance.parse_headers(headers) }

    let(:parsed_headers) do
      {
        "token" => "123abc",
        "account_id" => 123,
        "created_at" => Time.new(2016, 2, 2).in_time_zone(time_zone)
      }
    end
    it { expect(subject).to eq parsed_headers }
  end

  describe "#handle_headers" do
    let(:parsed_headers) { { "token" => token } }

    subject { instance.handle_headers(parsed_headers, {}) }

    context "when there isn't a token" do
      let(:token) { nil }

      it "should not call TokenManager" do
        expect(token_manager_klass).not_to receive(:add_token_for_account).with(parsed_headers)
        subject
      end
    end

    context "when there is a token" do
      let(:token) { "123abc" }

      it "should call TokenManager" do
        expect(token_manager_klass).to receive(:add_token_for_account).with(parsed_headers)
        subject
      end
    end
  end

  describe "#parse_body" do
    subject { instance.parse_body("body") }
    before { allow_any_instance_of(parser_klass).to receive(:request_acknowledgement_text).and_return(error_text) }

    context "when the body has errors" do
      let(:error_text) { "errors" }

      it "should short circuit" do
        expect_any_instance_of(parser_klass).not_to receive(:parse_fixml).and_return("return")
        expect(subject).to eq nil
      end
    end

    context "when the body does NOT have errors" do
      let(:error_text) { nil }

      it "should short circuit" do
        expect_any_instance_of(parser_klass).to receive(:parse_fixml).and_return("return")
        expect(subject).to eq "return"
      end
    end
  end

  describe "#handle_error" do
    let(:parser) { instance_double(parser_klass, request_acknowledgement_text: error_text) }

    subject { instance.handle_error(parser, "body") }

    context "when the error is an invalid token" do
      let(:error_text) { "x-cme-token is no longer valid. Please initiate a new subscription" }

      it "clears the token from Redis" do
        expect(token_manager_klass).to receive(:clear_token_for_account).with(123)
        subject
      end

      it "does not notify Honeybadger" do
        allow(token_manager_klass).to receive(:clear_token_for_account)
        expect(Honeybadger).not_to receive(:notify)
        subject
      end

      it "does not set body_has_errors" do
        allow(token_manager_klass).to receive(:clear_token_for_account)
        subject
        expect(instance.experiencing_problems?).to eq false
      end

      it "returns nil" do
        allow(token_manager_klass).to receive(:clear_token_for_account)
        expect(subject).to be_nil
      end
    end

    context "when the error is a different CME error" do
      let(:error_text) { "not entitled to query" }

      it "notifies Honeybadger" do
        expect(Honeybadger).to receive(:notify)
        subject
      end

      it "sets body_has_errors" do
        allow(Honeybadger).to receive(:notify)
        subject
        expect(instance.experiencing_problems?).to eq true
      end

      it "does not clear the token" do
        allow(Honeybadger).to receive(:notify)
        expect(token_manager_klass).not_to receive(:clear_token_for_account)
        subject
      end

      it "returns nil" do
        allow(Honeybadger).to receive(:notify)
        expect(subject).to be_nil
      end
    end
  end

  describe "#handle_body" do
    subject { instance.handle_body(parsed_body) }

    context "when the parsed body is nil" do
      let(:parsed_body) { nil }

      it "should short circuit" do
        expect(resque_klass).not_to receive(:enqueue)
        expect(subject).to eq nil
      end
    end

    context "when the parsed body is valid" do
      let(:parsed_body) { "body" }

      it "should publish to resque" do
        expect(resque_klass).to receive(:enqueue).with(123, parsed_body.to_json)
        subject
      end
    end
  end
end
