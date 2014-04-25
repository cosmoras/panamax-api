class Service < ActiveRecord::Base
  include DockerRunnable
  include ServiceJournal

  belongs_to :app
  has_many :service_categories
  has_many :categories, through: :service_categories, source: :app_category
  has_many :links, class_name: 'ServiceLink', foreign_key: 'linked_from_service_id'

  serialize :ports, Array
  serialize :expose, Array
  serialize :environment, Hash
  serialize :volumes, Array

  before_save   :resolve_name_conflicts
  after_destroy :delete_service_unit

  validates_presence_of   :name

  def unit_name
    "#{name}.service"
  end

  def load_state
    service_state['loadState']
  end

  def active_state
    service_state['activeState']
  end

  def sub_state
    service_state['subState']
  end

  def copy_categories_from_image(image, app_categories)
    image.categories.each do |image_cat|
      self.categories << app_categories.find { |app_cat| app_cat.name == image_cat.name }
    end
  end

  def self.new_from_image(image)
    self.new(
      name: image.name,
      description: image.description,
      from: "#{image.repository}:#{image.tag}",
      links: image.links,
      ports: image.ports,
      expose: image.expose,
      environment: image.environment,
      volumes: image.volumes
    )
  end

  def self.new_from_params(image_create_params)
    self.new(name: "#{image_create_params[:image]}",
             from: "#{image_create_params[:image]}:#{image_create_params[:tag]}",
             ports: image_create_params[:ports],
             expose: image_create_params[:expose],
             environment: image_create_params[:environment],
             volumes: image_create_params[:volumes]
    )
  end

  protected

  def fleet_client
    PanamaxAgent.fleet_client
  end

  private

  def delete_service_unit
    fleet_client.destroy(self.unit_name)
  end

  def resolve_name_conflicts
    unless persisted?
      sanitized_name = name.gsub('/', '_')
      count = Service.where('name LIKE ?', "#{sanitized_name}%").count
      self.name = (count > 0) ? "#{sanitized_name}_#{count}" : sanitized_name
    end
  end

  def service_state
    if not @service_state
      fleet_state = fleet_client.get_state(unit_name)
      @service_state = JSON.parse(fleet_state['node']['value'])
    end
    @service_state
  rescue Exception
    {}
  end

end
