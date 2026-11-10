require "test_helper"

ActiveRecord::Schema.define do
  create_table(:positions, force: true) { |t| t.string :name }
  create_table(:groups, force: true) { |t| t.string :name }
  create_table(:groups_positions, id: false, force: true) do |t|
    t.integer :group_id
    t.integer :position_id
  end
  create_table(:locations, force: true) { |t| t.string :name }
  create_table(:location_types, force: true) { |t| t.string :name }
  create_table(:location_type_locations, force: true) do |t|
    t.integer :location_id
    t.integer :location_type_id
  end
end

class Group < ActiveRecord::Base
end

class Position < ActiveRecord::Base
  has_and_belongs_to_many :groups
end

class LocationType < ActiveRecord::Base
end

class LocationTypeLocation < ActiveRecord::Base
  belongs_to :location
  belongs_to :location_type
end

class Location < ActiveRecord::Base
  has_many :location_type_locations, dependent: :delete_all
  has_many :location_types, through: :location_type_locations
end

class ThroughAssociationAuditTest < Minitest::Test
  def setup
    WulinAudit::AuditLog.delete_all
  end

  def test_habtm_remove_audits_join_row_delete
    position = Position.create!(name: "P")
    kept = Group.create!(name: "Kept")
    removed = Group.create!(name: "Removed")
    position.groups = [kept, removed]

    position.groups = [kept]

    deletes = WulinAudit::AuditLog.where(action: "delete")
    assert_equal ["HABTM_Groups"], deletes.pluck(:class_name)
    assert_equal "Removed", deletes.first.detail["Group"]
    assert_equal [kept], position.reload.groups
  end

  def test_has_many_through_remove_and_clear_audit_join_row_deletes
    location = Location.create!(name: "L")
    venue = LocationType.create!(name: "Venue")
    hotel = LocationType.create!(name: "Hotel")
    location.location_types = [venue, hotel]

    location.location_types = [hotel]
    location.location_types.clear

    deletes = WulinAudit::AuditLog.where(action: "delete", class_name: "LocationTypeLocation").order(:id)
    assert_equal ["Venue", "Hotel"], deletes.map { |log| log.detail["Location Type"] }
    assert_equal 0, LocationTypeLocation.count
  end

  def test_has_many_through_remove_skips_rejected_join_model
    LocationTypeLocation.reject_audit
    location = Location.create!(name: "L")
    location.location_types = [LocationType.create!(name: "Venue")]

    location.location_types = []

    assert_equal 0, WulinAudit::AuditLog.where(action: "delete").count
  ensure
    LocationTypeLocation.auditable = true
  end
end
