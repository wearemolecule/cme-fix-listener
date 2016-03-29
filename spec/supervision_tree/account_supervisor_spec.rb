require 'spec_helper'

describe SupervisionTree::AccountSupervisor do
  let(:klass) { described_class }

  subject { klass.new(123) }

  before do
    allow_any_instance_of(SupervisionTree::AccountFetchActor).to receive(:speak!).and_return(nil)
    allow_any_instance_of(SupervisionTree::CmeFixListenerActor).to receive(:start_requests!).and_return(nil)
  end

  it 'should create two actors on init' do
    expect(subject.container.actors.count).to eq 2
    actor = subject.container.actors.detect { |c| c.name == :cme_fix_listener_actor_123 }
    expect(actor.class).to eq SupervisionTree::CmeFixListenerActor
    actor = subject.container.actors.detect { |c| c.name == :account_fetch_actor_123 }
    expect(actor.class).to eq SupervisionTree::AccountFetchActor
  end
end
