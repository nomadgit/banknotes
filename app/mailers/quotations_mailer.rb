class QuotationsMailer < ActionMailer::Base
  default :from => Rails.configuration.sender
  
  def send_quotation(quotation_id, to, subject, message, attach_pdf)
    @quotation = Quotation.find(quotation_id)
    @message = message
    attachments["quotation-#{@quotation.code}.pdf"] = File.read(@quotation.quotation_location) if attach_pdf
    
    mail(:to => to,
         :subject => subject)
  end
end
