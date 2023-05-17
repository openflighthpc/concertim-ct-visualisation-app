attributes :id, :name, :height, :rows, :cols, :depth, :simple
attributes :padding_top, :padding_right, :padding_bottom, :padding_left
attributes :images

node(:rackable) do |template|
  Ivy::Template.rackables[template.rackable]
end
