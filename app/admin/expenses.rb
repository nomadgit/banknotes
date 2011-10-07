ActiveAdmin.register Expense do
  form do |f|
    f.inputs "Name" do
        f.input :admin_user
    end
  end
end
