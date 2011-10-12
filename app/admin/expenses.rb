ActiveAdmin.register Expense do
  scope :all, :default => true
  scope "Travel" do |expenses|
    expenses.where(:expense_type => "travel")
  end

  scope "Goods and Services" do |expenses|
    expenses.where(:expense_type => "goods_and_services")
  end

  index do
    column "Paid By" ,:admin_user
    column "Type" ,:expense_type
    column :detail
    column :cost
    column do |expense|
          link_to("Details", admin_expense_path(expense)) + " | " + \
          link_to("Edit", edit_admin_expense_path(expense)) + " | " + \
          link_to("Delete", admin_expense_path(expense), :method => :delete, :confirm => "Are you sure?")
    end
  end

  sidebar "Total Expense in past 30 days" , :only => :index do
    ul do
      li "Travel: "+expenses.where(:expense_type => "travel").where("created_at > ?", Time.now-30.day).sum(:cost).to_s
      li "Goods and Services: "+expenses.where(:expense_type => "goods_and_services").where("created_at > ?", Time.now-30.day).sum(:cost).to_s
    end
  end

  form do |f|
    f.inputs "Expense Form" do
      f.input :admin_user
      f.input :expense_type, :collection => {"Travel" => "travel","Goods&Services" => "goods_and_services"}, :as => :radio
      f.input :detail
      f.input :cost
    end
  f.buttons
  end
end
