module Import
  class Ptak
    def initialize
    end

    def import_product_feed(id = nil)
      errors = []
      external_ids = []
      copy_params = []
      copy_ids = []
      image_params = {}
      image_ids = []
      external_id = nil
      product = nil
      not_persisted = []
      no_cat = []
      no_color = []
      no_size = []      
      Nokogiri::XML(open 'http://ptakmodahurt.pl/xmlfiles/products.xml').css('//product').first(200).each do |n|
      # Nokogiri::XML(open Rails.root.join('products.xml')).css('//product').first(20).each do |n|
        begin
          external_id = n.css('ean13').text
          next if id && id != external_id
          if !n.previous_element || (external_id != n.previous_element.css('ean13').text)
            copy_params = []
            image_params = {}
            product = nil
            if cat = map_category(n.css('category_default_name').text)
              ## Spree::Sample.load_sample('products')
              default_shipping_category = Spree::ShippingCategory.find_by!(name: 'Default')
              clothing = Spree::TaxCategory.find_by!(name: 'Ubrania')
              Spree::Config[:currency] = 'PLN'

              name = n.css('name').text
              product = Spree::Product.where(name: name).first_or_create! do |p|
                p.price = n.css('price').text.to_f
                desc = n.css('description').text.strip_html_tags
                desc = name if desc.blank?
                p.description = desc
                p.available_on = Time.zone.now
                p.tax_category = clothing
                p.shipping_category = default_shipping_category
              end
              next unless product
              product.save


              ## Spree::Sample.load_sample('taxons')
              # kategoria
              # byebug
              taxon = Spree::Taxon.where(name: cat).first_or_create! do |t|
                t.parent = Spree::Taxon.where(name: 'Kategorie').first
                t.taxonomy = Spree::Taxonomy.find_by!(name: 'Kategorie')
              end
              product.taxons << taxon unless taxon.in? product.taxons
              # marka
              # brand_name = 
              # taxon = Spree::Taxon.where(name: brand_name).first_or_create!
              # taxon.parent = Spree::Taxon.where(name: 'Marki').first
              # taxon.taxonomy = Spree::Taxonomy.find_by!(name: 'Marki')
              # taxon.save
              # product.taxons << taxon
              
              # params = {
              #   delivery_time: 14,
              #   en_desc: desc,
              #   en_name: name,
              #   full_price: full_price,
              #   external_id: external_id,
              #   own_desc: desc,
              #   own_name: name,
              #   percent_discount: 0,
              #   product_category_id: cat,
              #   sex_id: 1,
              # }
              if product.persisted?
                external_ids << external_id
              else
                not_persisted << external_id
              end              
            end
          end
          next unless product.try(:persisted?)
          color = n.css('Attribute_Color').text
          if color
            ## Spree::Sample.load_sample('option_values')
            # kolor
            attrs = {
              name: color,
              presentation: color,
              option_type: Spree::OptionType.find_by!(presentation: 'Kolor')
            }
            Spree::OptionValue.where(attrs).first_or_create!

            # rozmiar
            size = n.css('Attribute_Size').text
            attrs = {
              name: size,
              presentation: size,
              option_type: Spree::OptionType.find_by!(presentation: 'Rozmiar')
            }
            Spree::OptionValue.where(attrs).first_or_create!


            ## Spree::Sample.load_sample('product_option_types')
            product.option_types = [
              Spree::OptionType.find_by!(presentation: 'Rozmiar'),
              Spree::OptionType.find_by!(presentation: 'Kolor')
            ]
            # product.save!


            ## Spree::Sample.load_sample('variants')
            variant_params = {
              product: product,
              option_values: [
                Spree::OptionValue.where(name: size).first,
                Spree::OptionValue.where(name: color).first
              ],
              sku: "#{n.css('reference').text}_#{size}_#{color}",
              cost_price: n.css('price').text.to_f
            }

            variant = Spree::Variant.where(product_id: variant_params[:product].id, sku: variant_params[:sku]).first
            variant = Spree::Variant.create!(variant_params) unless variant

            # product.master.update!({
            #   sku: 'SPR-00012',
            #   cost_price: 21
            # })


            ## Spree::Sample.load_sample('stock')
            variant.stock_items.each do |stock_item|
              Spree::StockMovement.create(quantity: n.css('quantity').text.to_i, stock_item: stock_item)
            end


            ## Spree::Sample.load_sample('assets')
            n.css('images').text.split(',').uniq.each do |image|
              uri = URI.parse(image)
              file = uri.open
              filename = File.basename(uri.path)
 
              if variant.images.with_attached_attachment.where(active_storage_blobs: { filename: filename }).none?
                variant.images.create!(attachment: { io: file, filename: filename })
              end
            end
          else
            no_color << n.css('Attribute_Color').text unless no_cat.include?(n.css('Attribute_Color').text)
          end
        rescue Exception => e
          errors << [external_id, e].join('-')
        end
      end
    end

    def map_category(name)
      {
        'bielizna' => 'Bielizna',
        'biustonosze' => 'Bielizna',
        'bluzki' => 'Bluzki i koszule',
        'bluzki-plus-size' => 'Bluzki i koszule',
        'bluzy' => 'Swetry',
        'bluzy-plus-size' => 'Swetry',
        'body' => 'Bielizna',
        'kamizelka' => 'Marynarki',
        'kamizelki' => 'Marynarki',
        'kamizelka-plus-size' => 'Marynarki',
        'kombinezony' => 'Kombinezony',
        'kurtki' => 'Kurtki',
        'kurtki-plus-size' => 'Kurtki',
        'majtki' => 'Bielizna',
        'plaszcze' => 'Płaszcze',
        'plaszcze-plus-size' => 'Płaszcze',
        'poncho' => 'Marynarki',
        'ponczochy' => 'Bielizna',
        'rajstopy' => 'Bielizna',
        'skarpetki' => 'Bielizna',
        'spodnie' => 'Spodnie',
        'spodnie-plus-size' => 'Spodnie',
        'spodnice' => 'Spodnice',      
        'sukienki' => 'Sukienki',
        'sukienki-plus-size' => 'Sukienki',
        'swetry' => 'Swetry',
        'swetry-plus-size' => 'Swetry',
        'torby' => 'Torby',
        'tuniki' => 'Sukienki',
        'tuniki-plus-size' => 'Sukienki',
        'zakiety' => 'Marynarki',
        'zakiety-plus-size' => 'Marynarki'
      }[name.parameterize]
    end
  end
end