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
    let(:headers) { { "x-cme-token" => "tok-1", "date" => "Mon, 01 Jan 2024" } }
    let(:parsed_body) { [{ "trade" => 1 }] }

    subject { instance.handle_cme_response(cme_response) }

    before do
      allow_any_instance_of(parser_klass).to receive(:request_acknowledgement_text).and_return(nil)
      allow_any_instance_of(parser_klass).to receive(:parse_fixml).and_return(parsed_body)
    end

    it "persists the token and trade batch together after parsing" do
      expect(resque_klass).to receive(:persist_token_and_enqueue).with(123, "tok-1", parsed_body.to_json)
      expect(token_manager_klass).not_to receive(:add_token_for_account)
      expect(resque_klass).not_to receive(:enqueue)
      subject
    end

    context "when a crash occurs after the CME response is received but before Redis commit" do
      before do
        allow(resque_klass).to receive(:persist_token_and_enqueue).and_raise(Redis::CannotConnectError)
      end

      it "does not leave the poll cursor advanced without the batch queued" do
        expect(token_manager_klass).not_to receive(:add_token_for_account)
        expect(resque_klass).not_to receive(:enqueue)
        expect { subject }.to raise_error(Redis::CannotConnectError)
      end
    end

    context "when the response has an invalid token error" do
      before do
        allow_any_instance_of(parser_klass).to receive(:request_acknowledgement_text)
          .and_return("x-cme-token is no longer valid. Please initiate a new subscription")
        allow(token_manager_klass).to receive(:clear_token_for_account)
      end

      it "clears the token and does not re-advance the cursor" do
        expect(token_manager_klass).to receive(:clear_token_for_account).with(123)
        expect(resque_klass).not_to receive(:persist_token_and_enqueue)
        expect(resque_klass).not_to receive(:enqueue)
        subject
      end
    end

    context "when the token is missing" do
      let(:headers) { { "date" => "Mon, 01 Jan 2024" } }

      before { allow(Honeybadger).to receive(:notify) }

      it "notifies and still enqueues the body without advancing a token" do
        expect(resque_klass).to receive(:enqueue).with(123, parsed_body.to_json)
        expect(resque_klass).not_to receive(:persist_token_and_enqueue)
        subject
      end
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

  describe "#commit_parsed_response" do
    let(:raw_headers) { { "x-cme-token" => "tok-1" } }
    let(:parsed_headers) { { "token" => "tok-1", "account_id" => 123 } }

    subject { instance.commit_parsed_response(parsed_headers, parsed_body, raw_headers) }

    context "when the parsed body is blank" do
      let(:parsed_body) { nil }

      it "advances the token without enqueueing" do
        expect(resque_klass).to receive(:persist_token_and_enqueue).with(123, "tok-1", nil)
        subject
      end
    end

    context "when the parsed body is present" do
      let(:parsed_body) { [{ "qty" => 47 }] }

      it "advances the token and enqueues the batch together" do
        expect(resque_klass).to receive(:persist_token_and_enqueue).with(123, "tok-1", parsed_body.to_json)
        subject
      end
    end
  end
end
