require 'spec_helper'

describe 'panamax:templates:load' do
  include_context 'rake'

  before do
    Template.stub(:load_templates_from_template_repos)
  end

  its(:prerequisites) { should include('environment') }

  it 'loads templates' do
    expect(Template).to receive(:load_templates_from_template_repos)
    subject.invoke
  end
end