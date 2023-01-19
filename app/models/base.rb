class Base < ApplicationRecord
  validates :base_number, presence: true, uniqueness: true
  validates :base_name, presence: true, length: { maximum: 50 }, uniqueness: true
  validates :attendance_type, presence: true
end
