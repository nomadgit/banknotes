class QuotationItem < ActiveRecord::Base
  belongs_to :quotation
  
  validates :quantity, :presence => true, :numericality => { :integer => true }
  validates :amount, :presence => true, :numericality => true
  validates :description, :presence => true
  
  def total
    self.quantity * self.amount
  end
end
