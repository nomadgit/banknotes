include ActionView::Helpers::NumberHelper

def generate_invoice(invoice)

  # Generate invoice
  Prawn::Document.generate @invoice.invoice_location do |pdf|

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
    pdf.text "INVOICE", :size => 40, :style => :bold

    #Invoice NO
    pdf.move_down -10
    pdf.text "#{invoice.code}", :size => 20

    #Due
    pdf.move_down -5
    if invoice.specific_date
      pdf.text "Date: #{invoice.specific_date.to_s.split(" ")[0]}    Due: #{invoice.due_date.to_s.split(" ")[0]}", :size => 20
    else
      pdf.text "Date: #{Time.now.to_s.split(" ")[0]}    Due: #{invoice.due_date.to_s.split(" ")[0]}", :size => 20
    end

    # Client info
    pdf.move_down 12
    pdf.font_size(12)
    pdf.text invoice.client.name ,:style => :bold
    pdf.text invoice.client.address
    pdf.text invoice.client.phone

    # Items
    pdf.move_down 10
    pdf.font_size(12)
    header = ["<font size='13'><color rgb='FFFFFF'>ITEM</color></font>",
              "<font size='13'><color rgb='FFFFFF'>QUANTITY</color></font>",
              "<font size='13'><color rgb='FFFFFF'>AMOUNT</color></font>",
              "<font size='13'><color rgb='FFFFFF'>TOTAL</color></font>"]
    items = invoice.items.collect do |item|
      [item.description, item.quantity.to_s, number_to_currency(item.amount), number_to_currency(item.total)]
    end

    hl = items.count + 1

    if invoice.discount.to_i == 0
      items = items + [["", "", "", ""]] \
                    + [["", "", "Sub-total:", "#{number_to_currency(invoice.subtotal)}"]] \
                    + [["", "", "Taxes:", "#{number_to_currency(invoice.taxes)} (#{number_with_delimiter(invoice.tax)}%)"]] \
                    + [["", "", "Total:", "#{number_to_currency(invoice.total)}"]]
    else
      discount = invoice.total*invoice.discount/100
      items = items + [["", "", "Discount:", "#{number_to_currency(discount)} (#{number_with_delimiter(invoice.discount)}%)"]] \
                    + [["", "", "Sub-total:", "#{number_to_currency(invoice.subtotal)}"]] \
                    + [["", "", "Taxes:", "#{number_to_currency(invoice.taxes)} (#{number_with_delimiter(invoice.tax)}%)"]] \
                    + [["", "", "Total:", "#{number_to_currency(invoice.total)}"]]
    end

    pdf.table [header] + items,:cell_style => { :inline_format => true }, :header => true, :width => pdf.bounds.width,:column_widths => {0 => 315, 1 => 75, 2 => 75, 3 => 75} do
      cells.borders = []
      row(-4..-1).borders = []
      row(hl).style :borders => [:top], :border_width => 1,:border_color => "888888"
      row(-4..-1).column(2).align = :right
      row(0).style :font_style => :bold,:background_color => "888888"
      row(-1).style :font_style => :bold
    end

    # Terms
    pdf.move_down -85
    if invoice.terms != ''
      pdf.move_down 20
      pdf.text 'PAYMENT TERMS', :size => 13, :style => :bold
      pdf.text invoice.terms
    end

    # Notes
    if invoice.notes != ''
      pdf.move_down 20
      pdf.text 'REMARKS', :size => 13, :style => :bold
      pdf.text invoice.notes
    end

    #Receiver signature
    pdf.move_down 20
    pdf.text 'RECEIVED BY', :size => 13, :style => :bold
    pdf.move_down 15
    pdf.text "________________________________________________"
    pdf.move_down 10
    pdf.text "Name___________________________________________"
    pdf.move_down 10
    pdf.text "Date____________________________________________"


    #Authorized by
    pdf.move_down -92
    pdf.text "AUTHORIZED BY                                             <color rgb='ffffff'>.<color>", :size => 13,:inline_format => true,:align => :right,:style => :bold
    pdf.move_down 15
    pdf.text "________________________________________________",:align => :right
    pdf.move_down 10
    pdf.text "Name___________________________________________",:align => :right
    pdf.move_down 10
    pdf.text "Date____________________________________________",:align => :right
    # Footer
    if invoice.quotation
      pdf.draw_text "Reference ##{invoice.quotation.code}", :at => [0, 0], :style => :bold
    end
  end
end
#######################################################################################################################
ActiveAdmin.register Invoice do
  scope :all, :default => true
  scope :draft do |invoices|
    invoices.where(:status => Invoice::STATUS_DRAFT)
  end

  scope :sent do |invoices|
    invoices.where(:status => Invoice::STATUS_SENT)
  end
  
  scope :paid do |invoices|
    invoices.where(:status => Invoice::STATUS_PAID)
  end
  
  index do
    column :status do |invoice|
      status_tag invoice.status, invoice.status_tag
    end
    column :code do |invoice|
      link_to "##{invoice.code}", admin_invoice_path(invoice)
    end
    
    column :client
    column :quotation do |invoice|
      if invoice.quotation
        link_to "##{invoice.quotation.code}", admin_quotation_path(invoice)
      end
    end
    
    column "Issued" do |invoice|
      time = distance_of_time_in_words Time.now, invoice.due_date
      if invoice.due_date <= Time.now 
        #" (due in #{distance_of_time_in_words Time.now, invoice.due_date})"
        status_tag "Late for #{time}(#{invoice.due_date.to_s.gsub("-","/").split(" ")[0]})", "error"
      elsif invoice.due_date > Time.now
        #" (Due in #{distance_of_time_in_words Time.now, invoice.due_date})"
        status_tag "Due in #{time}(#{invoice.due_date.to_s.gsub("-","/").split(" ")[0]})","ok"
      else
        ""
      end
      
      #"#{l invoice.created_at, :format => :short}" + due
    end
    column :total do |invoice|
      number_to_currency invoice.total
    end
    
    column do |invoice|
      link_to("Details", admin_invoice_path(invoice)) + " | " + \
      link_to("Edit", edit_admin_invoice_path(invoice)) + " | " + \
      link_to("Delete", admin_invoice_path(invoice), :method => :delete, :confirm => "Are you sure?")
    end
  end
  
  # -----------------------------------------------------------------------------------
  # PDF
  
  action_item :only => :show do
    link_to "Generate PDF", generate_pdf_admin_invoice_path(resource)
  end
  
  member_action :generate_pdf do
    @invoice = Invoice.find(params[:id])
    generate_invoice(@invoice)
    
    # Send file to user
    send_file @invoice.invoice_location
  end
  
  # -----------------------------------------------------------------------------------
  
  # -----------------------------------------------------------------------------------
  # Email sending
  
  action_item :only => :show do
    link_to "Send", send_invoice_admin_invoice_path(resource)
  end
  
  member_action :send_invoice do
    @invoice = Invoice.find(params[:id])
  end
  
  member_action :dispatch_invoice, :method => :post do
    @invoice = Invoice.find(params[:id])
    
    # Generate the PDF invoice if neccesary
    generate_invoice(@invoice) if params[:attach_pdf]
    
    # Attach our own email if we want to send a copy to ourselves.
    params[:recipients] += ", #{current_admin_user.email}" if params[:send_copy]
    
    # Send all emails
    params[:recipients].split(',').each do |recipient|
      InvoicesMailer.send_invoice(@invoice.id, recipient.strip, params[:subject], params[:message], !!params[:attach_pdf]).deliver
    end
    
    # Change invoice status to sent
    @invoice.status = Invoice::STATUS_SENT
    @invoice.save
    
    redirect_to admin_invoice_path(@invoice), :notice => "Invoice sent succesfully"
  end
  
  # -----------------------------------------------------------------------------------
  
  show :title => :code do
    panel "Invoice Details" do
      attributes_table_for invoice do
        row("Code") { invoice.code }
        if invoice.quotation
          row("Reference") { invoice.quotation.code }
        end
        row("Status") { status_tag invoice.status, invoice.status_tag }
        if invoice.specific_date
          row("Specific date") {invoice.specific_date}        
        end
        row("Issue Date") { invoice.created_at }
        row("Due Date") { invoice.due_date }
      end
    end
    
    panel "Items" do
      table_for invoice.items do |t|
        t.column("Qty.") { |item| number_with_delimiter item.quantity }
        t.column("Description") { |item| item.description }
        t.column("Per Unit") { |item| number_to_currency item.amount }
        t.column("Total") { |item| number_to_currency item.total}
        
        # Show the tax, discount, subtotal and total
        tr do
          2.times { td "" }
          td "Discount:", :style => "text-align:right; font-weight: bold;"
          td "#{number_with_delimiter(invoice.discount)}%"
        end
        
        tr do
          2.times { td "" }
          td "Sub-total:", :style => "text-align:right; font-weight: bold;"
          td "#{number_to_currency(invoice.subtotal)}%"
        end
        
        tr do
          2.times { td "" }
          td "Taxes:", :style => "text-align:right; font-weight: bold;"
          td "#{number_to_currency(invoice.taxes)} (#{number_with_delimiter(invoice.tax)}%)"
        end
        
        tr do
          2.times { td "" }
          td "Total:", :style => "text-align:right; font-weight: bold;"
          td "#{number_to_currency(invoice.total)}%", :style => "font-weight: bold;"
        end
      end
    end
    
    panel "Other" do
      attributes_table_for invoice do
        row("Terms") { simple_format invoice.terms }
        row("Notes") { simple_format invoice.notes }
      end
    end
  end
  
  sidebar "Bill To", :only => :show do
    attributes_table_for invoice.client do
      row("Name") { link_to invoice.client.name, admin_client_path(invoice.client) }
      row("Email") { mail_to invoice.client.email }
      row("Address") { invoice.client.address }
      row("Phone") { invoice.client.phone }
    end
  end
  
  sidebar "Total", :only => :show do
    h1 number_to_currency(invoice.total), :style => "text-align: center; margin-top: 20px"
  end
  
  form do |f|
    f.inputs "Client" do
      f.input :client
    end

    f.inputs "Quotation" do
      f.input :quotation
    end
    
    f.inputs "Items" do
      f.has_many :items do |i|
        i.input :_destroy, :as => :boolean, :label => "Delete this item" unless i.object.id.nil?
        i.input :quantity
        i.input :description
        i.input :amount
      end
    end
    
    f.inputs "Options" do
      if Invoice.last then code = Invoice.last.code end
      f.input :code, :hint => "Latest invoice's code: #{code} "
      f.input :status, :collection => Invoice.status_collection, :as => :radio
      f.input :specific_date, :hint => "If blank Date in this invoice will be #{Time.now.to_s.split(" ")[0]}"
      f.input :due_date
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
