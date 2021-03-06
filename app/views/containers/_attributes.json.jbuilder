json.extract! container, :id, :type, :name, :disposition, :size_x, :size_y, :size_z, :print_label,
  :created_by_id, :updated_by_id, :project_id, :created_at, :updated_at

json.is_full container.is_full?
json.available_space container.available_space
json.size container.size

json.partial! '/shared/data/all/metadata', object: container # , klass: 'Container'
