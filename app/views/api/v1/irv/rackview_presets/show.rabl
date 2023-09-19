object @preset
attributes :id, :name
# node(:default) { |preset| preset[:id] == @user.get_preference('default_data_centre_rack_view_preset').to_i}
node(:default) { false }
attribute :values
