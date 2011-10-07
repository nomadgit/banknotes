include ActionView::Helpers::NumberHelper

def generate_quotation(quotation)
  # Generate quotation
  Prawn::Document.generate @quotation.quotation_location do |pdf|
    #FONT
    pdf.font_families.update("THSarabun" => {
      :normal => Rails.root.to_s + "/public/fonts/THSarabun.ttf",
      :italic => Rails.root.to_s + "/public/fonts/THSarabun Italic.ttf",
      :bold => Rails.root.to_s + "/public/fonts/THSarabun Bold.ttf",
      :bold_italic => Rails.root.to_s + "/public/fonts/THSarabun BoldItalic.ttf"
    })
    pdf.font "THSarabun"
    # LOGO
    pdf.image Rails.root.to_s + "/public/images/dgm_logo.png", :width => 150, :position => :right

    # ADDRESS 
    pdf.font_size(15){
      pdf.text "<color rgb='000000'>DGM59 Co., Ltd.</color>", :inline_format => true ,
                                                              :style => :bold, :align => :right
    }
    pdf.font_size(12) {
      pdf.text "<color rgb='000000'>6 Ramkhamhaeng 146</color>", :inline_format => true ,
                                                                 :align => :right
      pdf.text "<color rgb='000000'>Ramkhamhaeng Road, Sapansoong</color>", :inline_format => true ,
                                                                            :align => :right
      pdf.text "<color rgb='000000'>Sapansoong, Bangkok 10240</color>", :inline_format => true ,
                                                                        :align => :right
      pdf.text "<color rgb='000000'>TAX NO: 3033993042</color>", :inline_format => true ,
                                                                 :style => :bold,:align => :right
    }

    pdf.move_down -130

    # Title
    pdf.text "QUOTATION", :size => 40, :style => :bold

    #Quotation NO
    pdf.move_down -10
    pdf.text "#{quotation.code}", :size => 20
    
    #Date
    pdf.move_down -5
    if quotation.specific_date
      pdf.text "Date: #{quotation.specific_date.to_s.split(" ")[0]}", :size => 20
    else
      pdf.text "Date: #{Time.now.to_s.split(" ")[0]}", :size => 20
    end

    # Client info
    pdf.move_down 12
    pdf.font_size(12)
    pdf.text quotation.client.name,:style => :bold
    pdf.text quotation.client.address
    pdf.text quotation.client.phone
    if quotation.client.email
      pdf.text quotation.client.email
    end

    # Items
    pdf.move_down 10
    pdf.font_size(10)
    header = ["<color rgb='FFFFFF'>Item</color>",
              "<color rgb='FFFFFF'>Quantity</color>",
              "<color rgb='FFFFFF'>Amount</color>",
              "<color rgb='FFFFFF'>Total</color>"]
    items = quotation.quotation_items.collect do |item|
      [item.description, item.quantity.to_s, number_to_currency(item.amount), number_to_currency(item.total)]
    end

    hl = items.count + 1

    if quotation.discount.to_i == 0
      items = items + [["", "", "", ""]] \
                    + [["", "", "Sub-total:", "#{number_to_currency(quotation.subtotal)}"]] \
                    + [["", "", "Taxes:", "#{number_to_currency(quotation.taxes)} (#{number_with_delimiter(quotation.tax)}%)"]] \
                    + [["", "", "Total:", "#{number_to_currency(quotation.total)}"]]
    else
      discount = quotation.total*quotation.discount/100
      items = items + [["", "", "Discount:", "#{number_to_currency(discount)} (#{number_with_delimiter(quotation.discount)}%)"]] \
                    + [["", "", "Sub-total:", "#{number_to_currency(quotation.subtotal)}"]] \
                    + [["", "", "Taxes:", "#{number_to_currency(quotation.taxes)} (#{number_with_delimiter(quotation.tax)}%)"]] \
                    + [["", "", "Total:", "#{number_to_currency(quotation.total)}"]]
    end

    pdf.table [header] + items,:cell_style => { :inline_format => true }, :header => true, :width => pdf.bounds.width do
      cells.borders = []
      row(-4..-1).borders = []
      row(hl).style :borders => [:top], :border_width => 1,:border_color => "888888"
      row(-4..-1).column(2).align = :right
      row(0).style :font_style => :bold,:background_color => "888888"
      row(-1).style :font_style => :bold
    end


 

    # Terms
    if quotation.terms != ''
      pdf.move_down 20
      pdf.text 'Terms', :size => 18
      pdf.text quotation.terms
    end

    # Notes
    if quotation.notes != ''
      pdf.move_down 20
      pdf.text 'Notes', :size => 18
      pdf.text quotation.notes
    end

    #Receiver signature
    pdf.move_down 20
    pdf.text 'Receiver', :size => 18
    pdf.text "________________________________"
    pdf.text "Name___________________________"
    pdf.text "Date____________________________"
  end
end

ActiveAdmin.register Quotation do
  scope :all, :default => true
  scope :draft do |quotations|
    quotations.where(:status => Quotation::STATUS_DRAFT)
  end

  scope :sent do |quotations|
    quotations.where(:status => Quotation::STATUS_SENT)
  end
  
  scope :accepted do |quotations|
    quotations.where(:status => Quotation::STATUS_ACCEPTED)
  end
  
  index do
    column :status do |quotation|
      status_tag quotation.status, quotation.status_tag
    end
    column :code do |quotation|
      link_to "##{quotation.code}", admin_quotation_path(quotation)
    end
    
    column :client
    
    column :total do |quotation|
      number_to_currency quotation.total
    end
    
    column do |quotation|
      link_to("Details", admin_quotation_path(quotation)) + " | " + \
      link_to("Edit", edit_admin_quotation_path(quotation)) + " | " + \
      link_to("Delete", admin_quotation_path(quotation), :method => :delete, :confirm => "Are you sure?")
    end
  end
  
  # -----------------------------------------------------------------------------------
  # PDF
  
  action_item :only => :show do
    link_to "Generate PDF", generate_pdf_admin_quotation_path(resource)
  end
  
  member_action :generate_pdf do
    @quotation = Quotation.find(params[:id])
    generate_quotation(@quotation)
    
    # Send file to user
    send_file @quotation.quotation_location
  end
  
  # -----------------------------------------------------------------------------------
  
  # -----------------------------------------------------------------------------------
  # Email sending
  
  action_item :only => :show do
    link_to "Send", send_quotation_admin_quotation_path(resource)
  end
  
  member_action :send_quotation do
    @quotation = Quotation.find(params[:id])
  end
  
  member_action :dispatch_quotation, :method => :post do
    @quotation = Quotation.find(params[:id])
    
    # Generate the PDF quotation if neccesary
    generate_quotation(@quotation) if params[:attach_pdf]
    
    # Attach our own email if we want to send a copy to ourselves.
    params[:recipients] += ", #{current_admin_user.email}" if params[:send_copy]
    
    # Send all emails
    params[:recipients].split(',').each do |recipient|
      QuotationsMailer.send_quotation(@quotation.id, recipient.strip, params[:subject], params[:message], !!params[:attach_pdf]).deliver
    end
    
    # Change quotation status to sent
    @quotation.status = Quotation::STATUS_SENT
    @quotation.save
    
    redirect_to admin_quotation_path(@quotation), :notice => "Quotation sent succesfully"
  end
  
  # -----------------------------------------------------------------------------------
  
  show :title => :code do
    panel "Quotation Details" do
      attributes_table_for quotation do
        row("Code") { quotation.code }
        row("Status") { status_tag quotation.status, quotation.status_tag }
        if quotation.specific_date
          row("Specific Date") {quotation.specific_date}        
        end
        row("Issue Date") { quotation.created_at }
      end
    end
    
    panel "Items" do
      table_for quotation.quotation_items do |t|
        t.column("Qty.") { |quotation_item| number_with_delimiter quotation_item.quantity }
        t.column("Description") { |quotation_item| quotation_item.description }
        t.column("Per Unit") { |quotation_item| number_to_currency quotation_item.amount }
        t.column("Total") { |quotation_item| number_to_currency quotation_item.total}
        
        # Show the tax, discount, subtotal and total
        tr do
          2.times { td "" }
          td "Discount:", :style => "text-align:right; font-weight: bold;"
          td "#{number_with_delimiter(quotation.discount)}%"
        end
        
        tr do
          2.times { td "" }
          td "Sub-total:", :style => "text-align:right; font-weight: bold;"
          td "#{number_to_currency(quotation.subtotal)}%"
        end
        
        tr do
          2.times { td "" }
          td "Taxes:", :style => "text-align:right; font-weight: bold;"
          td "#{number_to_currency(quotation.taxes)} (#{number_with_delimiter(quotation.tax)}%)"
        end
        
        tr do
          2.times { td "" }
          td "Total:", :style => "text-align:right; font-weight: bold;"
          td "#{number_to_currency(quotation.total)}%", :style => "font-weight: bold;"
        end
      end
    end
    
    panel "Other" do
      attributes_table_for quotation do
        row("Terms") { simple_format quotation.terms }
        row("Notes") { simple_format quotation.notes }
      end
    end
  end
  
  sidebar "Bill To", :only => :show do
    attributes_table_for quotation.client do
      row("Name") { link_to quotation.client.name, admin_client_path(quotation.client) }
      row("Email") { mail_to quotation.client.email }
      row("Address") { quotation.client.address }
      row("Phone") { quotation.client.phone }
    end
  end
  
  sidebar "Total", :only => :show do
    h1 number_to_currency(quotation.total), :style => "text-align: center; margin-top: 20px"
  end
  
  form do |f|
    f.inputs "Client" do
      f.input :client
    end
    
    f.inputs "Items" do
      f.has_many :quotation_items do |i|
        i.input :_destroy, :as => :boolean, :label => "Delete this quotation_item" unless i.object.id.nil?
        i.input :quantity
        i.input :description
        i.input :amount
      end
    end
    
    f.inputs "Options" do
      f.input :code, :hint => "Latest Quotation's code: #{Quotation.last.code}"
      f.input :specific_date, :hint => "If blank Date in this quotation will be #{Time.now.to_s.split(" ")[0]}"
      f.input :status, :collection => Quotation.status_collection, :as => :radio
      f.input :tax, :input_html => { :style => "width: 30px"}, :hint => "This should be a percentage, from 0 to 100 (without the % sign)"
      f.input :discount, :input_html => { :style => "width: 30px"}, :hint => "This should be a percentage, from 0 to 100 (without the % sign)"
    end
    
    f.inputs "Other Fields" do
      f.input :terms, :input_html => { :rows => 4 }, :label => "Terms & Conditions"
      f.input :notes, :input_html => { :rows => 4 }
    end
    
    f.buttons
  end
end
