class Expense < ActiveRecord::Base
  belongs_to :admin_user
  validates :detail, :admin_user_id,:cost,:expense_type, :presence => true
end
