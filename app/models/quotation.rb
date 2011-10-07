class Quotation < ActiveRecord::Base
  STATUS_DRAFT = 'draft'
  STATUS_SENT  = 'sent'
  STATUS_ACCEPTED  = 'accepted'
  
  belongs_to :client
  has_many :invoices
  has_many :quotation_items, :dependent => :destroy
  
  accepts_nested_attributes_for :quotation_items, :allow_destroy => true
  
  validates :code, :client_id, :presence => true
  validates :status, :inclusion => { :in => [STATUS_ACCEPTED, STATUS_SENT, STATUS_DRAFT], :message => "You need to pick one status." }
  validates :tax, :discount, :numericality => { :greater_than_or_equal_to => 0, :less_than_or_equal_to => 100 }
  
  class << self
    def suggest_code
      quotation = order('created_at desc').limit(1).first
      if quotation
        "INV-#{quotation.id + 1}"
      else
        "INV-1"
      end
    end

    def status_collection
      {
        "Draft" => STATUS_DRAFT,
        "Sent" => STATUS_SENT,
        "Paid" => STATUS_ACCEPTED
      }
    end
    
    def this_month
      where('created_at >= ?', Date.new(Time.now.year, Time.now.month, 1).to_datetime)
    end
  end
  
  def quotation_items_total
    quotation_items_total = 0
    self.quotation_items.each do |i|
      quotation_items_total += i.total
    end
    quotation_items_total
  end
  
  def total
    quotation_items_total * (1 - self.discount / 100) * (1 + self.tax / 100)
  end
  
  def subtotal
    quotation_items_total * (1 - self.discount / 100)
  end
  
  def to_s
    self.code
  end

  def taxes
    subtotal * (self.tax / 100)
  end
  
  def status_tag
    case self.status
      when STATUS_DRAFT then :error
      when STATUS_SENT then :warning
      when STATUS_ACCEPTED then :ok
    end
  end
  
  def quotation_location
    "#{Rails.root}/pdfs/quotation-#{self.code}.pdf"
  end
end
