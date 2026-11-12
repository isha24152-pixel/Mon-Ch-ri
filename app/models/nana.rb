class Nana < ApplicationRecord
  belongs_to :user, optional: true
end