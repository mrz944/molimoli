task import_ptak_feed: :environment do
  Import::Ptak.new.import_product_feed
end
