require 'spec_helper'

describe JobsController do
  fixtures :jobs, :job_templates, :job_steps

  let(:get_job_response) { { 'id' => '1234', 'stepsCompleted' => '1', 'status' => 'running' } }

  let(:create_response) { { 'id' => '1234' } }

  let(:fake_dray_client) do
    double(:fake_dray_client,
           get_job: get_job_response,
           create_job: create_response,
           delete_job: nil
    )
  end

  before do
    allow(PanamaxAgent::Dray::Client).to receive(:new).and_return(fake_dray_client)
  end

  describe '#index' do
    it 'returns an array' do
      get :index, format: :json
      expect(JSON.parse(response.body)).to be_an Array
    end

    it 'includes a Total-Count header with the job count' do
      get :index, format: :json
      expect(response.headers['Total-Count']).to eq(1)
    end

  end

  describe '#show' do
    it 'returns a specific job' do
      get :show, id: Job.first.key, format: :json
      expect(response.body).to eq(JobSerializer.new(Job.first).to_json)
    end
  end

  describe '#create' do
    let(:new_job) { Job.new(job_template: job_templates(:cluster_job_template)) }

    before do
      allow(JobBuilder).to receive(:create).and_return(new_job)
    end

    it 'returns a job' do
      post :create, template_id: job_templates(:cluster_job_template).id, format: :json
      expect(response.body).to eq(JobSerializer.new(new_job).to_json)
    end

    it 'calls start_job on the job' do
      expect(new_job).to receive(:start_job)
      post :create, template_id: job_templates(:cluster_job_template).id, format: :json
    end

  end

  describe '#destroy' do
    let(:job) { Job.first }

    before do
      allow(Job).to receive(:find_by_key).with(Job.first.key).and_return(job)
    end

    it 'destroys the job model' do
      expect do
        delete :destroy, id: Job.first.key, format: :json
      end.to change(Job, :count).by(-1)
    end
  end

  describe '#log' do
    let(:log) { { 'lines' => [] } }

    before do
      allow_any_instance_of(Job).to receive(:log).with(3).and_return(log)
    end

    it 'returns the log data' do
      get :log, id: Job.first.key, index: 3, format: :json
      expect(response.body).to eq(log.to_json)
    end

  end

end
