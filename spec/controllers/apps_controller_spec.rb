require 'spec_helper'

describe AppsController do

  describe '#index' do

    it 'returns an array' do
      get :index, format: :json
      expect(JSON.parse(response.body)).to be_an Array
    end

  end

  describe '#show' do
    it "returns a specific app" do
      get :show, { id: App.first.id, format: :json }
      expect(response.body).to eq (AppSerializer.new(App.first)).to_json
    end

    it 'returns app representations with an array of services in the services attribute' do
      get :show, { id: App.first.id, format: :json }
      expect(JSON.parse(response.body)).to have_key('services')
      expect(JSON.parse(response.body)['services']).to be_an Array
    end

  end

  describe '#create' do

    context 'when the request contains a template id' do
      let(:app){ App.new }
      let(:params){ { template_id: 1 } }
      let(:template){ double(:template, name: 'my_template') }

      before do
        App.stub(:create_from_template).and_return(app)
        AppExecutor.stub(:run)
        Template.stub(:find).with(params[:template_id]).and_return(template)
      end

      it 'fetches the template for the given template id' do
        expect(Template).to receive(:find).with(params[:template_id]).and_return(template)
        post :create, { template_id: 1, format: :json }
      end

      it 'creates the application from the template' do
        expect(App).to receive(:create_from_template).with(template)
        post :create, { template_id: 1, format: :json }
      end

    end

    context 'when the request contains an image repository' do

      let(:params) do
        {
            image: 'foo/bar:baz',
            links: 'SERVICE2',
            ports: '3306:3306',
            expose: '3306',
            environment: 'MYSQL_ROOT_PASSWORD=pass@word01',
            volumes: '/var/panamax:/var/app/panamax',
            tag: 'latest'
        }
      end

      let(:app){ App.new }

      before do
        App.stub(:create_from_image).and_return(app)
        AppExecutor.stub(:run)
      end

      it 'creates the application from the image' do
        expect(App).to receive(:create_from_image).with(params).and_return(app)
        post :create, params.merge(format: :json)
      end

    end


    context 'when attempting to run the application raises an exception' do
      let(:app){ apps(:app1) } # load from fixture to get services assoc
      let(:params){ { template_id: 1 } }
      let(:template){ double(:template, name: 'my_template') }

      before do
        App.stub(:create_from_template).and_return(app)
        AppExecutor.stub(:run).and_raise('boom')
        Template.stub(:find)
      end

      it 'destroys the app' do
        post :create, params.merge(format: :json)
        expect(App.where(id: app.id).first).to be_nil
      end

      it 'destroys the app services' do
        post :create, params.merge(format: :json)
        expect(Service.where(app_id: app.id)).to be_empty
      end

      it 'returns 500 error' do
        post :create, params.merge(format: :json)
        expect(response.status).to eq(400) # :bad_request
      end

      it 'renders the error in the json body' do
        post :create, params.merge(format: :json)
        expect(JSON.parse(response.body)).to have_key('error')
      end

    end

  end

end