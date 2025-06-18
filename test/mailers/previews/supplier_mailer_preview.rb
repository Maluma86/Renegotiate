# test/mailers/previews/supplier_mailer_preview.rb
class SupplierMailerPreview < ActionMailer::Preview
  # Preview at http://localhost:3000/rails/mailers/supplier_mailer/invite_to_renegotiation
  def invite_to_renegotiation
    # find an existing renegotiation, or build one on the fly:
    ren = Renegotiation.includes(product: :supplier).first ||
          Renegotiation.create!(
            product: Product.create!(
              name:            "Acme Widget",
              current_price:   123.45,
              supplier:        User.create!(
                                 company_name:  "Acme Co",
                                 contact_email: "supplier@example.com",
                                 role:          "supplier"
                               ),
              procurement_id:  1
            ),
            buyer_id:     1,
            supplier_id:  User.last.id,
            min_target:   90,
            max_target:  100,
            status:      "pending"
          )

    SupplierMailer.invite_to_renegotiation(ren.id)
  end
end
