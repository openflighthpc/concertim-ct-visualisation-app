#
# ResourceTableCollectionBuilder
#
# Responsibiliy: Decorate a collection such that it adopts the features that
# are used in resource tables, such as sorting, searching, pagination and
# authorization.
#
# Subject of the decoration should be a collection, typically an
# ActiveRecord::Relation.
# 
# Context of the decoration should be a controller with the
# "ControllerConcerns::ResourceTable" concern included. Note: That concern
# includes a convinience method for performing this decoration internally.
#
class ResourceTableCollectionDecorator < Decorator

  private

  # decorate_collection! performs all relevant decoration on the collection
  def decorate_subject!
    @controller = opts.delete(:controller)

    if @subject.blank?
      @subject = (@subject || [])
      # @subject = (@subject || []).paginate(page: 1)        
    else
      decorate_with_sorting!
      # decorate_with_pagination!
      decorate_with_search!
    end
  end

  # decorate_with_sorting! sorts the collection if it supports it.
  def decorate_with_sorting!
    if @subject.respond_to? :reorder
      sort_column = @controller.sort_column
      sort_direction = @controller.sort_direction
      @subject = @subject.reorder(@controller.sort_expression(sort_column, sort_direction, opts[:human_sorting]))
    end
  end

  # # decorate_with_pagination! decorates with pagination if the subject can be paginated.
  # def decorate_with_pagination!
  #   if @subject.respond_to? :paginate
  #     @subject = @subject.paginate(page: @controller.current_page, per_page: @controller.per_page) #pagination
  #   end
  # end


  PERMITTED_SEARCH_OPTIONS = [:search_scope].freeze
  # decorate_with_search! decorates with search functionality if the collection is searchable.
  def decorate_with_search!
    if @subject.respond_to?(:ancestors) && @subject.ancestors.include?(Searchable)
      search_opts = opts.select { |k| PERMITTED_SEARCH_OPTIONS.include? k }
      @subject = @subject.search_for(@controller.search_term, search_opts)
    end
  end
end
