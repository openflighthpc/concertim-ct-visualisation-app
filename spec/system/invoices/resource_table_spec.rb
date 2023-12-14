require 'rails_helper'

RSpec.describe "invoices index page table", type: :system do
  let(:user_password) { 'user-password' }
  let!(:user) { create(:user, :with_openstack_details, password: user_password) }
  let(:items_per_page) { 20 }

  before(:each) do
    visit new_user_session_path
    expect(current_path).to eq(new_user_session_path)
    fill_in "Username", with: user.login
    fill_in "Password", with: user_password
    click_on "Login"
  end

  before(:each) do
    create(:cloud_service_config)
  end

  before(:each) { allow(GetInvoicesJob).to receive(:perform_now).and_return(result) }
  let(:result) { GetInvoicesJob::Result.new(true, invoice_request_response_body, user, nil, 200) }
  let(:invoice_request_response_body) {
    {
      "total_invoices" => total_invoices,
      "invoices" => invoices.map(&:attributes),
    }
  }

  # The API does the pagination for us, we emulate that here.
  let(:invoices) { build_list(:invoice, [total_invoices, items_per_page].min) }

  describe "pagination" do
    context "when there are 20 or fewer invoices" do

      let(:total_invoices) { 10 }

      it "lists all invoices" do
        visit invoices_path
        expect(current_path).to eq(invoices_path)

        table = find('.resource_table')
        invoices.each do |invoice|
          expect(table).to have_content(invoice.invoice_id)
          expect(table).to have_content(invoice.invoice_number)
        end
      end
    end

    context "when there are more than 20 invoices" do
      let(:total_invoices) { 30 }

      it "lists the first 20 invoices" do
        visit invoices_path
        expect(current_path).to eq(invoices_path)

        table = find('.resource_table')
        invoices.each do |invoice|
          expect(table).to have_content(invoice.invoice_id)
          expect(table).to have_content(invoice.invoice_number)
        end
      end

      it "displays enabled pagination controls" do
        visit invoices_path
        expect(current_path).to eq(invoices_path)

        controls = find('.pagination_controls')
        expect(controls).to have_content "Displaying items 1-20 of 30"
        # Expect prev navigation to be disabled.
        expect(controls).to have_css('.page.prev.disabled')
        # Expect next navigation to not be disabled.
        expect(controls).not_to have_css('.page.next.disabled')
        expect(controls).to have_css('.page.next')
        expect(controls).to have_css('a[rel="next"]')
      end
    end
  end

  describe "invoice table rows" do
    let(:total_invoices) { 10 }
    it "displays correct amount for invoice" do
      visit invoices_path
      expect(current_path).to eq(invoices_path)

      table = find('.resource_table')
      invoices.each do |invoice|
        tr = table.find("tr[data-test='invoice-#{invoice.invoice_id}']")
        expect(tr).to have_content(invoice.invoice_number)
        expect(tr).to have_content(invoice.amount)
      end
    end

    it "displays a link to view the invoice" do
      visit invoices_path
      expect(current_path).to eq(invoices_path)

      table = find('.resource_table')
      invoices.each do |invoice|
        tr = table.find("tr[data-test='invoice-#{invoice.invoice_id}']")
        expect(tr).to have_link("View invoice", href: invoice_path(invoice))
      end
    end
  end
end
