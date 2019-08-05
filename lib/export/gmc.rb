module Export
  class Gmc
    include Rails.application.routes.url_helpers

    def product_feed
      errors = []
      builder = Nokogiri::XML::Builder.new(encoding: 'utf-8') do |xml|
        xml.rss(version: '1.0', :'xmlns:g' => 'http://base.google.com/ns/1.0') {
          xml.channel {
            Spree::Product.order(:id).find_each do |p|
              begin
                v = p.variants.first
                if v
                  link = "https://www.molimoli.pl#{Spree::Core::Engine.routes.url_helpers.product_path p}"
                  image = url_for(v.images.first.url(:product))
                  category = p.taxons.find_by(parent: Spree::Taxon.find_by(name: 'Kategorie'))
                  color = v.option_values.find_by(option_type: Spree::OptionType.find_by(presentation: 'Kolor')).presentation
                  size = v.option_values.find_by(option_type: Spree::OptionType.find_by(presentation: 'Rozmiar')).presentation
                  google_category = map_category(category.id)

                  xml.item {
                    xml['g'].id v.sku
                    xml['g'].item_group_id p.sku
                    xml['g'].title p.name
                    xml['g'].description p.description
                    xml['g'].link link
                    xml['g'].condition 'new'
                    xml['g'].price "#{p.price_in('PLN').amount.to_d} PLN"
                    xml['g'].availability 'in stock'
                    xml['g'].image_link image
                    xml['g'].color color
                    xml['g'].size size
                    xml['g'].size_type 'Regular'
                    xml['g'].size_system 'EU'
                    xml['g'].age_group 'adult'
                    xml['g'].gender 'female'
                    xml['g'].brand 'MoliMoli'
                    xml['g'].google_product_category google_category
                    xml['g'].product_type category.name
                  }
                end
              rescue Exception => e
                errors << [p.id, e].join('-')
              end
            end
          }
        }
      end
      puts "Total errors: #{errors.count}"
      puts "Errors:"
      errors.map{ |error| puts error }

      # io = StringIO.new
      # io.write builder.to_xml
      # io.rewind

      # blob = ActiveStorage::Blob.create_after_upload!(
      #   io: io,
      #   filename: 'gmc.xml',
      #   content_type: 'text/xml'
      # )
      # url_for(blob)

      file = Tempfile.new('gmc.xml')
      file.write builder.to_xml
      file.rewind
      file.close

      s3 = Aws::S3::Resource.new(
        access_key_id: ENV['BUCKETEER_AWS_ACCESS_KEY_ID'],
        secret_access_key: ENV['BUCKETEER_AWS_SECRET_ACCESS_KEY'],
        region: ENV['BUCKETEER_AWS_REGION']
      )
      obj = s3.bucket(ENV['BUCKETEER_BUCKET_NAME']).object('feeds/gmc.xml')
      obj.upload_file(file, { acl: 'public-read' })
      file.unlink
      obj.public_url
    end

    private

    def map_category(id)
      {
        14 => "Apparel & Accessories > Clothing > Dresses",
        15 => "Apparel & Accessories > Clothing > Shirts & Tops",
        16 => "Apparel & Accessories > Clothing > Shirts & Tops",
        17 => "Apparel & Accessories > Clothing > Skirts",
        18 => "Apparel & Accessories > Clothing > Uniforms > Contractor Pants & Coveralls",
        19 => "Apparel & Accessories > Clothing > Outerwear > Coats & Jackets",
        20 => "Apparel & Accessories > Clothing > Pants",
        21 => "Apparel & Accessories > Clothing > Outerwear > Coats & Jackets",
        22 => "Apparel & Accessories > Clothing > Outerwear > Coats & Jackets",
        23 => "Apparel & Accessories > Shoes",
        24 => "Luggage & Bags",
        25 => "Apparel & Accessories > Clothing Accessories",
        26 => "Apparel & Accessories > Jewelry",
        27 => "Apparel & Accessories > Clothing > Underwear & Socks"
      }[id]
    end
  end
end