class Api::V1::Irv::RacksController < Api::V1::Irv::BaseController

  def index
    # As RABL has quite a serious issue where it casts the collection as an array
    # before itterating over it, causeing Data Mapper which lazy loads any way
    # to call for each item indevidually, rather that with a single shot request
    # for it all.
    #
    # Because of this we will get the database to produce what we need directly
    # in the form of XML, convert it to JSON and send it back to the requestor
    #
    # Uncomment the bellow to use the new ultra fast query method!
    #
    irv_rack_structure = Ivy::Irv.get_structure(params[:rack_ids])
    render :json => Crack::XML.parse(irv_rack_structure).to_json

    # If you want XML uncomment the below
    #
    # render :xml => irv_rack_structure

    #XXX This is the slow method, comment this out when using the above
    #
    # @racks = Ivy::HwRack.all
   end
end
