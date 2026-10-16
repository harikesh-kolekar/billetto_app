require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe FetchEventJob, type: :job do
  describe '#perform_later' do
    it 'enqueues the job' do
      expect {
        described_class.perform_later()
      }.to have_enqueued_job(described_class)
             .on_queue('default')
    end
  end
end
